from pathlib import Path
import sys
import unittest
from unittest.mock import call, patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_open_event_adds_stable_and_checks_the_result(self):
        with patch.object(release.subprocess, 'check_output', side_effect=[
            b'{"labels":[{"name":"bug"}]}',
            b'[{"name":"release:stable"}]',
            b'{"labels":[{"name":"bug"},{"name":"release:stable"}]}',
        ]) as request:
            release.validate('owner/repo', '23', 'opened')

        self.assertEqual(request.call_args_list, [
            call(['gh', 'api', 'repos/owner/repo/pulls/23']),
            call(['gh', 'api', '--method', 'POST', 'repos/owner/repo/issues/23/labels',
                  '-f', 'labels[]=release:stable']),
            call(['gh', 'api', 'repos/owner/repo/pulls/23']),
        ], 'Opening workflow must add stable and validate it in the same run')


if __name__ == '__main__':
    unittest.main(verbosity=2)
