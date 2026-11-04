import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/pages/shared/auth/forgot_password_page.dart';
import 'package:quanlytro/pages/shared/auth/register_page.dart';

class _Gateway extends Fake implements AccountGateway {
  int registrations = 0;
  int resets = 0;
  String? email;
  String? password;
  String? failure;

  @override
  Future<void> register(String email, String password) async {
    if (failure != null) throw ArgumentError(failure!);
    registrations++;
    this.email = email;
    this.password = password;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    if (failure != null) throw ArgumentError(failure!);
    resets++;
    this.email = email;
  }
}

LocalAuth _cloudAuth(_Gateway gateway) => LocalAuth()
  ..configureFirebase(
    gateway: gateway,
    onSignedIn: (_) async =>
        fail('Registration and recovery must not open private data'),
    onSignedOut: () async {},
  );

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _fillRegistration(
  WidgetTester tester, {
  String confirmation = 'Secret123',
}) async {
  for (final entry in [
    (0, ' NEW@Example.com '),
    (1, 'Secret123'),
    (2, confirmation),
  ]) {
    final field = find.byType(TextFormField).at(entry.$1);
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.$2);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'Registration validates confirmation and consent before creating an unprivileged account',
    (tester) async {
      final gateway = _Gateway();
      final auth = _cloudAuth(gateway);
      addTearDown(auth.dispose);
      await tester.pumpWidget(MaterialApp(home: RegisterPage(auth: auth)));
      await _fillRegistration(tester, confirmation: 'Different123');
      final submit = find.widgetWithText(FilledButton, 'Đăng ký tài khoản');
      await _tap(tester, submit);
      expect(find.text('Mật khẩu xác nhận chưa khớp.'), findsOneWidget);
      expect(gateway.registrations, 0);
      await tester.enterText(find.byType(TextFormField).last, 'Secret123');
      await _tap(tester, submit);
      expect(
        find.text(
          'Vui lòng đồng ý với điều khoản sử dụng và chính sách bảo mật.',
        ),
        findsOneWidget,
      );
      expect(gateway.registrations, 0);
      await _tap(tester, find.byType(CheckboxListTile));
      await _tap(tester, submit);
      expect(gateway.registrations, 1);
      expect(gateway.email, 'new@example.com');
      expect(gateway.password, 'Secret123');
      expect(auth.role, isNull);
      expect(auth.session, isNull);
      expect(find.text('Đã tạo tài khoản'), findsOneWidget);
      expect(find.textContaining('cấp vai trò'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Registration failures keep the form and never report success', (
    tester,
  ) async {
    final gateway = _Gateway()..failure = 'Email này đã được đăng ký.';
    final auth = _cloudAuth(gateway);
    addTearDown(auth.dispose);
    await tester.pumpWidget(MaterialApp(home: RegisterPage(auth: auth)));
    await _fillRegistration(tester);
    await _tap(tester, find.byType(CheckboxListTile));
    await _tap(tester, find.widgetWithText(FilledButton, 'Đăng ký tài khoản'));
    expect(find.text('Email này đã được đăng ký.'), findsOneWidget);
    expect(find.text('Đã tạo tài khoản'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      ' NEW@Example.com ',
    );
    expect(auth.role, isNull);
  });

  testWidgets(
    'Recovery validates email, confirms sending, and limits resend attempts',
    (tester) async {
      final gateway = _Gateway();
      final auth = _cloudAuth(gateway);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordPage(auth: auth)),
      );
      await tester.enterText(find.byType(TextFormField), 'bad-email');
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Gửi liên kết khôi phục'),
      );
      expect(find.text('Địa chỉ email chưa hợp lệ.'), findsOneWidget);
      expect(gateway.resets, 0);
      await tester.enterText(find.byType(TextFormField), ' USER@Example.com ');
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Gửi liên kết khôi phục'),
      );
      expect(gateway.resets, 1);
      expect(gateway.email, 'user@example.com');
      expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Gửi lại liên kết (60s)'),
            )
            .onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 60));
      await _tap(
        tester,
        find.widgetWithText(OutlinedButton, 'Gửi lại liên kết'),
      );
      expect(gateway.resets, 2);
      expect(auth.role, isNull);
      await _tap(tester, find.text('Dùng email khác'));
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Demo recovery explains limitations instead of pretending to send email',
    (tester) async {
      final auth = LocalAuth();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordPage(
            auth: auth,
            initialEmail: 'tenant@tro.local',
          ),
        ),
      );
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Gửi liên kết khôi phục'),
      );
      expect(find.text('Kiểm tra email của bạn'), findsNothing);
      expect(
        find.textContaining('Bản dùng thử không gửi email khôi phục.'),
        findsNWidgets(2),
      );
      expect(auth.role, isNull);
    },
  );

  for (final width in [320.0, 390.0, 1280.0]) {
    for (final registration in [true, false]) {
      testWidgets(
        '${registration ? 'Registration' : 'Recovery'} fits at $width with large text and keyboard',
        (tester) async {
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
              home: registration
                  ? const RegisterPage()
                  : const ForgotPasswordPage(),
            ),
          );
          await _tap(
            tester,
            find.widgetWithText(
              FilledButton,
              registration ? 'Đăng ký tài khoản' : 'Gửi liên kết khôi phục',
            ),
          );
          expect(find.text('Vui lòng nhập email.'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
