import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_editor.dart';
import 'package:quanlytro/pages/landlord/rooms/models/landlord_room.dart';

class _RoomRepository implements RentalRepository {
  _RoomRepository(this.snapshot);
  Map<String, Map<String, dynamic>> snapshot;
  Completer<void>? pending;
  int writes = 0;

  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async => snapshot;

  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    writes++;
    await pending?.future;
    snapshot = documents;
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Room area accepts the configured integer range and rejects invalid input',
    (tester) async {
      final store = LandlordDemoStore.demo();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => LandlordRoomEditor(store: store),
                ),
                child: const Text('Mở biểu mẫu'),
              ),
            ),
          ),
        ),
      );

      for (final area in [6, 25, 99, 100, 101, 500]) {
        await tester.tap(find.text('Mở biểu mẫu'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'AREA-$area');
        await tester.enterText(find.byType(TextFormField).at(2), '$area');
        await tester.tap(find.text('Lưu phòng'));
        await tester.pumpAndSettle();
        expect(find.byType(LandlordRoomEditor), findsNothing);
        expect(
          store.catalog.singleWhere((room) => room.code == 'AREA-$area').area,
          area,
        );
      }

      for (final (index, value) in [
        (0, ''),
        (1, 'abc'),
        (2, '0'),
        (3, '-1'),
        (4, '5'),
        (5, '501'),
        (6, '25.5'),
      ]) {
        final code = 'INVALID-$index';
        await tester.tap(find.text('Mở biểu mẫu'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, code);
        await tester.enterText(find.byType(TextFormField).at(2), value);
        await tester.tap(find.text('Lưu phòng'));
        await tester.pumpAndSettle();
        expect(find.text('Nhập giá trị từ 6 đến 500.'), findsOneWidget);
        expect(store.catalog.any((room) => room.code == code), isFalse);
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      }

      const room = LandlordRoom(
        code: 'EDIT-AREA',
        floor: 1,
        area: 25,
        capacity: 2,
        roomTypeId: 'studio',
      );
      store.saveRoom(room);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => LandlordRoomEditor(store: store, room: room),
                ),
                child: const Text('Sửa phòng'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sửa phòng'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '100');
      await tester.tap(find.text('Lưu phòng'));
      await tester.pumpAndSettle();
      expect(
        store.catalog.singleWhere((room) => room.code == 'EDIT-AREA').area,
        100,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Room editor stays open until Firebase confirms the save', (
    tester,
  ) async {
    final seed = RentalPortfolio([LandlordDemoStore.demo()]);
    final repository = _RoomRepository({'portfolio': seed.toMap()});
    addTearDown(seed.dispose);
    final persistence = AppPersistence(repository, cloudMode: true);
    await tester.runAsync(persistence.initialize);
    final store = RentalPortfolio.instance.active;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => LandlordRoomEditor(store: store),
              ),
              child: const Text('Mở biểu mẫu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở biểu mẫu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'ZZ9');
    repository.pending = Completer<void>();
    await tester.tap(find.text('Lưu phòng'));
    await tester.pump();
    expect(find.byType(LandlordRoomEditor), findsOneWidget);
    expect(find.text('Đang lưu...'), findsOneWidget);

    repository.pending!.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomEditor), findsOneWidget);
    expect(find.textContaining('chờ lưu lên Firebase'), findsOneWidget);
    expect(store.catalog.where((room) => room.code == 'ZZ9'), hasLength(1));
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    await tester.pump();

    repository.pending = Completer<void>();
    await tester.tap(find.text('Lưu phòng'));
    await tester.pump();
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomEditor), findsNothing);
    expect(repository.writes, 2);
    expect(store.catalog.where((room) => room.code == 'ZZ9'), hasLength(1));
    expect(store.catalog.singleWhere((room) => room.code == 'ZZ9').area, 100);
    final savedPortfolio = repository.snapshot['portfolio']!;
    final savedProperty = (savedPortfolio['properties'] as List)
        .cast<Map>()
        .singleWhere(
          (property) =>
              (property['property'] as Map)['id'] == store.property.id,
        );
    final savedRoom = (savedProperty['rooms'] as List).cast<Map>().singleWhere(
      (room) => room['code'] == 'ZZ9',
    );
    expect(savedRoom['area'], 100);
  });

  testWidgets('Duplicate room codes are rejected at the room field', (
    tester,
  ) async {
    final store = LandlordDemoStore.demo();
    addTearDown(store.dispose);
    store.saveRoom(
      const LandlordRoom(
        code: 'P103',
        floor: 1,
        area: 25,
        capacity: 2,
        roomTypeId: 'studio',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => LandlordRoomEditor(store: store),
              ),
              child: const Text('Mở biểu mẫu'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở biểu mẫu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'p103');
    await tester.tap(find.text('Lưu phòng'));
    await tester.pumpAndSettle();

    expect(find.text('Mã phòng này đã tồn tại.'), findsOneWidget);
    expect(store.catalog.where((room) => room.code == 'P103'), hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
  });
}
