// Firestore SDK interfaces are sealed; these fakes isolate session restoration.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/layouts/role_layout.dart';

class _Credential extends Fake implements UserCredential {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _RestorableUser extends Fake implements User {
  _RestorableUser(this.uid);

  @override
  final String uid;

  @override
  String get email => 'tenant@example.com';
}

class _ProfileSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _ProfileSnapshot(this.profile);

  final Map<String, dynamic>? profile;

  @override
  Map<String, dynamic>? data() => profile;
}

class _ProfileDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _ProfileDocument(this.profile);

  final Map<String, dynamic>? profile;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _ProfileSnapshot(profile);
}

class _ProfileCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _ProfileCollection(this.profile);

  final Map<String, dynamic>? profile;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _ProfileDocument(profile);
}

class _ProfileFirestore extends _Firestore {
  _ProfileFirestore(this.profile);

  final Map<String, dynamic>? profile;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _ProfileCollection(profile);
}

class _RestoredAuth extends _Auth {
  _RestoredAuth(this.user);

  final User user;

  @override
  User get currentUser => user;
}

class _Auth extends Fake implements FirebaseAuth {
  final events = <String>[];
  String? failure;

  @override
  Stream<User?> authStateChanges() => Stream.value(currentUser);

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    events.add('create:$email');
    if (failure != null) throw FirebaseAuthException(code: failure!);
    return _Credential();
  }

  @override
  Future<void> signOut() async {
    events.add('signOut');
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    events.add('reset:$email');
    if (failure != null) throw FirebaseAuthException(code: failure!);
  }
}

class _PhoneAuth extends _Auth {
  String? sentPhone;
  int? resendToken;
  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    sentPhone = phoneNumber;
    resendToken = forceResendingToken;
    if (failure != null) {
      verificationFailed(FirebaseAuthException(code: failure!));
      return;
    }
    codeSent('verification-id', 23);
  }
}

void main() {
  test('Restores only a server profile with an active tenant role', () async {
    final auth = _RestoredAuth(_RestorableUser('tenant-uid'));
    final gateway = FirebaseAccountGateway(
      auth: auth,
      firestore: _ProfileFirestore({
        'role': 'tenant',
        'tenantId': 'TENANT01',
        'disabled': false,
      }),
    );

    final session = await gateway.restoreSession();
    expect(session?.uid, 'tenant-uid');
    expect(session?.role, AppRole.tenant);
    expect(session?.tenantId, 'TENANT01');
    expect(auth.events, isEmpty);
  });

  test('Invalid restored profiles close the Firebase session', () async {
    final auth = _RestoredAuth(_RestorableUser('disabled-uid'));
    final gateway = FirebaseAccountGateway(
      auth: auth,
      firestore: _ProfileFirestore({
        'role': 'tenant',
        'tenantId': 'TENANT01',
        'disabled': true,
      }),
    );

    await expectLater(gateway.restoreSession(), throwsArgumentError);
    expect(auth.events, ['signOut']);
  });

  test('Phone SDK receives E.164 and resend token, and maps early callback failures', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final auth = _PhoneAuth();
    final gateway = FirebaseAccountGateway(auth: auth, firestore: _Firestore());
    final challenge = await gateway.requestPhoneCode(
      '0912 345 678',
      resendToken: 12,
    );
    expect(auth.sentPhone, '+84912345678');
    expect(auth.resendToken, 12);
    expect(challenge.resendToken, 23);
    auth.failure = 'quota-exceeded';
    await expectLater(
      gateway.requestPhoneCode('0912345678'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('SMS'),
        ),
      ),
    );
  });
  test(
    'Legacy registration cannot create an account without a contact phone',
    () async {
      final auth = _Auth();
      final gateway = FirebaseAccountGateway(
        auth: auth,
        firestore: _Firestore(),
      );
      await expectLater(
        gateway.register('hello@example.com', 'Secret123'),
        throwsArgumentError,
      );
      expect(auth.events, isEmpty);
    },
  );

  test(
    'Reset does not disclose unknown accounts and reports network errors',
    () async {
      final auth = _Auth()..failure = 'user-not-found';
      final gateway = FirebaseAccountGateway(
        auth: auth,
        firestore: _Firestore(),
      );
      await gateway.requestPasswordReset('unknown@example.com');
      auth.failure = 'network-request-failed';
      await expectLater(
        gateway.requestPasswordReset('hello@example.com'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('kết nối mạng'),
          ),
        ),
      );
    },
  );

  test(
    'Registration reports duplicate email without opening a session',
    () async {
      final auth = _Auth()..failure = 'email-already-in-use';
      final gateway = FirebaseAccountGateway(
        auth: auth,
        firestore: _Firestore(),
      );
      await expectLater(
        gateway.registerAccount(
          'used@example.com',
          'Secret123',
          displayName: 'Nguyễn Văn An',
          phoneNumber: '0912345678',
          requestedRole: AppRole.tenant,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('đã được đăng ký'),
          ),
        ),
      );
      expect(auth.events, ['create:used@example.com']);
    },
  );
}
