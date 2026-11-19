from pathlib import Path
import sys
import unittest
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_unlabel_event_does_not_restore_the_default(self):
        with patch.object(release, 'pr_labels', return_value={'bug'}), \
                patch.object(release.subprocess, 'check_output') as request:
            with self.assertRaisesRegex(ValueError, 'Select exactly one.*Found: none'):
                release.validate('owner/repo', '23', 'unlabeled')
            request.assert_not_called()


if __name__ == '__main__':
    unittest.main(verbosity=2)
