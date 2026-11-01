import hashlib
import json
from pathlib import Path
import unittest
import import_rental_photos as importer


class RentalPhotoApiCheck(unittest.TestCase):
    def test_imported_albums_are_real_files_with_verified_sources(self):
        manifest = json.loads((importer.ASSETS / 'manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(manifest['provider'], 'Nha Tot / Cho Tot')
        types = {album['type'] for album in manifest['albums']}
        self.assertTrue({'studio', 'loft', 'balcony', 'group'}.issubset(types))
        for album in manifest['albums']:
            self.assertGreaterEqual(len(album['photos']), 2)
            self.assertLessEqual(len(album['photos']), 4)
            hashes = set()
            for photo in album['photos']:
                file = importer.ROOT / photo['asset']
                self.assertTrue(file.resolve().is_relative_to(importer.ASSETS.resolve()))
                self.assertTrue(photo['url'].startswith('https://cdn.chotot.com/'))
                self.assertEqual(hashlib.sha256(file.read_bytes()).hexdigest(), photo['sha256'])
                self.assertLess(file.stat().st_size, 150_000)
                self.assertNotIn(photo['sha256'], hashes)
                hashes.add(photo['sha256'])

    def test_external_origins_are_rejected_before_network_access(self):
        for url in ['http://cdn.chotot.com/photo.jpg', 'https://example.com/photo.jpg', 'file:///private']:
            with self.assertRaises(ValueError):
                importer.fetch(url, image=True)


if __name__ == '__main__':
    unittest.main()
