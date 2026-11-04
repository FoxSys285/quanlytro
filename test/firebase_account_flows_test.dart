import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';

class _Credential extends Fake implements UserCredential {}

class _Firestore extends Fake implements FirebaseFirestore {}

class _Auth extends Fake implements FirebaseAuth {
  final events = <String>[];
  String? failure;
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

void main() {
  test('Register creates only an Auth identity and ends the Firebase session', () async {
    final auth = _Auth();
    final gateway = FirebaseAccountGateway(auth: auth, firestore: _Firestore());
    await gateway.register('hello@example.com', 'Secret123');
    expect(auth.events, ['create:hello@example.com', 'signOut']);
    // The Firestore fake rejects every call: registration cannot grant a role.
  });

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
        gateway.register('used@example.com', 'Secret123'),
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
