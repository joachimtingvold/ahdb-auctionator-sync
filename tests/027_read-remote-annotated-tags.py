from pathlib import Path
import sys
import unittest
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '.github'))
import release


class ReleaseTest(unittest.TestCase):
    def test_annotated_tags_use_the_peeled_commit(self):
        with patch.object(release.subprocess, 'check_output', return_value=(
            'tag-object\trefs/tags/2026.11.20.01-beta\n'
            'peeled-commit\trefs/tags/2026.11.20.01-beta^{}\n'
            'lightweight-commit\trefs/tags/2026.11.20.02\n'
        )):
            self.assertEqual(release.remote_tags(), {
                '2026.11.20.01-beta': 'peeled-commit',
                '2026.11.20.02': 'lightweight-commit',
            }, 'Version comparisons must use the commits that the remote tags point to')


if __name__ == '__main__':
    unittest.main(verbosity=2)
