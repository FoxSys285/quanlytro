import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/landlord_navigation.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_theme.dart';
import 'package:quanlytro/pages/landlord/landlord_ui.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_property_detail_page.dart';
import 'package:quanlytro/pages/landlord/properties/property_portfolio_page.dart';
import 'package:quanlytro/pages/landlord/room_types/landlord_room_types_page.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_button.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_rooms_page.dart';

void main() {
  late RentalPortfolio original;
  late RentalPortfolio portfolio;
  late LandlordDemoStore store;
  setUp(() {
    original = RentalPortfolio.instance;
    store = LandlordDemoStore.demo();
    portfolio = RentalPortfolio([store]);
    RentalPortfolio.instance = portfolio;
  });
  tearDown(() {
    RentalPortfolio.instance = original;
    portfolio.dispose();
    store.dispose();
  });

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 800),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Property detail and both embedded tabs fit $size, dark=$dark',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: landlordTheme(dark: dark),
              home: const Scaffold(body: PropertyPortfolioPage()),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byTooltip('Xem phòng'));
          await tester.tap(find.byTooltip('Xem phòng'));
          await tester.pumpAndSettle();
          expect(find.byType(LandlordPropertyDetailPage), findsOneWidget);
          expect(find.byType(LandlordPageFrame), findsNothing);
          expect(find.text('QUẢN LÝ KHÔNG GIAN'), findsNothing);
          expect(find.text('Danh sách phòng trọ'), findsNothing);
          expect(
            tester
                .widget<LandlordRoomsPage>(find.byType(LandlordRoomsPage))
                .embedded,
            isTrue,
          );
          final tab = find.text('Loại phòng (${store.roomTypes.length})');
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<LandlordRoomTypesPage>(
                  find.byType(LandlordRoomTypesPage),
                )
                .embedded,
            isTrue,
          );
          expect(find.text('BỘ SƯU TẬP KHÔNG GIAN'), findsNothing);
          expect(find.byType(LandlordPageFrame), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Detail has one vertical scroll, preserves filters across tabs and handles Android back',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(LandlordBottomNavigation),
          matching: find.text('Nhà trọ'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Xem phòng'));
      await tester.tap(find.byTooltip('Xem phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordBottomNavigation), findsOneWidget);
      final verticalScrolls = find.descendant(
        of: find.byType(LandlordPropertyDetailPage),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
        ),
      );
      expect(verticalScrolls, findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '102');
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomButton), findsOneWidget);
      await tester.ensureVisible(
        find.text('Loại phòng (${store.roomTypes.length})'),
      );
      await tester.tap(find.text('Loại phòng (${store.roomTypes.length})'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phòng trọ (${store.catalog.length})'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '102',
      );
      expect(find.byType(LandlordRoomButton), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LandlordPropertyDetailPage), findsNothing);
      expect(find.text('Danh sách nhà trọ'), findsOneWidget);
      expect(find.byType(LandlordBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
