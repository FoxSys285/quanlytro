import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/admin_commission.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/firestore_repository.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/profile/account_store.dart';
import 'package:quanlytro/layouts/role_layout.dart';

class MemoryRepository implements RentalRepository {
  final data = <String, Map<String, dynamic>>{};
  bool failWrites = false;
  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async => data;
  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    if (failWrites) throw StateError('Server refused write');
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
  const liveSnapshot = String.fromEnvironment('ADMIN_LIVE_SNAPSHOT');
  if (liveSnapshot.isNotEmpty) {
    test(
      'Actual Firebase snapshot matches the live commission totals',
      () async {
        Future<Map<String, dynamic>> document(String name) async {
          final raw = jsonDecode(
            await File('$liveSnapshot/$name.json').readAsString(),
          ) as Map;
          return Map<String, dynamic>.from(
            jsonDecode(raw['fields']['payload']['stringValue'] as String)
                as Map,
          );
        }

        final portfolio = RentalPortfolio.fromMap(await document('portfolio'));
        final admin = AdminStore(portfolio: portfolio)
          ..restore(await document('admin-after'));
        expect(portfolio.stores, hasLength(10));
        final rates = [
          for (final store in portfolio.stores)
            admin.commissionRate(store.property.id),
        ];
        expect(rates, [300, 350, 400, 450, 500, 550, 600, 650, 700, 750]);
        final forecast = portfolio.stores.fold<int>(
          0,
          (sum, store) =>
              sum +
              (commissionRentCollected(store, DateTime(2026, 11)) *
                          admin.commissionRate(store.property.id)! +
                      5000) ~/
                  10000,
        );
        expect(forecast, 7305375);
        expect(admin.statements, isEmpty);
      },
    );
  }
  test('Admin edits the shared representative and member, preserving both after restore', () async {
    await LocalAuth.instance.initialize();
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
    final portfolio = RentalPortfolio.seeded();
    final store = portfolio.stores.first;
    final admin = AdminStore(portfolio: portfolio);
    final account = AccountStore(rental: store);
    expect(account.profile(AppRole.admin).phone, isEmpty);
    expect(account.profile(AppRole.admin).email, isEmpty);
    account.restore({
      'contacts': {
        'admin': {
          'name': 'Saved administrator',
          'phone': '0912345678',
          'email': 'saved@example.test',
        },
      },
      'notifications': {},
    });
    expect(account.profile(AppRole.admin).phone, '0912345678');
    account.dispose();
    for (final member in [
      store.members.firstWhere((m) => m.isRepresentative),
      store.members.firstWhere((m) => !m.isRepresentative),
    ]) {
      admin.editMemberContact(
        store.property.id,
        member.id,
        'Tên đã sửa',
        '0912345678',
      );
      final restored = RentalPortfolio.fromMap(portfolio.toMap());
      expect(
        restored
            .byId(store.property.id)!
            .members
            .firstWhere((m) => m.id == member.id)
            .name,
        'Tên đã sửa',
      );
    }
    await LocalAuth.instance.signOut();
    expect(
      () => admin.editMemberContact(
        store.property.id,
        store.members.first.id,
        'Sai quyền',
        '0912345678',
      ),
      throwsArgumentError,
    );
  });

  test('Shared edits go to the existing portfolio/admin documents; cloud failure stays visible and retries', () async {
    final local = MemoryRepository(), remote = MemoryRepository();
    await LocalAuth.instance.initialize();
    await remote.saveAll({
      'auth': LocalAuth.instance.toMap(),
      'portfolio': RentalPortfolio.seeded().toMap(),
    });
    final persistence = AppPersistence(
      HybridRentalRepository(local: local, remote: remote),
    );
    await persistence.initialize();
    expect(remote.data['staff']!['staff'], isEmpty);
    expect(remote.data['conversations']!['records'], isEmpty);
    for (final store in RentalPortfolio.instance.stores) {
      expect(
        remote.data['announcements:${store.property.id}']!['sent'],
        isEmpty,
      );
    }
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
    final store = RentalPortfolio.instance.stores.first;
    final member = store.members.first;
    AdminStore.instance.editMemberContact(
      store.property.id,
      member.id,
      'Chỉnh trực tiếp',
      '0987654321',
    );
    AdminStore.instance.setCommissionRate(store.property.id, 350);
    await persistence.saveAdminChanges();
    expect(persistence.cloudConfirmed, isTrue);
    expect(remote.data['admin']!['commissionRates'][store.property.id], 350);
    final saved = RentalPortfolio.fromMap(remote.data['portfolio']!);
    expect(saved.stores.first.members.first.name, 'Chỉnh trực tiếp');
    expect(remote.data.containsKey('adminDemo'), isFalse);
    remote.failWrites = true;
    AdminStore.instance.editMemberContact(
      store.property.id,
      member.id,
      'Giữ khi mất mạng',
      '0912345678',
    );
    await expectLater(persistence.saveAdminChanges(), throwsStateError);
    expect(persistence.error.value, isNotNull);
    expect(persistence.cloudConfirmed, isFalse);
    expect(
      RentalPortfolio.fromMap(local.data['portfolio']!)
          .stores
          .first
          .members
          .first
          .name,
      'Giữ khi mất mạng',
    );
    expect(
      RentalPortfolio.fromMap(remote.data['portfolio']!)
          .stores
          .first
          .members
          .first
          .name,
      'Chỉnh trực tiếp',
    );
    remote.failWrites = false;
    await persistence.saveAdminChanges();
    expect(persistence.error.value, isNull);
    expect(persistence.cloudConfirmed, isTrue);
    expect(
      RentalPortfolio.fromMap(remote.data['portfolio']!)
          .stores
          .first
          .members
          .first
          .name,
      'Giữ khi mất mạng',
    );
    await LocalAuth.instance.signOut();
    await expectLater(persistence.saveAdminChanges(), throwsArgumentError);
    await persistence.dispose();
  });

  test(
    'Missing persisted data fails visibly instead of generating demo records',
    () async {
      final repository = MemoryRepository();
      await expectLater(
        AppPersistence(repository).initialize(),
        throwsStateError,
      );
      expect(repository.data, isEmpty);
    },
  );
}
