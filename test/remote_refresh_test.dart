import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/firestore_repository.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';

Map<String, Map<String, dynamic>> copy(
  Map<String, Map<String, dynamic>> data,
) => (jsonDecode(jsonEncode(data)) as Map).map(
  (key, value) =>
      MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
);

class MemoryRemote implements RentalRepository, RentalChangeSource {
  MemoryRemote(this.data);
  Map<String, Map<String, dynamic>> data;
  bool failWrites = false;
  int writes = 0;
  final events = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => events.stream;
  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async => copy(data);
  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    if (failWrites) throw StateError('Offline');
    writes++;
    data = copy(documents);
  }

  @override
  Future<void> close() => events.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MemoryRemote> remote() async {
    await LocalAuth.instance.initialize();
    final portfolio = RentalPortfolio.seeded();
    final data = <String, Map<String, dynamic>>{
      'portfolio': portfolio.toMap(),
      'auth': LocalAuth.instance.toMap(),
      'admin': {
        'verified': {},
        'hidden': [],
        'tickets': [],
        'logs': [],
        'acceptingViewings': true,
      },
      'conversations': {'records': []},
      'viewings': {'records': [], 'nextId': 1},
      'staff': {'staff': [], 'nextId': 1},
      for (final store in portfolio.stores)
        'announcements:${store.property.id}': {
          'sent': [],
          'recipients': {},
          'readByTenant': {},
          'landlordRead': [],
          'nextId': 1,
        },
    };
    portfolio.dispose();
    return MemoryRemote(copy(data));
  }

  test(
    'Remote updates keep store instances and selection without echo writes',
    () async {
      final repository = await remote();
      final persistence = AppPersistence(repository, cloudMode: true);
      await persistence.initialize();
      addTearDown(persistence.dispose);
      final portfolio = RentalPortfolio.instance;
      final selected = portfolio.stores[1];
      portfolio.select(selected.property.id);
      await persistence.flush();
      final before = repository.writes;
      final properties = repository.data['portfolio']!['properties'] as List;
      (properties[1]['property'] as Map)['name'] = 'Nhà cập nhật từ chủ trọ';
      repository.events.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await persistence.flush();
      expect(identical(RentalPortfolio.instance, portfolio), isTrue);
      expect(identical(portfolio.active, selected), isTrue);
      expect(selected.property.name, 'Nhà cập nhật từ chủ trọ');
      await persistence.flush();
      expect(repository.writes, before);
      expect(persistence.error.value, isNull);
    },
  );

  test('Failed local edits survive a remote invalidation', () async {
    final repository = await remote();
    final persistence = AppPersistence(repository, cloudMode: true);
    await persistence.initialize();
    addTearDown(persistence.dispose);
    repository.failWrites = true;
    final store = RentalPortfolio.instance.active;
    store.updateProperty(
      LandlordProperty.fromMap({...store.property.toMap(), 'name': 'Chưa lưu'}),
    );
    await persistence.flushInBackground();
    expect(persistence.error.value, isNotNull);
    await persistence.refresh();
    expect(store.property.name, 'Chưa lưu');
    await persistence.refresh(discardUnsaved: true);
    expect(store.property.name, isNot('Chưa lưu'));
    expect(persistence.error.value, isNull);
  });

  test(
    'Retry reconnects after a read error without claiming a write',
    () async {
      final repository = await remote();
      final persistence = AppPersistence(repository, cloudMode: true);
      await persistence.initialize();
      addTearDown(persistence.dispose);
      repository.events.addError(StateError('Connection lost'));
      await Future<void>.delayed(Duration.zero);
      expect(persistence.error.value, isNotNull);
      expect(persistence.hasPendingChanges, isFalse);
      await persistence.retrySync();
      expect(persistence.error.value, isNull);
      expect(repository.writes, 0);
    },
  );

  test('Retry saves a pending edit after the connection returns', () async {
    final repository = await remote();
    final persistence = AppPersistence(repository, cloudMode: true);
    await persistence.initialize();
    addTearDown(persistence.dispose);
    repository.failWrites = true;
    final store = RentalPortfolio.instance.active;
    store.updateProperty(
      LandlordProperty.fromMap({...store.property.toMap(), 'name': 'Đã sửa'}),
    );
    await persistence.flushInBackground();
    expect(persistence.error.value, isNotNull);
    expect(persistence.hasPendingChanges, isTrue);
    repository.failWrites = false;
    await persistence.retrySync();
    expect(persistence.error.value, isNull);
    expect(persistence.hasPendingChanges, isFalse);
    expect(repository.writes, 1);
    final properties = repository.data['portfolio']!['properties'] as List;
    expect((properties.first['property'] as Map)['name'], 'Đã sửa');
  });

  test(
    'Strict Firebase session never reports an offline save as confirmed',
    () async {
      final local = await remote();
      final server = await remote();
      final repository = HybridRentalRepository(
        local: local,
        remote: server,
        strictRemote: true,
        isOnline: false,
      );
      addTearDown(repository.close);
      await expectLater(repository.readAll(), throwsStateError);
      await expectLater(repository.saveAll(local.data), throwsStateError);
      expect(repository.lastSaveReachedRemote, isFalse);
    },
  );
}
