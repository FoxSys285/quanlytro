import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/account_provider.dart';
import 'package:quanlytro/data/auth_validation.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/shared/auth/login_page.dart';
import 'package:quanlytro/pages/shared/auth/phone_login_page.dart';
import 'package:quanlytro/pages/shared/auth/provider_registration_page.dart';

const _session = FirebaseAccountSession(
  uid: 'tenant-a',
  role: AppRole.tenant,
  tenantId: 'tenant-tenant-a',
  email: 'tenant@example.com',
  displayName: 'Nguyễn Văn An',
  phoneNumber: '+84912345678',
);

class _Gateway extends Fake implements AccountGateway, AccountProviderGateway {
  FirebaseAccountSession? result = _session;
  Object? failure;
  String? sentPhone;
  bool linking = false;
  int sent = 0;
  int confirmed = 0;
  int signedOut = 0;
  int? resendToken;
  AppRole? newRole;
  @override
  ProviderAccountIdentity? pendingIdentity = const ProviderAccountIdentity(
    email: 'tenant@example.com',
    displayName: 'Nguyễn Văn An',
  );
  @override
  Future<FirebaseAccountSession?> signInWithGoogle() async {
    if (failure != null) throw failure!;
    return result;
  }

  @override
  Future<PhoneCodeChallenge> requestPhoneCode(
    String phoneNumber, {
    int? resendToken,
    bool linkToCurrentUser = false,
  }) async {
    sent++;
    sentPhone = phoneNumber;
    linking = linkToCurrentUser;
    this.resendToken = resendToken;
    if (failure != null) throw failure!;
    return PhoneCodeChallenge(
      resendToken: 42,
      confirm: (code) async {
        confirmed++;
        if (code != '123456') {
          throw ArgumentError('Mã OTP không đúng. Vui lòng nhập lại.');
        }
        return result;
      },
    );
  }

  @override
  Future<FirebaseAccountSession> completeProviderRegistration({
    required String displayName,
    required String phoneNumber,
    required AppRole requestedRole,
  }) async {
    newRole = requestedRole;
    return FirebaseAccountSession(
      uid: 'new-user',
      role: requestedRole,
      tenantId: requestedRole == AppRole.tenant ? 'tenant-new-user' : null,
      displayName: displayName,
      phoneNumber: normalizeVietnamesePhone(phoneNumber),
    );
  }

  @override
  Future<void> signOut() async {
    signedOut++;
  }
}

