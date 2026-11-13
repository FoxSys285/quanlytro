import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_editor.dart';

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

    repository.pending = Completer<void>();
    await tester.tap(find.text('Lưu phòng'));
    await tester.pump();
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomEditor), findsNothing);
    expect(repository.writes, 2);
    expect(store.catalog.where((room) => room.code == 'ZZ9'), hasLength(1));
  });
}
