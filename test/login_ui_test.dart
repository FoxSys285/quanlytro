import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/main.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/auth/login_page.dart';

void main() {
  setUpAll(() async {
    RentalPortfolio.instance = RentalPortfolio.seeded();
    LandlordDemoStore.instance = RentalPortfolio.instance.stores.first;
    await LocalAuth.instance.initialize();
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Installed app login and logout at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      LocalAuth.instance.signOut();
      await tester.pumpWidget(const MyApp(requireLogin: true));
      expect(find.byType(LoginPage), findsOneWidget);
      final landlord = find.widgetWithText(ActionChip, 'Chủ trọ');
      await tester.ensureVisible(landlord);
      await tester.tap(landlord);
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField).last).controller!.text, 'Tro@2026');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      for (var i = 0; i < 200 && LocalAuth.instance.role == null; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(LocalAuth.instance.role, AppRole.landlord);
      await tester.pumpAndSettle();
      expect(find.byType(LandlordLayout), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Tài khoản'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(LocalAuth.instance.role, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