LocalAuth _auth(
  _Gateway gateway, {
  Future<void> Function(FirebaseAccountSession)? open,
}) {
  return LocalAuth()..configureFirebase(
    gateway: gateway,
    onSignedIn: open ?? (_) async {},
    onSignedOut: () async {},
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Vietnamese mobile contacts normalize consistently and reject placeholders',
    () {
      for (final value in [
        '0912345678',
        '+84912345678',
        '84 912 345 678',
        '(0912) 345-678',
      ]) {
        expect(validateAccountPhone(value), isNull);
        expect(normalizeVietnamesePhone(value), '+84912345678');
      }
      for (final value in [
        '',
        '0000000000',
        '123456789',
        '+14155552671',
        '09123456789',
      ]) {
        expect(validateAccountPhone(value), isNotNull);
      }
    },
  );

  test(
    'New provider identity cannot open private data before profile completion',
    () async {
      final gateway = _Gateway()..result = null;
      var opened = false;
      final auth = _auth(
        gateway,
        open: (_) async {
          opened = true;
        },
      );
      addTearDown(auth.dispose);
      expect(await auth.signInWithGoogle(), isFalse);
      expect(auth.role, isNull);
      expect(opened, isFalse);
      await auth.completeProviderRegistration(
        displayName: 'Nguyễn Văn An',
        phoneNumber: '0912345678',
        requestedRole: AppRole.landlord,
      );
      expect(auth.role, AppRole.landlord);
      expect(gateway.newRole, AppRole.landlord);
      expect(opened, isTrue);
    },
  );

  test('Provider denial and private data failures leave no authenticated app session', () async {
    final gateway = _Gateway()
      ..failure = ArgumentError('Tài khoản đã bị khóa.');
    final auth = _auth(gateway);
    addTearDown(auth.dispose);
    await expectLater(auth.signInWithGoogle(), throwsArgumentError);
    expect(auth.role, isNull);
    expect(gateway.signedOut, 1);
    gateway.failure = null;
    var closed = false;
    auth.configureFirebase(
      gateway: gateway,
      onSignedIn: (_) async => throw StateError('Cannot open private data'),
      onSignedOut: () async {
        closed = true;
      },
    );
    await expectLater(auth.signInWithGoogle(), throwsStateError);
    expect(auth.session, isNull);
    expect(closed, isTrue);
  });

  test(
    'Linking a verified phone preserves UID and does not reopen account data',
    () async {
      final gateway = _Gateway();
      var opens = 0;
      final auth = _auth(
        gateway,
        open: (_) async {
          opens++;
        },
      );
      addTearDown(auth.dispose);
      await auth.signInWithGoogle();
      final challenge = await auth.requestPhoneCode(
        '0912 345 678',
        linkToCurrentUser: true,
      );
      expect(gateway.sentPhone, '+84912345678');
      expect(gateway.linking, isTrue);
      await expectLater(
        auth.confirmPhoneCode(challenge, '000000', linkToCurrentUser: true),
        throwsArgumentError,
      );
      expect(auth.session?.uid, 'tenant-a');
      expect(
        await auth.confirmPhoneCode(
          challenge,
          '123456',
          linkToCurrentUser: true,
        ),
        isTrue,
      );
      expect(auth.session?.uid, 'tenant-a');
      expect(opens, 1);
    },
  );

  testWidgets('Main identifier routes a phone to OTP without a password', (
    tester,
  ) async {
    final auth = _auth(_Gateway());
    addTearDown(auth.dispose);
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await tester.enterText(find.byType(TextField).first, '0912345678');
    await tester.pump();
    await _tap(tester, find.widgetWithText(FilledButton, 'Nhận mã OTP'));
    expect(find.byType(PhoneLoginPage), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '0912345678',
    );
    expect(auth.role, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Google button starts authentication and cancellation keeps login usable',
    (tester) async {
      final gateway = _Gateway()..failure = const AccountSignInCancelled();
      final auth = _auth(gateway);
      addTearDown(auth.dispose);
      await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Google'));
      expect(auth.role, isNull);
      expect(
        find.textContaining('chưa được hỗ trợ trong phiên bản'),
        findsNothing,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Google'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('Google first signup requires a contact phone and consent', (
    tester,
  ) async {
    final gateway = _Gateway()..result = null;
    final auth = _auth(gateway);
    addTearDown(auth.dispose);
    await tester.pumpWidget(MaterialApp(home: LoginPage(auth: auth)));
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Google'));
    expect(find.byType(ProviderRegistrationPage), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Hoàn tất đăng ký'));
    expect(find.text('Vui lòng nhập số điện thoại.'), findsOneWidget);
    expect(auth.role, isNull);
    await tester.enterText(find.byType(TextFormField).last, '0912345678');
    await _tap(tester, find.widgetWithText(FilledButton, 'Hoàn tất đăng ký'));
    expect(find.textContaining('Vui lòng đồng ý'), findsOneWidget);
    expect(auth.role, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'OTP validates phone/code, keeps wrong code retryable, and throttles resend',
    (tester) async {
      final gateway = _Gateway();
      final auth = _auth(gateway);
      addTearDown(auth.dispose);
      await tester.pumpWidget(MaterialApp(home: PhoneLoginPage(auth: auth)));
      await _tap(tester, find.widgetWithText(FilledButton, 'Gửi mã OTP'));
      expect(gateway.sent, 0);
      expect(find.text('Vui lòng nhập số điện thoại.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '0912 345 678');
      await _tap(tester, find.widgetWithText(FilledButton, 'Gửi mã OTP'));
      expect(gateway.sentPhone, '+84912345678');
      expect(auth.role, isNull);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Gửi lại mã (60s)'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextFormField).last, '123');
      await _tap(tester, find.widgetWithText(FilledButton, 'Xác nhận mã OTP'));
      expect(gateway.confirmed, 0);
      await tester.enterText(find.byType(TextFormField).last, '000000');
      await _tap(tester, find.widgetWithText(FilledButton, 'Xác nhận mã OTP'));
      expect(
        find.text('Mã OTP không đúng. Vui lòng nhập lại.'),
        findsOneWidget,
      );
      expect(auth.session, isNull);
      await tester.pump(const Duration(seconds: 60));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Gửi lại mã'));
      expect(gateway.resendToken, 42);
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await _tap(tester, find.widgetWithText(FilledButton, 'Xác nhận mã OTP'));
      expect(auth.session?.uid, 'tenant-a');
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
