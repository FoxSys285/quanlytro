import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/leases/landlord_leases_page.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_button.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_rooms_page.dart';
import 'package:quanlytro/pages/landlord/rooms/models/landlord_room.dart';

void main() {
  testWidgets('Room filters, grid and search use current property data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RentalPortfolio.instance = RentalPortfolio.seeded();
    RentalPortfolio.instance.select('may');
    final store = RentalPortfolio.instance.active;
    final vacant = store.roomDetails
        .where((room) => room.status == LandlordRoomStatus.vacant)
        .length;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LandlordRoomsPage(store: store)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomButton), findsNWidgets(12));

    await tester.tap(find.text('Phòng trống ($vacant)'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomButton), findsNWidgets(vacant));

    await tester.tap(find.byTooltip('Xem dạng lưới'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LandlordRoomButton>(find.byType(LandlordRoomButton).first)
          .compact,
      isTrue,
    );

    await tester.tap(find.text('Tất cả (${store.roomDetails.length})'));
    await tester.enterText(find.byType(TextField).first, '0987 654 321');
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomButton), findsOneWidget);
    expect(find.text('101'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vacant room opens a contract form with its room selected', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RentalPortfolio.instance = RentalPortfolio.seeded();
    RentalPortfolio.instance.select('may');
    final store = RentalPortfolio.instance.active;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LandlordRoomsPage(store: store)),
      ),
    );
    await tester.pumpAndSettle();
    final vacant = store.roomDetails.firstWhere(
      (room) => room.status == LandlordRoomStatus.vacant,
    );
    final card = find.byKey(ValueKey(vacant.room.code));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final action = find.descendant(
      of: card,
      matching: find.text('Tạo hợp đồng'),
    );
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(LandlordLeasesPage), findsOneWidget);
    expect(find.text('Tạo hợp đồng thuê phòng'), findsOneWidget);
    expect(
      find.text('Phòng ${vacant.room.leaseRoomCode ?? vacant.room.code}'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
