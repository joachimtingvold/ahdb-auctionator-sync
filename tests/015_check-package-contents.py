"""Check a real BigWigs build; no other test files or test runner are required."""
from pathlib import Path
import unittest
import zipfile


class PackageContentsTest(unittest.TestCase):
    def test_archive_is_installable_and_preserves_addon_source(self):
        """The built ZIP contains the addon, correct metadata, and unchanged source."""
        root = Path(__file__).resolve().parent.parent
        archives = list((root / '.release').glob('*.zip'))
        self.assertEqual(len(archives), 1,
                         f'Expected one BigWigs ZIP under .release, found {archives}')
        prefix = 'AHDBAuctionatorSync/'
        expected = {prefix + name for name in (
            'AHDBAuctionatorSync.lua', 'AHDBAuctionatorSync.toc',
            'LICENSE', 'README.md', 'CHANGELOG.md',
        )}
        with zipfile.ZipFile(archives[0]) as archive:
            self.assertIsNone(archive.testzip(), 'ZIP has a corrupt member')
            files = [name for name in archive.namelist() if not name.endswith('/')]
            self.assertEqual(len(files), len(set(files)), 'ZIP contains duplicate file entries')
            self.assertEqual(set(files), expected,
                             'ZIP must contain only the installable addon files')
            toc = archive.read(prefix + 'AHDBAuctionatorSync.toc').decode()
            source_toc = (root / 'AHDBAuctionatorSync.toc').read_text()
            headers = dict(line[3:].split(':', 1) for line in toc.splitlines()
                           if line.startswith('## ') and ':' in line)
            source_headers = dict(line[3:].split(':', 1) for line in source_toc.splitlines()
                                  if line.startswith('## ') and ':' in line)
            self.assertEqual(headers.get('Interface'), source_headers.get('Interface'),
                             'Packaged interface differs from the source TOC')
            self.assertEqual(headers.get('Dependencies'), source_headers.get('Dependencies'),
                             'Packaged dependencies differ from the source TOC')
            self.assertTrue(headers.get('Version', '').strip(), 'Packaged version is empty')
            self.assertNotIn('@project-version@', toc, 'Packager did not replace the version token')
            self.assertEqual(archive.read(prefix + 'AHDBAuctionatorSync.lua').replace(b'\r\n', b'\n'),
                             (root / 'AHDBAuctionatorSync.lua').read_bytes().replace(b'\r\n', b'\n'),
                             'Packaging changed the addon Lua code')
            self.assertEqual(archive.read(prefix + 'CHANGELOG.md').replace(b'\r\n', b'\n'),
                             (root / 'CHANGELOG.md').read_bytes().replace(b'\r\n', b'\n'),
                             'Packaged changelog differs from the source')


if __name__ == '__main__':
    unittest.main(verbosity=2)
