import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/landlord_navigation.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/meter_readings/landlord_chisodiennuoc_page.dart';

void main() {
  testWidgets('Room meter action opens without a build-time notification', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final originalPortfolio = RentalPortfolio.instance;
    addTearDown(() => RentalPortfolio.instance = originalPortfolio);
    RentalPortfolio.instance = RentalPortfolio.seeded()..select('property-3');

    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(LandlordBottomNavigation),
        matching: find.text('Phòng'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ghi điện nước'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordChiSoDienNuocPage), findsOneWidget);
    expect(find.byType(LandlordBottomNavigation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Landlord destinations open without notifying during build', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final originalPortfolio = RentalPortfolio.instance;
    addTearDown(() => RentalPortfolio.instance = originalPortfolio);
    RentalPortfolio.instance = RentalPortfolio.seeded()..select('property-3');

    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final destination in const [
      'dashboard',
      'rooms',
      'billing',
      'conversations',
      'announcements',
      'properties',
      'room_types',
      'services',
      'meter_readings',
      'viewings',
      'leases',
      'members',
      'payments',
      'payment_accounts',
      'incidents',
      'staff',
      'support',
      'settings',
    ]) {
      final pageContext = tester.element(find.byType(Scaffold).first);
      RoleLayoutShell.navigateTo(pageContext, destination);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: destination);
      expect(
        find.byType(LandlordBottomNavigation),
        findsOneWidget,
        reason: destination,
      );
    }
  });
}
