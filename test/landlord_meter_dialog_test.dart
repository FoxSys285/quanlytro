import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_theme.dart';
import 'package:quanlytro/pages/landlord/landlord_ui.dart';
import 'package:quanlytro/pages/landlord/meter_readings/landlord_chisodiennuoc_page.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Meter dialog fits a $width px phone', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final originalPortfolio = RentalPortfolio.instance;
      addTearDown(() => RentalPortfolio.instance = originalPortfolio);
      RentalPortfolio.instance = RentalPortfolio.seeded()..select('property-3');

      await tester.pumpWidget(
        MaterialApp(
          theme: landlordTheme(dark: false),
          home: const Scaffold(body: LandlordChiSoDienNuocPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(LandlordCard).first);
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      final fields = find.descendant(
        of: dialog,
        matching: find.byType(TextField),
      );
      expect(dialog, findsOneWidget);
      expect(fields, findsNWidgets(2));
      expect(find.text('Chỉ số điện'), findsOneWidget);
      expect(find.text('Chỉ số nước'), findsOneWidget);
      expect(find.textContaining('Cũ:'), findsNWidgets(2));
      expect(tester.getRect(fields.first).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(fields.first).right, lessThanOrEqualTo(width));
      expect(
        tester.getRect(find.text('Chỉ số điện')).bottom,
        lessThan(tester.getRect(fields.first).top),
      );
      expect(
        tester.getRect(fields.first).bottom,
        lessThan(tester.getRect(find.text('Chỉ số nước')).top),
      );
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(fields.last);
      await tester.pumpAndSettle();
      expect(tester.getRect(fields.last).bottom, lessThanOrEqualTo(740 - 260));
    });
  }
}
