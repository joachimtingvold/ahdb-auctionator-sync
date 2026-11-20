from datetime import datetime, timedelta, timezone
from pathlib import Path
import sys
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_summer_midnight_falls_at_2200_utc(self):
        now = datetime(2026, 7, 20, 22, tzinfo=timezone.utc)
        tags = {'2026.07.20.01-beta': 'first'}
        self.assertEqual(release.next_tag(tags, 'new', 'release:stable', now - timedelta(seconds=1)),
                         '2026.07.20.02', 'Stable releases must advance the beta number')
        self.assertEqual(release.next_tag(tags, 'new', 'release:stable', now),
                         '2026.07.21.01', 'The date must roll over at Oslo midnight')


if __name__ == '__main__':
    unittest.main(verbosity=2)
