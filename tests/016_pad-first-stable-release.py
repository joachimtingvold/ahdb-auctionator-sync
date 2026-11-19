from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_first_stable_version_uses_two_digits(self):
        now = datetime(2026, 11, 20, 12, tzinfo=timezone.utc)
        self.assertEqual(release.next_tag({}, 'new', 'release:stable', now),
                         '2026.11.20.01', 'First stable release must start at 01')


if __name__ == '__main__':
    unittest.main(verbosity=2)
