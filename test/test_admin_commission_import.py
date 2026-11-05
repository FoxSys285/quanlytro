import unittest
import json
import tempfile
from pathlib import Path
from unittest.mock import patch
from datetime import datetime, timezone
from tool.initialize_admin_commissions import rent_collected, plan, scoped_portfolio
from tool import initialize_admin_commissions as importer


class CommissionImportTest(unittest.TestCase):
    def test_all_missing_past_periods_are_included_without_inventing_receipts(self):
        store = {'property': {'id': 'p', 'name': 'House'}, 'invoices': [
            {'id': 'i', 'charges': [{'name': 'Tiền phòng', 'amount': 1000000}]}],
            'payments': [{'invoiceId': 'i', 'status': 'approved',
                          'paidAt': f'2026-{month:02d}-01', 'approvedAmount': 1000000}
                         for month in (7, 8, 9, 11)]}
        admin, _ = plan({'properties': [store]}, {}, datetime(2026, 11, 5))
        self.assertEqual([s['month'][:7] for s in admin['commissionStatements']],
                         ['2026-07', '2026-08', '2026-09'])
        self.assertTrue(all(s['receipts'] == [] for s in admin['commissionStatements']))

    def test_scoped_apply_preserves_management_and_reads_back(self):
        prop = {'id': 'p', 'data': {'property': {'id': 'p', 'name': 'House'}}}
        original = {'admin': {'commissionRates': {'p': 500}, 'verified': {'p': False}},
                    'keep': {'value': 'untouched'}}
        name = importer.BASE.split('/v1/')[1] + '/management/system'
        live = {'name': name, 'updateTime': 'version-1',
                'fields': {k: importer.value(v) for k, v in original.items()}}
        calls = []
        def request(url, data=None):
            calls.append((url, data))
            if url.endswith(':beginTransaction'):
                return {'transaction': 'in-memory-only'}
            if url.endswith(':runQuery'):
                collection = data['structuredQuery']['from'][0]['collectionId']
                self.assertEqual(data['transaction'], 'in-memory-only')
                if collection == 'rental_properties':
                    return [{'document': {'name': 'properties/p', 'fields': {
                        k: importer.value(v) for k, v in prop.items() if k != 'id'}}}]
                return [{'document': live}] if collection == 'management' else []
            if url.endswith(':commit'):
                self.assertEqual(data['transaction'], 'in-memory-only')
                self.assertEqual(data['writes'][0]['currentDocument'], {'updateTime': 'version-1'})
                live.update(data['writes'][0]['update'])
                return {'commitTime': 'committed'}
            if url.endswith('/management/system'):
                return live
            self.fail('Unexpected request: ' + url)
        with tempfile.TemporaryDirectory(dir='.dart_tool') as temporary:
            with patch.object(importer, 'ROOT', Path(temporary)), \
                 patch.object(importer, 'request', side_effect=request), \
                 patch.dict('os.environ', {'FIREBASE_ACCESS_TOKEN': 'test-only'}), \
                 patch('sys.argv', ['importer', '--apply']), patch('builtins.print'):
                importer.main()
            backups = list(Path(temporary).rglob('after.json'))
            self.assertEqual(len(backups), 1)
            saved = json.loads(backups[0].read_text(encoding='utf-8'))
            data = {k: importer.decode(v) for k, v in saved['fields'].items()}
            self.assertEqual(data['keep'], original['keep'])
            self.assertEqual(data['admin']['commissionRates'], {'p': 500})
            self.assertEqual(data['admin']['tickets'], [])
            self.assertEqual(data['admin']['commissionStatements'], [])
        self.assertFalse(any(url.endswith(':rollback') for url, _ in calls))

    def test_scoped_data_excludes_archived_and_keeps_financial_links(self):
        properties = [{'id': 'p', 'archived': False,
                       'data': {'property': {'id': 'p', 'name': 'House'}}},
                      {'id': 'old', 'archived': True, 'data': {}}]
        records = [
            {'propertyId': 'p', 'kind': 'invoices', 'data': {'id': 'i'}},
            {'propertyId': 'p', 'kind': 'payments', 'data': {'invoiceId': 'i'}},
            {'propertyId': 'p', 'kind': 'payments', 'archived': True, 'data': {}},
            {'propertyId': 'old', 'kind': 'payments', 'data': {}},
        ]
        snapshot = scoped_portfolio(properties, records)
        self.assertEqual(len(snapshot['properties']), 1)
        store = snapshot['properties'][0]
        self.assertEqual(store['invoices'], [{'id': 'i'}])
        self.assertEqual(store['payments'], [{'invoiceId': 'i'}])

    def test_rent_share_and_idempotent_plan_never_invent_receipts(self):
        store = {'property': {'id': 'p', 'name': 'House'}, 'invoices': [
            {'id': 'i', 'charges': [{'name': 'Tiền thuê phòng', 'amount': 3000000},
                                    {'name': 'Điện nước', 'amount': 1000000}]}],
            'payments': [{'invoiceId': 'i', 'status': 'approved', 'paidAt': '2026-09-01',
                          'reviewedAt': '2026-10-01', 'approvedAmount': 2000000}]}
        self.assertEqual(rent_collected(store, '2026-09'), 0)
        self.assertEqual(rent_collected(store, '2026-10'), 1500000)
        now = datetime(2026, 11, 4, tzinfo=timezone.utc)
        admin, _ = plan({'properties': [store]}, {'tickets': [{'id': 'keep'}]}, now)
        self.assertEqual(admin['tickets'], [{'id': 'keep'}])
        self.assertEqual(admin['commissionStatements'][0]['receipts'], [])
        self.assertEqual(admin['commissionStatements'][0]['rentCollected'], 1500000)
        again, _ = plan({'properties': [store]}, admin, now)
        self.assertEqual(again, admin)
