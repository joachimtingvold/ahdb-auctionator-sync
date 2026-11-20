from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseRetryTest(unittest.TestCase):
    def test_retry_returns_existing_tag_for_packaging(self):
        tags = {'2026.11.20.01-beta': 'merged'}
        with patch.object(release, 'pr_labels', return_value={'release:beta'}), \
                patch.object(release, 'remote_tags', return_value=tags), \
                patch.object(release.subprocess, 'run') as push:
            self.assertEqual(release.tag_merge('owner/repo', '23', 'merged'),
                             '2026.11.20.01-beta',
                             'A retry must pass the existing tag to the package job')
            push.assert_not_called()


if __name__ == '__main__':
    unittest.main(verbosity=2)
