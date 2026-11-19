from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_number_100_is_never_used(self):
        tags = {'2026.11.20.99-beta': 'previous'}
        now = datetime(2026, 11, 20, 12, tzinfo=timezone.utc)
        with self.assertRaisesRegex(ValueError, r'All 99 release numbers for 2026\.11\.20'):
            release.next_tag(tags, 'new', 'release:stable', now)


if __name__ == '__main__':
    unittest.main(verbosity=2)
