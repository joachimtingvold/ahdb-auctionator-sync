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
        prefix = 'AuctionSync/'
        expected = {prefix + name for name in (
            'AuctionSync.lua', 'AuctionSync.toc', 'AuctionSync.tga',
            'LICENSE', 'README.md', 'CHANGELOG.md',
        )}
        with zipfile.ZipFile(archives[0]) as archive:
            self.assertIsNone(archive.testzip(), 'ZIP has a corrupt member')
            files = [name for name in archive.namelist() if not name.endswith('/')]
            self.assertEqual(len(files), len(set(files)), 'ZIP contains duplicate file entries')
            self.assertEqual(set(files), expected,
                             'ZIP must contain only the installable addon files')
            toc = archive.read(prefix + 'AuctionSync.toc').decode()
            source_toc = (root / 'AuctionSync.toc').read_text()
            headers = dict(line[3:].split(':', 1) for line in toc.splitlines()
                           if line.startswith('## ') and ':' in line)
            source_headers = dict(line[3:].split(':', 1) for line in source_toc.splitlines()
                                  if line.startswith('## ') and ':' in line)
            self.assertEqual(headers.get('Interface'), source_headers.get('Interface'),
                             'Packaged interface differs from the source TOC')
            self.assertEqual(headers.get('Dependencies'), source_headers.get('Dependencies'),
                             'Packaged dependencies differ from the source TOC')
            self.assertEqual(headers['Title'].strip(), 'Auction Sync')
            self.assertEqual(headers['IconTexture'].strip(), r'Interface\AddOns\AuctionSync\AuctionSync')
            self.assertEqual(archive.read(prefix + 'AuctionSync.tga'),
                             (root / 'AuctionSync.tga').read_bytes(),
                             'Packaging changed the addon icon')
            self.assertEqual(headers['Category'].strip(), 'Auctions')
            self.assertEqual(headers['SavedVariables'].strip(), 'AuctionSyncDB')
            self.assertTrue(headers.get('Version', '').strip(), 'Packaged version is empty')
            self.assertEqual(archives[0].name, f"AuctionSync-{headers['Version'].strip()}.zip")
            self.assertNotIn('@project-version@', toc, 'Packager did not replace the version token')
            self.assertEqual(archive.read(prefix + 'AuctionSync.lua').replace(b'\r\n', b'\n'),
                             (root / 'AuctionSync.lua').read_bytes().replace(b'\r\n', b'\n'),
                             'Packaging changed the addon Lua code')
            self.assertEqual(archive.read(prefix + 'CHANGELOG.md').replace(b'\r\n', b'\n'),
                             (root / 'CHANGELOG.md').read_bytes().replace(b'\r\n', b'\n'),
                             'Packaged changelog differs from the source')


if __name__ == '__main__':
    unittest.main(verbosity=2)
