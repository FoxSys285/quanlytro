import copy
import tempfile
import unittest
from datetime import datetime
from pathlib import Path
from unittest.mock import patch
from tool.supplement_firebase_samples import plan
from tool import supplement_firebase_samples as importer


class FirebaseSamplesTest(unittest.TestCase):
    def test_preview_never_writes_and_apply_verifies_without_transaction_api(self):
        for apply in (False, True):
            with self.subTest(apply=apply), tempfile.TemporaryDirectory(dir='.dart_tool') as folder:
                calls, committed = [], {}
                def request(url, data=None):
                    calls.append(url)
                    if '?pageSize=' in url:
                        return {'documents': []}
                    if url.endswith(':commit'):
                        for write in data['writes']:
                            self.assertEqual(write['currentDocument'], {'exists': False})
                            doc = write['update']
                            committed[doc['name'].split('/documents/')[1]] = doc
                        return {}
                    return committed[url.split('/documents/')[1]]
                with patch.object(importer, 'ROOT', Path(folder)), \
                     patch.object(importer, 'sign_in_admin', return_value='admin'), \
                     patch.object(importer, 'request', side_effect=request), \
                     patch('sys.argv', ['samples', '--admin-email', 'admin@example.com'] +
                           (['--apply'] if apply else [])), patch('builtins.print'):
                    importer.main()
                self.assertEqual(any(u.endswith(':commit') for u in calls), apply)
                self.assertFalse(any(u.endswith((':beginTransaction', ':rollback', ':runQuery')) for u in calls))
                self.assertEqual(len(list(Path(folder).rglob('after.json'))), int(apply))
                for file in Path(folder).rglob('*.json'):
                    self.assertNotIn('temporary-transaction', file.read_text(encoding='utf-8'))

    def test_additive_idempotent_linked_samples_preserve_live_data(self):
        current = {
            'rental_properties/p': {'ownerUid': 'owner', 'data': {
                'property': {'id': 'p', 'name': 'House', 'address': 'Address'},
                'rooms': [{'code': '101', 'roomTypeId': 't'}],
                'roomTypes': [{'id': 't', 'monthlyRent': 3000000}]}},
            'rental_records/lease': {'kind': 'leases', 'propertyId': 'p',
                'ownerUid': 'owner', 'tenantIds': ['tenant'], 'data': {
                    'id': 'lease', 'tenantId': 'tenant', 'room': '101',
                    'tenantName': 'Name', 'monthlyRent': 3000000,
                    'startDate': '2026-01-01', 'endDate': '2027-01-01', 'status': 'active'}},
            'management/system': {'admin': {'commissionRates': {'p': 500}}},
        }
        before = copy.deepcopy(current)
        additions = plan(current, datetime(2026, 11, 5), 'admin')
        self.assertEqual(current, before)
        self.assertFalse(current.keys() & additions.keys())
        merged = current | additions
        self.assertEqual(plan(merged, datetime(2026, 11, 6), 'admin'), {})
        self.assertNotIn('management/system', additions)
        rows = [v for v in additions.values() if v.get('kind')]
        self.assertTrue(all(v['ownerUid'] == 'owner' for v in rows))
        kinds = {v['kind'] for v in rows}
        self.assertTrue({'leases', 'invoices', 'payments', 'members', 'incidents',
                         'readings', 'viewings', 'conversations', 'messages',
                         'announcements', 'tenantAnnouncements'} <= kinds)
        invoices = {r['data']['id']: r['data'] for r in rows if r['kind'] == 'invoices'}
        for row in rows:
            if row['kind'] == 'payments':
                self.assertIn(row['data']['invoiceId'], invoices)
        self.assertTrue(all(r['data']['leaseId'] == 'lease' for r in rows
                            if r['kind'] in ('invoices', 'members', 'incidents')))
        self.assertTrue(all(r['tenantIds'] == ['tenant'] for r in rows
                            if r['kind'] not in ('leases', 'announcements')))

