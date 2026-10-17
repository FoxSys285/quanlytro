import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/billing/landlord_billing_page.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_ui.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 800),
  ]) {
    testWidgets('Invoice details scroll above navigation at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      final invoice = LandlordDemoStore.instance.invoices.first;
      final originalCancelled = invoice.cancelled;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const LandlordBillingPage(),
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.receipt_long),
                  label: 'Hóa đơn',
                ),
                NavigationDestination(icon: Icon(Icons.home), label: 'Nhà trọ'),
              ],
            ),
          ),
        ),
      );
      final invoiceCard = find.textContaining('${invoice.id} ·');
      await tester.ensureVisible(invoiceCard);
      await tester.tap(invoiceCard);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text(invoice.id)),
        findsOneWidget,
      );
      for (final charge in invoice.charges) {
        expect(
          find.descendant(of: sheet, matching: find.text(charge.name)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: sheet, matching: find.text('Còn phải thu')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(formatLandlordMoney(invoice.remaining)),
        ),
        findsWidgets,
      );
      final cancel = find.descendant(
        of: sheet,
        matching: find.widgetWithText(OutlinedButton, 'Hủy hóa đơn'),
      );
      await tester.ensureVisible(cancel);
      await tester.pumpAndSettle();
      expect(cancel.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(cancel).bottom,
        lessThanOrEqualTo(size.height - 34),
      );
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(invoice.cancelled, originalCancelled);
      expect(cancel.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
