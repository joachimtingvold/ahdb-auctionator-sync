from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_yesterday_and_legacy_tags_do_not_advance_todays_counter(self):
        tags = {'2026.11.20.99-beta': 'previous', 'v0.3.99-beta': 'legacy'}
        now = datetime(2026, 11, 21, 12, tzinfo=timezone.utc)
        self.assertEqual(release.next_tag(tags, 'new', 'release:beta', now),
                         '2026.11.21.01-beta', 'Each Oslo date starts at 01')


if __name__ == '__main__':
    unittest.main(verbosity=2)
