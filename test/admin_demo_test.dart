import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_commission.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/firestore_repository.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/pages/admin/admin_demo_data.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';

class MemoryRepository implements RentalRepository {
  bool failWrites = false;
  final data = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async => {
    for (final e in data.entries)
      e.key: Map<String, dynamic>.from(jsonDecode(jsonEncode(e.value)) as Map),
  };
  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    if (failWrites) throw StateError('Disk full');
    for (final e in documents.entries) {
      data[e.key] = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(e.value)) as Map,
      );
    }
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LocalAuth.instance.initialize();
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
  });

  test('Demo finance covers unset, draft, waiting, partial and paid; edits round-trip independently', () {
    final original = jsonEncode(RentalPortfolio.instance.toMap());
    final demo = AdminDemoData()..now = DateTime(2026, 6, 15);
    final houses = demo.portfolio.stores;
    expect(demo.month, DateTime(2026, 5));
    expect(houses, hasLength(10));
    expect(demo.accounts, hasLength(24));
    expect(demo.admin.commissionRate(houses[0].property.id), isNull);
    expect(demo.admin.commissionRate(houses[1].property.id), 500);
    expect(commissionRentCollected(houses.first, demo.month), 12000000);
    final statements = demo.admin.statements
        .where((s) => s.month == demo.month)
        .toList();
    expect(statements, hasLength(8));
    expect(statements.any((s) => s.received == 0), isTrue);
    expect(statements.any((s) => s.received > 0 && s.remaining > 0), isTrue);
    expect(statements.any((s) => s.remaining == 0), isTrue);
    final member = houses.first.members.first;
    demo.editMember(
      houses.first.property.id,
      member.id,
      'Tên đã sửa',
      '0912345678',
    );
    demo.setLocked('sample-owner-0', true);
    demo.admin.setCommissionRate(houses.first.property.id, 750);
    demo.admin.closeCommission(houses.first.property.id, demo.month);
    final closed = demo.admin.statements.firstWhere(
      (s) => s.propertyId == houses.first.property.id && s.month == demo.month,
    );
    demo.admin.receiveCommission(closed, 100000, 'DEMO-NEW');
    final restored = AdminDemoData()
      ..restore(
        Map<String, dynamic>.from(jsonDecode(jsonEncode(demo.toMap())) as Map),
      );
    expect(restored.toMap(), demo.toMap());
    expect(restored.portfolio.stores.first.members.first.name, 'Tên đã sửa');
    expect(restored.portfolio.stores.first.members.first.phone, '0912345678');
    expect(
      restored.accounts.firstWhere((a) => a.id == 'sample-owner-0').disabled,
      isTrue,
    );
    expect(jsonEncode(RentalPortfolio.instance.toMap()), original);
    expect(
      () => demo.editMember(houses.first.property.id, member.id, '', 'abc'),
      throwsArgumentError,
    );
  });

  test('Firebase chunks preserve edits and reject incomplete/mixed snapshots atomically', () {
    final demo = AdminDemoData()..enabled = true;
    final docs = demo.cloudDocuments('admin_demo');
    expect(docs, hasLength(11));
    expect(
      docs.keys.any((id) => ['portfolio', 'auth', 'admin'].contains(id)),
      isFalse,
    );
    expect(
      docs.values.every((d) => utf8.encode(jsonEncode(d)).length <= 800000),
      isTrue,
    );
    final restored = AdminDemoData()..restoreCloudDocuments(docs, 'admin_demo');
    expect(restored.toMap(), demo.toMap());
    final before = jsonEncode(restored.toMap());
    final part = docs.keys.firstWhere((k) => k != 'admin_demo');
    docs[part]!['generation'] = 'mismatch';
    expect(
      () => restored.restoreCloudDocuments(docs, 'admin_demo'),
      throwsArgumentError,
    );
    expect(jsonEncode(restored.toMap()), before);
    docs.remove(part);
    expect(
      () => restored.restoreCloudDocuments(docs, 'admin_demo'),
      throwsArgumentError,
    );
    expect(jsonEncode(restored.toMap()), before);
  });

  test(
    'Autosave keeps demo local through Hybrid, and restores it on reopen',
    () async {
      final local = MemoryRepository(), remote = MemoryRepository();
      final hybrid = HybridRentalRepository(local: local, remote: remote);
      var persistence = AppPersistence(hybrid);
      await persistence.initialize();
      AdminDemoData.instance.toggle();
      await persistence.flush();
      expect(local.data['adminDemo']?['enabled'], isTrue);
      expect(remote.data.containsKey('adminDemo'), isFalse);
      await persistence.dispose();
      AdminDemoData.instance.enabled = false;
      persistence = AppPersistence(hybrid);
      await persistence.initialize();
      expect(AdminDemoData.instance.enabled, isTrue);
      expect(remote.data.containsKey('adminDemo'), isFalse);
      local.failWrites = true;
      AdminDemoData.instance.toggle();
      await persistence.flush();
      expect(persistence.error.value, isNotNull);
      expect(local.data['adminDemo']?['enabled'], isTrue);
      local.failWrites = false;
      AdminDemoData.instance.toggle();
      await persistence.flush();
      expect(persistence.error.value, isNull);
      await persistence.dispose();
      AdminDemoData.instance.enabled = false;
    },
  );

  test(
    'Signed-out preview cannot edit samples or initiate Firebase writes',
    () async {
      await LocalAuth.instance.signOut();
      final demo = AdminDemoData();
      final store = demo.portfolio.stores.first;
      expect(() => demo.setLocked('sample-1', true), throwsArgumentError);
      expect(
        () => demo.editMember(
          store.property.id,
          store.members.first.id,
          'Tên mới',
          '0912345678',
        ),
        throwsArgumentError,
      );
      await expectLater(
        AppPersistence(MemoryRepository()).syncAdminDemo(download: false),
        throwsArgumentError,
      );
    },
  );
}
