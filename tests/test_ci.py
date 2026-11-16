"""Exercise commit selection with real Git history, without GitHub access."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from select_commits import select


class CommitSelectionTests(unittest.TestCase):
    def setUp(self):
        self.previous = os.getcwd()
        self.directory = tempfile.TemporaryDirectory()
        os.chdir(self.directory.name)
        self.git('init', '-b', 'main')
        self.git('config', 'user.name', 'CI test')
        self.git('config', 'user.email', 'ci@example.invalid')
        self.commits = []
        for number in range(3):
            Path('file').write_text(str(number))
            self.git('add', 'file')
            self.git('commit', '-m', f'Commit {number}')
            self.commits.append(self.git('rev-parse', 'HEAD'))
        self.git('update-ref', 'refs/remotes/origin/main', self.commits[0])

    def tearDown(self):
        os.chdir(self.previous)
        self.directory.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git', *args], text=True, stderr=subprocess.DEVNULL).strip()

    def push(self, before):
        return select('push', {'before': before, 'after': self.commits[-1],
                              'repository': {'default_branch': 'main'}},
                      'owner/repo', self.commits[-1])['include']

    def test_multi_commit_push_checks_every_commit(self):
        self.assertEqual([entry['sha'] for entry in self.push(self.commits[0])], self.commits[1:])

    def test_new_branch_excludes_existing_main_history(self):
        self.assertEqual([entry['sha'] for entry in self.push('0' * 40)], self.commits[1:])

    def test_new_branch_at_main_still_checks_tip(self):
        self.git('update-ref', 'refs/remotes/origin/main', self.commits[-1])
        self.assertEqual([entry['sha'] for entry in self.push('0' * 40)], [self.commits[-1]])

    def test_fork_pr_checks_each_commit_and_combined_merge(self):
        event = {'pull_request': {
            'base': {'sha': self.commits[0]},
            'head': {'sha': self.commits[-1], 'repo': {'full_name': 'contributor/fork'}},
        }}
        entries = select('pull_request', event, 'owner/repo', 'combined-merge')['include']
        self.assertEqual([entry['sha'] for entry in entries], self.commits[1:] + ['combined-merge'])
        self.assertEqual([entry['repository'] for entry in entries],
                         ['contributor/fork', 'contributor/fork', 'owner/repo'])
        self.assertTrue(entries[-1]['label'].startswith('merge-'))

    def test_manual_run_checks_selected_commit(self):
        entries = select('workflow_dispatch', {}, 'owner/repo', self.commits[-1])['include']
        self.assertEqual([entry['sha'] for entry in entries], [self.commits[-1]])


if __name__ == '__main__':
    unittest.main(verbosity=2)
