from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_a_previous_days_beta_prevents_a_stable_tag_for_the_same_commit(self):
        tags = {'2026.11.20.01-beta': 'merged'}
        now = datetime(2026, 11, 21, 12, tzinfo=timezone.utc)
        self.assertIsNone(release.next_tag(tags, 'merged', 'release:stable', now),
                          'A rerun must not release the merge again on another day or channel')


if __name__ == '__main__':
    unittest.main(verbosity=2)
