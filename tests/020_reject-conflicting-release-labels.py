from pathlib import Path
import sys
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_two_release_labels_are_an_error(self):
        with self.assertRaisesRegex(ValueError, 'Found: release:beta, release:stable'):
            release.release_selection({'bug', 'release:stable', 'release:beta'})


if __name__ == '__main__':
    unittest.main(verbosity=2)
