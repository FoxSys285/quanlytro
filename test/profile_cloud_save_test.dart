import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/firebase_media_store.dart';
import 'package:quanlytro/data/scoped_firestore_repository.dart';
import 'package:quanlytro/layouts/role_layout.dart';

import 'support/memory_firestore_queries.dart';

class _Media extends Fake implements FirebaseMediaStore {
  @override
  Future<Map<String, Map<String, dynamic>>> prepareForCloud(
    Map<String, Map<String, dynamic>> snapshot, {
    bool uploadPropertyMedia = true,
    bool uploadPaymentProofs = true,
    String? uploaderUid,
  }) async => snapshot;
}

Map<String, Map<String, dynamic>> _copy(
  Map<String, Map<String, dynamic>> snapshot,
) => (jsonDecode(jsonEncode(snapshot)) as Map).map(
  (key, value) =>
      MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
);

void main() {
  for (final role in [AppRole.landlord, AppRole.tenant]) {
    test('${role.name} saves first profile and subsequent edits', () async {
      final db = MemoryFirestore({});
      final session = FirebaseAccountSession(
        uid: 'account',
        role: role,
        tenantId: role == AppRole.tenant ? 'tenant-account' : null,
      );
      ScopedFirestoreRentalRepository repository() =>
          ScopedFirestoreRentalRepository(
            session: session,
            firestore: db,
            mediaStore: _Media(),
          );
      final source = repository();
      final initial = await source.readAll();
      initial.putIfAbsent(
        'accounts',
        () => {'contacts': {}, 'notifications': {}},
      );
      source.setLocalSnapshotBaseline(initial);
      final edited = _copy(initial);
      final contact = <String, dynamic>{
        'name': 'Tên mới',
        'phone': '0901234567',
        'email': 'profile@example.com',
        'address': 'Địa chỉ liên hệ',
      };
      edited['accounts']!['contacts'] = {role.name: contact};
      await source.saveAll(edited);
      expect(
        db.documents['user_state']!['account']!['accounts'],
        edited['accounts'],
      );

      // A fresh session must load the saved profile and allow another save.
      final reopened = repository();
      final restored = await reopened.readAll();
      expect(restored['accounts'], edited['accounts']);
      reopened.setLocalSnapshotBaseline(restored);
      final next = _copy(restored);
      next['accounts']!['contacts'][role.name]['name'] = 'Tên cập nhật';
      await reopened.saveAll(next);
      expect(
        db.documents['user_state']!['account']!['accounts'],
        next['accounts'],
      );
    });

    test('${role.name} rejects a concurrently created profile', () async {
      final db = MemoryFirestore({});
      final source = ScopedFirestoreRentalRepository(
        session: FirebaseAccountSession(
          uid: 'account',
          role: role,
          tenantId: role == AppRole.tenant ? 'tenant-account' : null,
        ),
        firestore: db,
        mediaStore: _Media(),
      );
      final initial = await source.readAll();
      initial.putIfAbsent(
        'accounts',
        () => {'contacts': {}, 'notifications': {}},
      );
      source.setLocalSnapshotBaseline(initial);
      final edited = _copy(initial);
      edited['accounts']!['contacts'] = {
        role.name: {'name': 'Local'},
      };
      final remote = <String, dynamic>{
        'accounts': {
          'contacts': {
            role.name: {'name': 'Remote'},
          },
          'notifications': {},
        },
        'favorites': {'ids': []},
      };
      db.documents['user_state'] = {'account': remote};
      await expectLater(source.saveAll(edited), throwsStateError);
      expect(db.documents['user_state']!['account'], remote);
    });
  }
}
