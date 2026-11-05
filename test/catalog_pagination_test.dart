import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_rooms_page.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_button.dart';
import 'package:quanlytro/pages/shared/media/room_photo.dart';
import 'package:quanlytro/pages/shared/media/room_photo_gallery.dart';
import 'package:quanlytro/pages/shared/widgets/list_pagination.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_card.dart';

void main() {
  test('Demo activity is additive, linked and repeatable', () {
    final portfolio = RentalPortfolio.seeded();
    addTearDown(portfolio.dispose);
    final before = portfolio.toMap().toString();
    portfolio.supplementDemoActivity();
    expect(portfolio.toMap().toString(), before);
    for (final store in portfolio.stores) {
      expect(store.payments, isNotEmpty);
      expect(store.incidents.length, greaterThanOrEqualTo(4));
      for (final payment in store.payments) {
        expect(store.invoices.any((i) => i.id == payment.invoiceId), isTrue);
      }
    }
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('Room pages reset filters and clamp after deletion at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final portfolio = RentalPortfolio.seeded();
      addTearDown(portfolio.dispose);
      final store = portfolio.add(
        const LandlordProperty(
          id: 'pagination-test',
          name: 'Pagination',
          address: 'Test',
          ownerName: 'Test',
          phone: '0900000000',
          description: 'Test',
        ),
        floors: 3,
        roomsPerFloor: 6,
      );
      for (final type in store.roomTypes) {
        store.saveRoomType(
          type.name,
          id: type.id,
          monthlyRent: type.monthlyRent,
          photos: const [RoomPhoto.studio],
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordRoomsPage(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomButton), findsNWidgets(12));
      expect(find.byType(RoomPhotoImage), findsNWidgets(12));
      await tester.ensureVisible(find.byTooltip('Trang cuối'));
      expect(
        find.descendant(
          of: find.byTooltip('Trang cuối'),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Trang cuối'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomButton), findsNWidgets(6));
      expect(find.text('Trang 2 / 2'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Trang đầu'));
      await tester.tap(find.byTooltip('Trang đầu'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomButton), findsNWidgets(12));
      expect(find.text('Trang 1 / 2'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Trang tiếp theo'));
      await tester.tap(find.byTooltip('Trang tiếp theo'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomButton), findsNWidgets(6));
      expect(find.text('Trang 2 / 2'), findsOneWidget);
      for (final room in store.catalog.skip(6).toList()) {
        store.deleteRoom(room.code);
      }
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomButton), findsNWidgets(6));
      expect(
        tester.widget<ListPagination>(find.byType(ListPagination)).page,
        0,
      );
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '101');
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomButton), findsOneWidget);
      expect(
        tester.widget<ListPagination>(find.byType(ListPagination)).page,
        0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Discovery changes pages, clamps data and resets search at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final previous = RentalPortfolio.instance;
        final portfolio = RentalPortfolio.seeded();
        RentalPortfolio.instance = portfolio;
        addTearDown(() {
          RentalPortfolio.instance = previous;
          portfolio.dispose();
        });
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: TenantDiscoveryPage(resultsOnly: true)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TenantRoomCard), findsNWidgets(8));
        final first = tester
            .widget<TenantRoomCard>(find.byType(TenantRoomCard).first)
            .room
            .id;
        await tester.ensureVisible(find.byTooltip('Trang tiếp theo'));
        await tester.tap(find.byTooltip('Trang tiếp theo'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TenantRoomCard>(find.byType(TenantRoomCard).first)
              .room
              .id,
          isNot(first),
        );
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'not-a-real-room');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.byType(TenantRoomCard), findsNothing);
        await tester.enterText(find.byType(TextField), '');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TenantRoomCard>(find.byType(TenantRoomCard).first)
              .room
              .id,
          first,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('AI entry points removed for both roles', (tester) async {
    for (final layout in [const TenantLayout(), const LandlordLayout()]) {
      await tester.pumpWidget(MaterialApp(home: layout));
      // The embedded location picker can keep waiting for a platform response.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byTooltip('Mở trợ lý AI'), findsNothing);
      await tester.tap(find.byTooltip('Mở danh mục chức năng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Trợ lý AI'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
