import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/main.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/auth/login_page.dart';
import 'package:quanlytro/pages/shared/auth/forgot_password_page.dart';
import 'package:quanlytro/pages/shared/auth/register_page.dart';

void main() {
  setUpAll(() async {
    RentalPortfolio.instance = RentalPortfolio.seeded();
    LandlordDemoStore.instance = RentalPortfolio.instance.stores.first;
    await LocalAuth.instance.initialize();
  });

  for (final width in [320.0, 390.0, 600.0, 860.0]) {
    testWidgets('Login remains usable with large text and keyboard at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 740);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const LoginPage(),
        ),
      );
      expect(find.text('Apple'), findsNothing);
      expect(
        tester.getCenter(find.text('Hoặc đăng nhập bằng')).dx,
        closeTo(
          tester
              .getCenter(
                find.byKey(const ValueKey('login-alternative-divider')),
              )
              .dx,
          0.1,
        ),
      );
      final password = find.byType(TextField).last;
      await tester.ensureVisible(password);
      await tester.enterText(password, 'a-password');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Hiện mật khẩu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      final login = find.widgetWithText(FilledButton, 'Đăng nhập');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(
        find.text('Vui lòng nhập email hoặc số điện thoại.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Login opens registration and recovery with the entered email', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.enterText(find.byType(TextField).first, 'hello@example.com');
    final register = find.text('Đăng ký ngay');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      'hello@example.com',
    );
    final back = find.widgetWithText(TextButton, 'Đăng nhập').first;
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    final forgot = find.text('Quên mật khẩu?');
    await tester.ensureVisible(forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'hello@example.com',
    );
    expect(tester.takeException(), isNull);
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
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'Tro@2026',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Đăng nhập'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      for (var i = 0; i < 200 && LocalAuth.instance.role == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
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
