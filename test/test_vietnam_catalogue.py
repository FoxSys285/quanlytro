"""Offline checks of the complete user-requested building/floor/type hierarchy."""
import contextlib
import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tool'))
import generate_vietnam_catalogue as generator
from rental_import import build_snapshot, read_rows


class VietnamCatalogueTest(unittest.TestCase):
    def test_full_34_province_workbook_roundtrip_and_relationships(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.dart_tool') as temp:
            work = Path(temp)
            provinces = [{'code': code, 'name': f'Tỉnh {code:02d}', 'wards': [
                {'code': code * 100 + i, 'name': f'Phường {i}'} for i in range(1, 22)]}
                for code in sorted(generator.EXPECTED_CODES)]
            (work / 'administrative-units.json').write_text(json.dumps(provinces), encoding='utf-8')
            photo_pool = {'collectedAt': '2026-11-05T00:00:00+00:00', 'albums': [
                {'kind': kind, 'listingId': '123', 'photos': ['https://cdn.chotot.com/example.jpg'],
                 'sourceUrl': 'https://www.nhatot.com/123.htm',
                 'sourceApiUrl': 'https://gateway.chotot.com/v1/public/ad-listing/123'}
                for kind in ['studio', 'loft', 'balcony', 'group']]}
            (work / 'photo-pool.json').write_text(json.dumps(photo_pool), encoding='utf-8')
            with patch.object(generator, 'WORK', work), patch.object(generator, 'OUTPUT', work / 'catalogue.xlsx'), \
                    patch.object(generator, 'project_config', return_value=('offline-test', 'public-test-key')), \
                    contextlib.redirect_stdout(io.StringIO()):
                generator.prepare()
                data = generator.read_catalogue()
                info = generator.validate(data)
                self.assertEqual(info['properties'], 680)
                self.assertEqual(info['provinces'], 34)
                self.assertEqual(set(info['byProvince'].values()), {20})
                self.assertGreater(info['rooms'], 10000)
                self.assertEqual(len({o['password'] for o in data['owners']}), 680)
                self.assertTrue(all(s['property']['id'] == data['ownersByProperty'][s['property']['id']]
                                    for s in data['snapshot']['portfolio']['properties']))
                self.assertTrue(any(len(s['rooms']) == 120 for s in data['snapshot']['portfolio']['properties']))
                generator.build()
                snapshot, owners = build_snapshot(read_rows(generator.OUTPUT))
                self.assertEqual(snapshot, data['snapshot'])
                self.assertEqual(owners, data['ownersByProperty'])
                # A second prepare must not replace credentials of already-created accounts.
                with self.assertRaisesRegex(ValueError, 'already exists'):
                    generator.prepare()
                invalid = copy.deepcopy(data)
                invalid['snapshot']['portfolio']['properties'][0]['rooms'][0]['code'] = 'P.201'
                with self.assertRaisesRegex(ValueError, 'codes'):
                    generator.validate(invalid)
                invalid = copy.deepcopy(data)
                invalid['snapshot']['portfolio']['properties'][0]['rooms'][0]['roomTypeId'] = 'unknown-type'
                with self.assertRaisesRegex(ValueError, 'room types'):
                    generator.validate(invalid)


if __name__ == '__main__':
    unittest.main()
