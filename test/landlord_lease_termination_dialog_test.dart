import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_theme.dart';
import 'package:quanlytro/pages/landlord/leases/landlord_leases_page.dart';

void main() {
  testWidgets('Ending a lease closes the reason dialog safely', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final store = LandlordDemoStore.demo();
    addTearDown(store.dispose);
    final currentLeases =
        store.leases.where((lease) => lease.isCurrent).toList()
          ..sort((a, b) => a.endDate.compareTo(b.endDate));
    final leaseToEnd = currentLeases.first;

    await tester.pumpWidget(
      MaterialApp(
        theme: landlordTheme(dark: false),
        home: Scaffold(body: LandlordLeasesPage(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    final endButtons = find.text('Kết thúc');
    await tester.ensureVisible(endButtons.first);
    await tester.tap(endButtons.first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Manual test closure');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Kết thúc hợp đồng'));
    await tester.pumpAndSettle();

    expect(leaseToEnd.status, LandlordLeaseStatus.terminated);
    expect(tester.takeException(), isNull);
  });
}
