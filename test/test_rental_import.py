"""Run: python -m unittest discover -s test -p test_rental_import.py"""
import copy
from contextlib import closing
import importlib.util
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('rental_import', ROOT / 'tool/rental_import.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
sys.path.insert(0, str(ROOT / 'tool'))
import publish_cloud_documents as publisher


def valid_rows():
    rows = {name: [{**dict(zip(module.SCHEMA[name], values)), '_row': name + ' 2'}]
            for name, values in module.EXAMPLES.items()}
    rows['NhaTro'][0]['ownerUid'] = 'owner-test-uid'
    rows['DichVu'].append({'propertyId': 'nha-001', 'id': 'water', 'name': 'Nước', 'unit': 'm3',
                          'basis': 'Theo chỉ số', 'price': 15000, 'active': True, '_row': 'DichVu 3'})
    return rows


class RentalImportTest(unittest.TestCase):
    def test_dotted_room_codes_preserve_floor_numbering_without_relaxing_other_ids(self):
        rows = valid_rows()
        rows['PhongTro'][0].update(code='P.101', floor=1)
        rows['PhongTro'].append({**rows['PhongTro'][0], 'code': 'P.1001', 'floor': 10})
        snapshot, _ = module.build_snapshot(rows)
        rooms = snapshot['portfolio']['properties'][0]['rooms']
        self.assertEqual([(r['code'], r['floor']) for r in rooms], [('P.101', 1), ('P.1001', 10)])
        for code in ['../P101', 'P..101', 'P/101', 'P:101']:
            bad = copy.deepcopy(rows)
            bad['PhongTro'][0]['code'] = code
            with self.subTest(code=code), self.assertRaises(ValueError):
                module.build_snapshot(bad)
        for field in ['propertyId', 'roomTypeId', 'id']:
            with self.subTest(field=field), self.assertRaises(ValueError):
                module.identifier({'_row': 'test', field: 'bad.id'}, field)

    @patch.object(publisher, 'BASE', 'https://firestore.googleapis.com/v1/projects/auth-unit-test/databases/(default)/documents')
    @patch.object(Path, 'read_text', return_value="FirebaseOptions web = FirebaseOptions(apiKey: 'public-test-key', projectId: 'auth-unit-test');")
    def test_private_admin_sign_in_rejects_other_roles_disabled_and_wrong_uid(self, _read_config):
        account = {'localId': 'admin-test', 'idToken': 'fake-id-token', 'email': 'admin@example.com'}
        base_profile = {'name': publisher.BASE.split('/v1/')[1] + '/users/admin-test',
                        'fields': {'role': {'stringValue': 'admin'}, 'disabled': {'booleanValue': False}}}
        with patch.object(publisher.getpass, 'getpass', return_value='fake-password') as prompt, \
                patch.object(publisher, 'request', side_effect=[account, base_profile]) as http, \
                patch.object(Path, 'write_text') as write, patch.dict(publisher.os.environ, {}, clear=True):
            publisher.sign_in_admin('admin@example.com')
            prompt.assert_called_once()
            self.assertEqual(http.call_args_list[0].args[1]['password'], 'fake-password')
            self.assertEqual(publisher._session_token, 'fake-id-token')
            self.assertNotIn('FIREBASE_ACCESS_TOKEN', publisher.os.environ)
            write.assert_not_called()
        for change in [{'role': {'stringValue': 'tenant'}}, {'disabled': {'booleanValue': True}}]:
            profile = copy.deepcopy(base_profile)
            profile['fields'].update(change)
            with self.subTest(change=change), patch.object(publisher.getpass, 'getpass', return_value='fake-password'), \
                    patch.object(publisher, 'request', side_effect=[account, profile]), self.assertRaises(ValueError):
                publisher.sign_in_admin('admin@example.com')
            self.assertIsNone(publisher._session_token)
        profile = {**base_profile, 'name': base_profile['name'] + '-someone-else'}
        with patch.object(publisher.getpass, 'getpass', return_value='fake-password'), \
                patch.object(publisher, 'request', side_effect=[account, profile]), self.assertRaises(ValueError):
            publisher.sign_in_admin('admin@example.com')
        self.assertIsNone(publisher._session_token)

    def test_template_empty_and_filled_roundtrip_and_cloud_codec(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.dart_tool') as temp:
            target = Path(temp) / 'input.xlsx'
            module.create_template(target)
            snapshot, owners = module.build_snapshot(module.read_rows(target))
            self.assertEqual(snapshot['portfolio']['properties'], [])
            book = module.load_workbook(target)
            rows = valid_rows()
            for name, records in rows.items():
                for number, row in enumerate(records, 2):
                    for column, key in enumerate(module.SCHEMA[name], 1):
                        book[name].cell(number, column, row[key])
            book.save(target)
            snapshot, owners = module.build_snapshot(module.read_rows(target))
            self.assertEqual(snapshot['portfolio']['properties'][0]['property']['phone'], '0900000000')
            self.assertEqual(snapshot['portfolio']['properties'][0]['leases'], [])
            source, output = Path(temp) / 'input.json', Path(temp) / 'cloud.json'
            source.write_text(json.dumps({'snapshot': snapshot, 'owners': owners}), encoding='utf-8')
            dart = module.shutil.which('dart')
            direct = Path(dart).parent / 'cache/dart-sdk/bin/dart.exe'
            if direct.is_file():
                dart = str(direct)
            subprocess.run([dart, '--packages=.dart_tool/package_config.json', 'tool/rental_import_codec.dart', str(source), str(output)], cwd=ROOT, check=True)
            cloud = json.loads(output.read_text(encoding='utf-8'))
            publisher.validate_create_source(cloud)
            self.assertEqual(cloud['rental_properties/nha-001']['ownerUid'], 'owner-test-uid')
            room = next(v for k, v in cloud.items() if k.startswith('public_rooms/'))
            self.assertEqual(room['price'], 3000000)
            self.assertTrue(room['available'])
            self.assertEqual(room['waterPrice'], 15000)
            self.assertFalse(any(k.startswith('users/') for k in cloud))
            forged = copy.deepcopy(cloud)
            forged['users/admin'] = {'role': 'admin'}
            with self.assertRaises(ValueError):
                publisher.validate_create_source(forged)
            forged = copy.deepcopy(cloud)
            next(v for k, v in forged.items() if k.startswith('rental_records/'))['kind'] = 'leases'
            with self.assertRaises(ValueError):
                publisher.validate_create_source(forged)

    def test_reject_invalid_keys_relations_money_formulas_and_placeholders(self):
        for sheet, field, value in [('NhaTro', 'propertyId', '../private'), ('NhaTro', 'ownerUid', 'THAY_BANG_UID_CHU_TRO'),
                                    ('PhongTro', 'roomTypeId', 'missing'), ('LoaiPhong', 'monthlyRent', 3.5),
                                    ('DichVu', 'active', 'yes'), ('LoaiPhong', 'photoUrls', 'http://example.com/a.jpg')]:
            rows = valid_rows()
            rows[sheet][0][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                module.build_snapshot(rows)
        rows = valid_rows()
        rows['PhongTro'].append(copy.deepcopy(rows['PhongTro'][0]))
        with self.assertRaises(ValueError):
            module.build_snapshot(rows)
        with tempfile.TemporaryDirectory(dir=ROOT / '.dart_tool') as temp:
            target = Path(temp) / 'formula.xlsx'
            module.create_template(target)
            book = module.load_workbook(target)
            book['NhaTro']['A2'] = '=1+1'
            book.save(target)
            with self.assertRaisesRegex(ValueError, 'công thức'):
                module.read_rows(target)

    def test_sqlite_preview_addition_backup_and_existing_occupied_rejection(self):
        snapshot, _ = module.build_snapshot(valid_rows())
        with tempfile.TemporaryDirectory(dir=ROOT / '.dart_tool') as temp:
            path = Path(temp) / 'existing.db'
            original = {'selectedId': 'existing', 'properties': [{'property': {'id': 'existing'}, 'leases': [{'id': 'occupied'}]}]}
            with closing(sqlite3.connect(path)) as db:
                db.execute('CREATE TABLE app_documents(id TEXT PRIMARY KEY,payload TEXT,updated_at TEXT)')
                db.execute('INSERT INTO app_documents VALUES(?,?,?)', ('portfolio', json.dumps(original), 'before'))
                db.execute('INSERT INTO app_documents VALUES(?,?,?)', ('auth', '{"untouched":true}', 'before'))
                db.commit()
            module.import_sqlite(path, snapshot)
            with closing(sqlite3.connect(path)) as db:
                self.assertEqual(json.loads(db.execute("SELECT payload FROM app_documents WHERE id='portfolio'").fetchone()[0]), original)
            backup = module.import_sqlite(path, snapshot, apply=True)
            self.assertTrue(backup.exists())
            with closing(sqlite3.connect(path)) as db:
                saved = json.loads(db.execute("SELECT payload FROM app_documents WHERE id='portfolio'").fetchone()[0])
                self.assertEqual(saved['properties'][0], original['properties'][0])
                self.assertEqual(db.execute("SELECT payload FROM app_documents WHERE id='auth'").fetchone()[0], '{"untouched":true}')
                self.assertEqual(len(saved['properties']), 2)
            with self.assertRaisesRegex(ValueError, 'đã tồn tại'):
                module.import_sqlite(path, snapshot, apply=True)


if __name__ == '__main__':
    unittest.main()
