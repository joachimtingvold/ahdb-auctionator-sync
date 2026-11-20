from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_beta_follows_the_highest_stable_or_beta_number(self):
        tags = {'2026.11.20.01-beta': 'first', '2026.11.20.02': 'second'}
        now = datetime(2026, 11, 20, 12, tzinfo=timezone.utc)
        self.assertEqual(release.next_tag(tags, 'new', 'release:beta', now),
                         '2026.11.20.03-beta', 'Stable releases must advance the beta counter')


if __name__ == '__main__':
    unittest.main(verbosity=2)
