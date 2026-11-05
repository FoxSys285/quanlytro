import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tool'))
from backfill_landlord_phones import generated_phone, nested_fields, normalized
from collect_nationwide_rentals import decode_wire


class PhoneBackfillTest(unittest.TestCase):
    def test_only_vietnamese_mobile_numbers_are_preserved(self):
        for value in ['0912 345 678', '+84912345678', '84912345678']:
            self.assertEqual(normalized(value), '0912345678')
        for value in ['', None, '0000000000', '12345', '09123456789']:
            self.assertIsNone(normalized(value))

    def test_generated_contacts_are_unique_and_have_valid_prefixes(self):
        used = {'0912345678'}
        for _ in range(700):
            phone = generated_phone(used)
            self.assertEqual(normalized(phone), phone)
        self.assertEqual(len(used), 701)

    def test_patch_updates_only_the_contact_fields(self):
        fields = nested_fields({'data.property.phone': '0912345678',
                                'data.property.phoneIsSynthetic': True})
        actual = {key: decode_wire(value) for key, value in fields.items()}
        self.assertEqual(actual, {'data': {'property': {
            'phone': '0912345678', 'phoneIsSynthetic': True}}})


if __name__ == '__main__':
    unittest.main()
