from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ExistingTagTest(unittest.TestCase):
    def test_manual_package_requires_a_commit_on_main(self):
        tag = '2026.11.20.01-beta'
        command = ['git', 'merge-base', '--is-ancestor', 'tagged-commit', 'main-commit']
        with patch.object(release, 'remote_tags', return_value={tag: 'tagged-commit'}), \
                patch.object(release.subprocess, 'run',
                             side_effect=subprocess.CalledProcessError(1, command)) as ancestry:
            with self.assertRaisesRegex(subprocess.CalledProcessError, 'merge-base'):
                release.existing_tag(tag, 'main-commit')
            ancestry.assert_called_once_with(command, check=True)


if __name__ == '__main__':
    unittest.main(verbosity=2)
