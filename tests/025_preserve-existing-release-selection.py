from pathlib import Path
import sys
import unittest
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_open_event_keeps_a_manually_selected_beta(self):
        with patch.object(release, 'pr_labels', return_value={'release:beta'}), \
                patch.object(release.subprocess, 'check_output') as request:
            release.validate('owner/repo', '23', 'opened')
            request.assert_not_called()


if __name__ == '__main__':
    unittest.main(verbosity=2)
