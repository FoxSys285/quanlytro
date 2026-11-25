import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/landlord_navigation.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/admin/admin_page_router.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/property_portfolio_page.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_button.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_editor.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_rooms_page.dart';

void main() {
  setUpAll(() {
    RentalPortfolio.instance = RentalPortfolio.seeded();
    LandlordDemoStore.instance = RentalPortfolio.instance.stores.first;
  });

  testWidgets(
    'Landlord theme switch updates the workspace and keeps navigation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
      await tester.pumpAndSettle();
      expect(find.text('Thao tác nhanh'), findsOneWidget);
      expect(find.text('Xem & quản lý phòng trọ'), findsOneWidget);

      await tester.tap(find.byTooltip('Mở danh mục chức năng'));
      await tester.pumpAndSettle();
      final lightTooltip = find.byTooltip('Chuyển sang giao diện sáng');
      final darkTooltip = find.byTooltip('Chuyển sang giao diện tối');
      final switchingToLight = lightTooltip.evaluate().isNotEmpty;
      await tester.tap(switchingToLight ? lightTooltip : darkTooltip);
      await tester.pumpAndSettle();
      expect(switchingToLight ? darkTooltip : lightTooltip, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Phòng trọ'),
        ),
        250,
        scrollable: find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Phòng trọ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomsPage), findsOneWidget);
      expect(find.byType(LandlordBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets('Production portfolio, selection and room editor at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      RentalPortfolio.instance.select('may');
      await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
      await tester.tap(find.byTooltip('Mở danh mục chức năng'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Nhà trọ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PropertyPortfolioPage), findsOneWidget);
      expect(
        find.text('${RentalPortfolio.instance.active.catalog.length} phòng'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      final propertyName = find.text('Nhà Nâu').first;
      await tester.ensureVisible(propertyName);
      await tester.tap(propertyName);
      await tester.pumpAndSettle();
      expect(RentalPortfolio.instance.active.property.name, 'Nhà Nâu');
      expect(find.text('Phòng trọ (18)'), findsOneWidget);
      expect(find.byType(LandlordRoomsPage), findsOneWidget);
      expect(find.byType(LandlordRoomButton), findsNWidgets(12));
      await tester.ensureVisible(find.text('Thêm phòng mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm phòng mới'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomEditor), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thêm phòng mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm phòng mới'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomEditor), findsOneWidget);
      await tester.tap(find.text('Lưu phòng'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập mã phòng.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('Admin destinations render operational content at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final id in [
        'dashboard',
        'users',
        'property_verification',
        'moderation',
        'support',
        'audit_logs',
        'settings',
        'profile',
        'notifications',
      ]) {
        final destination = RoleDestination(
          id: id,
          label: id,
          icon: Icons.home,
          group: 'admin',
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KeyedSubtree(
                key: ValueKey(id),
                child: Builder(
                  builder: (context) => buildAdminPage(context, destination),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$id at $width');
        expect(find.textContaining('sẽ được thiết kế'), findsNothing);
      }
    });
  }
}
