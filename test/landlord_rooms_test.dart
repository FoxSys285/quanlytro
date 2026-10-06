import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_card.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_rooms_page.dart';
import 'package:quanlytro/pages/landlord/rooms/models/landlord_room.dart';

void _currentLeases(LandlordDemoStore store) {
  for (final lease in store.leases) {
    lease.startDate = DateTime(2000);
    lease.endDate = DateTime(2100);
  }
}

void main() {
  test('Room list shares audience codes and respects contract prices and occupancy', () {
    final store = LandlordDemoStore.demo();
    addTearDown(store.dispose);
    _currentLeases(store);
    LandlordRoomDetails room(String code) =>
        store.roomDetails.firstWhere((item) => item.room.code == code);
    expect(
      store.roomDetails.map((item) => item.room.code).toSet(),
      LandlordDemoStore.rooms.keys.toSet(),
    );
    expect(room('101').lease!.room, 'A.101');
    expect(room('A.302').lease!.tenantName, 'Minh Anh');
    expect(room('B.105').status, LandlordRoomStatus.occupied);
    expect(room('102').status, LandlordRoomStatus.vacant);
    store.saveRoomType(
      'Phòng có ban công',
      id: 'balcony',
      monthlyRent: 4200000,
    );
    expect(room('102').monthlyRent, 4200000);
    expect(room('A.302').monthlyRent, 3500000);
    store.endLease(room('101').lease!);
    expect(room('101').status, LandlordRoomStatus.vacant);
    store.deleteRoomType('balcony');
    expect(room('102').monthlyRent, isNull);
    expect(room('A.302').monthlyRent, 3500000);
  });

  testWidgets('Landlord rooms tab opens the room list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.tap(find.text('Phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomsPage), findsOneWidget);
    expect(
      find.byType(LandlordRoomCard),
      findsNWidgets(LandlordDemoStore.rooms.length),
    );
    expect(find.text('Phòng A.302'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Room search, floor and status filters at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = LandlordDemoStore.demo();
      addTearDown(store.dispose);
      _currentLeases(store);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordRoomsPage(store: store)),
        ),
      );
      expect(find.byType(LandlordRoomCard), findsNWidgets(6));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Phòng trống'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomCard), findsNWidgets(3));
      await tester.enterText(find.byType(TextField), '102');
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomCard), findsOneWidget);
      store.saveRoomType('Ban công mới', id: 'balcony', monthlyRent: 4400000);
      await tester.pumpAndSettle();
      expect(find.text('4.400.000 đ / tháng'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tầng 2').last);
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomCard), findsNWidgets(2));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Đang thuê'));
      await tester.pumpAndSettle();
      expect(find.text('Không có phòng phù hợp với bộ lọc.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
