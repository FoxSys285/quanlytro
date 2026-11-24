import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';

void main() {
  test(
    'Reapproving a stale proof saves normalized data and survives reopening',
    () {
      final source = RentalPortfolio.seeded();
      addTearDown(source.dispose);
      final raw = source.stores.first.toMap();
      for (final type in raw['roomTypes'] as List) {
        (type as Map).remove('borderColorValue');
      }
      final normalized = LandlordDemoStore.empty()..restore(raw);
      addTearDown(normalized.dispose);
      final portfolio = RentalPortfolio([normalized]);
      final id = normalized.property.id;
      final path = 'rental_properties/$id';
      final proof = propertyVerificationProof(normalized.toMap());
      Map<String, dynamic> encode(Map<String, dynamic> admin) =>
          encodeCloudDocuments(
            {'portfolio': portfolio.toMap(), 'admin': admin},
            owners: {id: 'owner'},
          )[path]!;
      final edited = encode({
        'verified': {id: true},
        'verificationProofs': {id: proof},
      });
      final live = <String, dynamic>{
        ...edited,
        'serverMetadata': 'preserve',
        'data': <String, dynamic>{
          ...edited['data'] as Map,
          'roomTypes': raw['roomTypes'],
        },
      };
      expect(
        propertyVerificationProof(live['data'] as Map<String, dynamic>),
        isNot(proof),
      );
      final loadedAdmin = <String, dynamic>{};
      restoreCloudPropertyVerification(loadedAdmin, [live]);
      expect(loadedAdmin['verified'][id], isFalse);
      final before = encode(loadedAdmin);
      // The proof already exists on the server: comparing proofs alone misses
      // this approval and a normal three-way merge retains the old room types.
      expect(edited['verificationProof'], live['verificationProof']);
      final committed = mergeCloudAdminProperty(
        before,
        edited,
        live,
        serverBefore: live,
      );
      expect(committed['serverMetadata'], 'preserve');
      expect(
        propertyVerificationProof(committed['data'] as Map<String, dynamic>),
        proof,
      );
      final reopened = LandlordDemoStore.empty();
      addTearDown(reopened.dispose);
      reopened.restore({...reopened.toMap(), ...committed['data'] as Map});
      final reopenedAdmin = <String, dynamic>{};
      restoreCloudPropertyVerification(reopenedAdmin, [committed]);
      final admin = AdminStore(portfolio: RentalPortfolio([reopened]))
        ..restore(reopenedAdmin);
      addTearDown(admin.dispose);
      expect(admin.isVerified(id), isTrue);

      final concurrent = {
        ...live,
        'data': {
          ...live['data'] as Map,
          'property': {
            ...(live['data'] as Map)['property'] as Map,
            'phone': '0912345678',
          },
        },
      };
      expect(
        () => mergeCloudAdminProperty(
          before,
          edited,
          concurrent,
          serverBefore: live,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'Approval does not write null for flags restored from property docs',
    () {
      final live = <String, dynamic>{
        'admin': {
          'verified': {'approved': true},
          'verificationProofs': {'approved': 'proof-a'},
          'reviewNotes': {'explicit-null': null},
        },
      };
      final before = <String, dynamic>{
        'admin': {
          'verified': {'approved': true, 'other': false, 'pending': false},
          'verificationProofs': {
            'approved': 'proof-a',
            'other': '',
            'pending': '',
          },
          'reviewNotes': {'explicit-null': null, 'other': ''},
        },
      };
      final edited = <String, dynamic>{
        'admin': {
          'verified': {'approved': true, 'other': false, 'pending': true},
          'verificationProofs': {
            'approved': 'proof-a',
            'other': '',
            'pending': 'proof-p',
          },
          'reviewNotes': {'explicit-null': null, 'other': 'Add documents'},
        },
      };
      final merged = mergeCloudDocument(
        before,
        edited,
        live,
        serverBefore: live,
      );
      final admin = merged['admin'] as Map;
      expect(admin['verified'], {'approved': true, 'pending': true});
      expect(admin['verificationProofs'], {
        'approved': 'proof-a',
        'pending': 'proof-p',
      });
      expect(admin['reviewNotes'], {
        'explicit-null': null,
        'other': 'Add documents',
      });
    },
  );

  test(
    'Existing null moderation maps recover without granting verification',
    () {
      final portfolio = RentalPortfolio.seeded();
      addTearDown(portfolio.dispose);
      final store = portfolio.stores.first;
      final id = store.property.id;
      final snapshot = <String, dynamic>{
        'verified': {id: null, 'stale': null},
        'verificationProofs': {id: null, 'stale': null},
        'reviewNotes': {id: null},
        'commissionRates': {id: null},
      };
      restoreCloudPropertyVerification(snapshot, [
        {
          'verified': true,
          'verificationProof': propertyVerificationProof(store.toMap()),
          'data': store.toMap(),
        },
      ]);
      restoreCloudPropertyReviews(snapshot, [
        {
          'kind': 'verificationReview',
          'propertyId': id,
          'data': {'note': 'Review'},
        },
      ]);
      final admin = AdminStore(portfolio: portfolio)..restore(snapshot);
      addTearDown(admin.dispose);
      expect(admin.isVerified(id), isTrue);
      expect(admin.isVerified('stale'), isFalse);
      expect(admin.toMap()['reviewNotes'], {id: 'Review'});
      expect(admin.toMap()['commissionRates'], isEmpty);

      restoreCloudPropertyVerification(snapshot, [
        {'verified': true, 'verificationProof': 'wrong', 'data': store.toMap()},
      ]);
      admin.restore(snapshot);
      expect(admin.isVerified(id), isFalse);
    },
  );
}
