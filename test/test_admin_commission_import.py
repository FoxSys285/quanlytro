import unittest
from datetime import datetime, timezone
from tool.initialize_admin_commissions import rent_collected, plan


class CommissionImportTest(unittest.TestCase):
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
