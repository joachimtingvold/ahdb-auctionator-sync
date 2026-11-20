from pathlib import Path
import sys
import unittest
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_a_live_none_selection_prevents_any_git_command(self):
        with patch.object(release, 'pr_labels', return_value={'release:none'}) as labels, \
                patch.object(release.subprocess, 'check_output') as read, \
                patch.object(release.subprocess, 'run') as push:
            release.tag_merge('owner/repo', '23', 'merged')
            labels.assert_called_once_with('owner/repo', '23')
            read.assert_not_called()
            push.assert_not_called()


if __name__ == '__main__':
    unittest.main(verbosity=2)
