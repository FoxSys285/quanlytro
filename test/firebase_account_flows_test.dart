// Firestore SDK interfaces are sealed; these fakes isolate account flows.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/layouts/role_layout.dart';

class _Credential extends Fake implements UserCredential {
  _Credential([this.user]);

  @override
  final User? user;
}

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
  bool get exists => profile != null;

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
  User? registrationUser;
  String? signInFailure = 'invalid-credential';

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
    return _Credential(registrationUser);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    events.add('signIn:$email');
    if (signInFailure != null) {
      throw FirebaseAuthException(code: signInFailure!);
    }
    return _Credential(registrationUser);
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

class _RegistrationDocument extends _ProfileDocument {
  _RegistrationDocument(this.store, this.path) : super(null);

  final _RegistrationFirestore store;
  @override
  final String path;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _ProfileSnapshot(store.documents[path]);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    store.documents[path] = data;
  }
}

class _RegistrationCollection extends _ProfileCollection {
  _RegistrationCollection(this.store, this.path) : super(null);

  final _RegistrationFirestore store;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _RegistrationDocument(store, '${this.path}/$path');
}

class _RegistrationTransaction extends Fake implements Transaction {
  _RegistrationTransaction(this.store);

  final _RegistrationFirestore store;
  final writes = <String, Map<String, dynamic>>{};

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async =>
      _ProfileSnapshot(store.documents[documentReference.path])
          as DocumentSnapshot<T>;

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    writes[documentReference.path] = data as Map<String, dynamic>;
    return this;
  }
}

class _RegistrationFirestore extends _Firestore {
  final documents = <String, Map<String, dynamic>>{};
  String? failure;
  int transactions = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _RegistrationCollection(this, path);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    transactions++;
    final transaction = _RegistrationTransaction(this);
    final result = await transactionHandler(transaction);
    if (failure != null) {
      throw FirebaseException(plugin: 'cloud_firestore', code: failure!);
    }
    documents.addAll(transaction.writes);
    return result;
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
    'Duplicate registration requires the existing account password',
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
      expect(auth.events, [
        'create:used@example.com',
        'signIn:used@example.com',
      ]);
    },
  );

  test(
    'Login explains how to finish a signup with a missing profile',
    () async {
      final auth = _Auth()
        ..registrationUser = _RestorableUser('incomplete-uid')
        ..signInFailure = null;
      final gateway = FirebaseAccountGateway(
        auth: auth,
        firestore: _ProfileFirestore(null),
      );

      await expectLater(
        gateway.signIn('tenant@example.com', 'Secret123'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('đăng ký lại với cùng email và mật khẩu'),
          ),
        ),
      );
      expect(auth.events, ['signIn:tenant@example.com', 'signOut']);
    },
  );

  for (final role in [AppRole.tenant, AppRole.landlord]) {
    test(
      'Retries an interrupted ${role.name} signup using the same UID',
      () async {
        final auth = _Auth()
          ..registrationUser = _RestorableUser('signup-uid')
          ..signInFailure = null;
        final firestore = _RegistrationFirestore()
          ..failure = 'permission-denied';
        final gateway = FirebaseAccountGateway(
          auth: auth,
          firestore: firestore,
        );

        Future<FirebaseAccountSession> register() => gateway.registerAccount(
          'tenant@example.com',
          'Secret123',
          displayName: 'Nguyễn Văn An',
          phoneNumber: '0912345678',
          requestedRole: role,
        );

        await expectLater(
          register(),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Chưa lưu được hồ sơ đăng ký. Vui lòng thử đăng ký lại với cùng email và mật khẩu.',
            ),
          ),
        );
        expect(firestore.documents, isEmpty);
        expect(auth.events.last, 'signOut');

        auth.failure = 'email-already-in-use';
        firestore.failure = null;
        final session = await register();
        expect(session.uid, 'signup-uid');
        expect(session.role, role);
        expect(session.phoneNumber, '+84912345678');
        expect(auth.events.last, 'signIn:tenant@example.com');
        expect(firestore.documents['users/signup-uid']?['role'], role.name);
        if (role == AppRole.tenant) {
          expect(session.tenantId, matches(r'^[A-Z0-9]{8}$'));
          expect(
            firestore.documents,
            contains('tenant_codes/${session.tenantId}'),
          );
          expect(firestore.documents['tenant_contacts/${session.tenantId}'], {
            'displayName': 'Nguyễn Văn An',
            'phoneNumber': '+84912345678',
          });
        } else {
          expect(session.tenantId, isNull);
          expect(firestore.documents.length, 1);
        }
      },
    );
  }

  for (final disabled in [false, true]) {
    test(
      'Duplicate signup cannot replace an existing disabled=$disabled profile',
      () async {
        final auth = _Auth()
          ..failure = 'email-already-in-use'
          ..registrationUser = _RestorableUser('existing-uid')
          ..signInFailure = null;
        final original = {
          'role': 'tenant',
          'tenantId': 'TENANT01',
          'disabled': disabled,
        };
        final firestore = _RegistrationFirestore()
          ..documents['users/existing-uid'] = original;
        final gateway = FirebaseAccountGateway(
          auth: auth,
          firestore: firestore,
        );

        await expectLater(
          gateway.registerAccount(
            'tenant@example.com',
            'Secret123',
            displayName: 'Changed Name',
            phoneNumber: '0912345678',
            requestedRole: AppRole.landlord,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('Email này đã được đăng ký'),
            ),
          ),
        );
        expect(firestore.documents, {'users/existing-uid': original});
        expect(firestore.transactions, 0);
        expect(auth.events.last, 'signOut');
      },
    );
  }
}
