import sys
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tool'))
from seed_verified_properties import eligible, select_properties


class VerifiedPropertySelectionTest(unittest.TestCase):
    def setUp(self):
        self.documents = {
            f'rental_properties/demo-{province}-{index}': {
                'importBatch': 'vn34-v1', 'isDemo': True, 'generation': 'synthetic',
                'published': True, 'provinceCode': province, 'data': {},
            } for province in range(34) for index in range(20)
        }
        self.proofs = {path: 'current-proof' for path in self.documents}

    def test_selects_400_unique_properties_balanced_across_all_provinces(self):
        selected = select_properties(self.documents, self.proofs)
        self.assertEqual(len(set(selected)), 400)
        counts = Counter(self.documents[path]['provinceCode'] for path in selected)
        self.assertEqual(len(counts), 34)
        self.assertEqual((min(counts.values()), max(counts.values())), (11, 12))
        self.assertEqual(selected, select_properties(self.documents, self.proofs))

    def test_preserves_existing_approvals_and_excludes_real_or_unpublished_data(self):
        approved = next(iter(self.documents))
        self.documents[approved].update(verified=True, verificationProof='current-proof')
        for path in list(self.documents)[1:4]:
            self.documents[path]['isDemo'] = False
        hidden = list(self.documents)[4]
        self.documents[hidden]['published'] = False
        chosen = select_properties(self.documents, self.proofs)
        self.assertIn(approved, chosen)
        self.assertNotIn(hidden, chosen)
        self.assertTrue(all(eligible(self.documents[path]) for path in chosen))

    def test_aborts_if_not_enough_synthetic_properties(self):
        with self.assertRaises(ValueError):
            select_properties({}, {})


if __name__ == '__main__':
    unittest.main()
