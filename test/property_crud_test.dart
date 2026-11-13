import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_properties_page.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';

class _UnavailableRepository extends Fake implements RentalRepository {
  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async =>
      throw StateError('Firebase unavailable');

  @override
  Future<void> close() async {}
}

class _ControlledRepository extends Fake implements RentalRepository {
  final Map<String, Map<String, dynamic>> snapshot;
  _ControlledRepository(this.snapshot);
  Completer<void>? pending;
  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async => snapshot;
  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    await pending?.future;
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A denied write keeps the session, a revoked read closes it', () {
    final denied = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    final expired = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unauthenticated',
    );
    expect(
      AppPersistence.shouldSignOutForFailure(denied, fromWrite: true),
      isFalse,
    );
    expect(AppPersistence.shouldSignOutForFailure(denied), isTrue);
    expect(
      AppPersistence.shouldSignOutForFailure(expired, fromWrite: true),
      isTrue,
    );
  });

  test('Firebase save errors identify connection and permissions separately', () {
    final offline = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    final denied = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    expect(AppPersistence.saveFailureMessage(offline), contains('kết nối'));
    expect(AppPersistence.saveFailureMessage(denied), contains('quyền Firestore'));
  });

  test('A second property produces a Firestore document owned by the landlord', () {
    final portfolio = RentalPortfolio([LandlordDemoStore.demo()]);
    addTearDown(portfolio.dispose);
    const property = LandlordProperty(
      id: 'property-1234567890123456',
      name: 'Nhà trọ mới',
      address: 'Địa chỉ mới',
      ownerName: 'Chủ trọ',
      phone: '0900000000',
      description: '',
    );
    portfolio.add(property, floors: 3, roomsPerFloor: 6);
    final documents = encodeCloudDocuments(
      {'portfolio': portfolio.toMap()},
      owners: {'may': 'owner-a', property.id: 'owner-a'},
    );
    final created = documents['rental_properties/${property.id}']!;
    expect(created['ownerUid'], 'owner-a');
    expect(created['verified'], isFalse);
    expect(created['verificationProof'], '');
    expect((created['data'] as Map)['property']['id'], property.id);
    expect(
      documents.values.where(
        (document) => document['propertyId'] == property.id &&
            document.containsKey('available'),
      ),
      hasLength(18),
    );
  });

  if (const bool.fromEnvironment('PROPERTY_CRUD_EXPORT')) {
    test(
      'Export real app property CRUD payloads for an isolated live check',
      () {
        final portfolio = RentalPortfolio([LandlordDemoStore.demo()]);
        addTearDown(portfolio.dispose);
        final id = 'crud-check-${DateTime.now().microsecondsSinceEpoch}';
        final store = portfolio.add(
          LandlordProperty(
            id: id,
            name: '[KIỂM TRA CRUD] Nhà trọ',
            address: 'Dữ liệu kiểm thử đồ án',
            ownerName: 'Chủ trọ kiểm thử',
            phone: '0900000000',
            description:
                'Nhà trọ kiểm thử tự động, sẽ được lưu trữ sau kiểm tra.',
          ),
          floors: 1,
          roomsPerFloor: 2,
        );
        Map<String, Map<String, dynamic>> encode() => encodeCloudDocuments(
          {
            'portfolio': {
              'properties': [store.toMap()],
            },
          },
          owners: {id: 'OWNER_FROM_FIREBASE'},
        );
        final created = encode();
        store.updateProperty(
          LandlordProperty.fromMap({
            ...store.property.toMap(),
            'name': '[KIỂM TRA CRUD] Đã cập nhật',
          }),
        );
        store.saveRoomType('Studio đã sửa', monthlyRent: 4200000, id: 'studio');
        final updated = encode();
        portfolio.remove(id);
        expect(portfolio.byId(id), isNull);
        final folder = Directory('.dart_tool/property_crud_check')
          ..createSync(recursive: true);
        File('${folder.path}/export.json').writeAsStringSync(
          jsonEncode({'propertyId': id, 'create': created, 'update': updated}),
        );
      },
    );
  }

  test('CRUD save waits for Firebase and surfaces rejected writes', () async {
    final repository = _ControlledRepository({
      'portfolio': RentalPortfolio([LandlordDemoStore.demo()]).toMap(),
    });
    final persistence = AppPersistence(repository, cloudMode: true);
    await persistence.initialize();
    addTearDown(persistence.dispose);
    repository.pending = Completer<void>();
    var finished = false;
    final save = persistence.saveChanges().then((_) => finished = true);
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    repository.pending!.complete();
    await save;
    expect(persistence.cloudConfirmed, isTrue);
    repository.pending = Completer<void>();
    final failed = expectLater(persistence.saveChanges(), throwsStateError);
    await Future<void>.delayed(Duration.zero);
    repository.pending!.completeError(StateError('Firebase refused write'));
    await failed;
    expect(persistence.cloudConfirmed, isFalse);
    expect(persistence.error.value, isNotNull);
  });

  test(
    'Cloud login cannot substitute seeded properties when Firebase fails',
    () async {
      final original = RentalPortfolio.instance;
      final persistence = AppPersistence(
        _UnavailableRepository(),
        cloudMode: true,
      );
      addTearDown(() async {
        await persistence.dispose();
        RentalPortfolio.instance = original;
      });
      await persistence.initializeAsync();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(persistence.initialSyncFailed, isTrue);
      expect(persistence.error.value, contains('Không tải được dữ liệu'));
      expect(RentalPortfolio.instance.stores, isEmpty);
    },
  );

  test(
    'A new property has empty business records and no sample bank account',
    () {
      final portfolio = RentalPortfolio([LandlordDemoStore.demo()]);
      addTearDown(portfolio.dispose);
      final store = portfolio.add(
        const LandlordProperty(
          id: 'new-house',
          name: 'Nhà mới',
          address: 'Địa chỉ',
          ownerName: 'Chủ trọ',
          phone: '0900000000',
          description: 'Nhà vừa tạo',
        ),
        floors: 1,
        roomsPerFloor: 2,
      );
      expect(store.catalog, hasLength(2));
      expect(store.roomTypes, hasLength(4));
      expect(store.leases, isEmpty);
      expect(store.invoices, isEmpty);
      expect(store.payments, isEmpty);
      expect(store.paymentAccounts, isEmpty);
      portfolio.remove(store.property.id);
      expect(portfolio.byId('new-house'), isNull);
    },
  );

  testWidgets('A landlord with one property can still add another', (
    tester,
  ) async {
    final original = RentalPortfolio.instance;
    final portfolio = RentalPortfolio([LandlordDemoStore.demo()]);
    RentalPortfolio.instance = portfolio;
    addTearDown(() {
      RentalPortfolio.instance = original;
      portfolio.dispose();
    });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LandlordPropertiesPage())),
    );
    expect(find.text('Thêm nhà trọ'), findsOneWidget);
  });
}
