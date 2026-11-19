from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_live_beta_label_pushes_only_the_tested_sha_as_a_tag(self):
        with patch.object(release, 'pr_labels', return_value={'release:beta'}), \
                patch.object(release, 'remote_tags', return_value={}), \
                patch.object(release, 'datetime') as clock, \
                patch.object(release.subprocess, 'run') as push:
            clock.now.return_value = datetime(2026, 11, 20, 12, tzinfo=timezone.utc)
            release.tag_merge('owner/repo', '23', 'tested-merge-sha')

        push.assert_called_once_with(
            ['git', 'push', 'origin', 'tested-merge-sha:refs/tags/2026.11.20.01-beta'],
            check=True,
        )


if __name__ == '__main__':
    unittest.main(verbosity=2)
