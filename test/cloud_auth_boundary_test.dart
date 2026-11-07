import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/layouts/role_layout.dart';

class _Gateway implements AccountGateway {
  bool deny = false;
  int signedOut = 0;
  String? registeredEmail;
  String? resetEmail;
  @override
  Future<void> register(String email, String password) async {
    registeredEmail = email;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    resetEmail = email;
  }

  @override
  Future<FirebaseAccountSession> signIn(String email, String password) async {
    if (deny) throw ArgumentError('Invalid cloud credentials');
    return const FirebaseAccountSession(
      uid: 'uid-tenant',
      role: AppRole.tenant,
      tenantId: 'tenant-123',
    );
  }

  @override
  Future<void> signOut() async {
    signedOut++;
  }

  @override
  Future<void> changePassword(String current, String password) async {}
}

class _RestoringGateway extends _Gateway
    implements AccountSessionRestoreGateway {
  FirebaseAccountSession? restoredSession;

  @override
  Future<FirebaseAccountSession?> restoreSession() async => restoredSession;
}

void main() {
  test('Profiles cannot choose their role or bypass disabled provisioning', () {
    expect(
      () => FirebaseAccountSession.fromProfile('u', null),
      throwsArgumentError,
    );
    expect(
      () => FirebaseAccountSession.fromProfile('u', {'role': 'admin'}),
      throwsArgumentError,
    );
    expect(
      () => FirebaseAccountSession.fromProfile('u', {
        'role': 'tenant',
        'disabled': false,
      }),
      throwsArgumentError,
    );
    expect(
      () => FirebaseAccountSession.fromProfile('u', {
        'role': 'tenant',
        'disabled': true,
        'tenantId': 't',
      }),
      throwsArgumentError,
    );
    final profile = FirebaseAccountSession.fromProfile('u', {
      'role': 'tenant',
      'disabled': false,
      'tenantId': 't',
    });
    expect(profile.role, AppRole.tenant);
  });
  test('Cloud failures never fall back to offline demo credentials', () async {
    final auth = LocalAuth();
    final gateway = _Gateway()..deny = true;
    auth.configureFirebase(
      gateway: gateway,
      onSignedIn: (_) async {
        fail('Must not open private data');
      },
      onSignedOut: () async {},
    );
    await expectLater(
      auth.signIn('landlord@tro.local', 'Tro@2026'),
      throwsArgumentError,
    );
    expect(auth.role, isNull);
    expect(auth.session, isNull);
    expect(auth.toMap(), isEmpty);
    auth.dispose();
  });
  test(
    'Private data opens before role is visible, closes before next login',
    () async {
      final auth = LocalAuth();
      final gateway = _Gateway();
      var open = false;
      auth.configureFirebase(
        gateway: gateway,
        onSignedIn: (session) async {
          expect(auth.role, isNull);
          expect(session.uid, 'uid-tenant');
          open = true;
        },
        onSignedOut: () async {
          open = false;
        },
      );
      await auth.signIn('tenant@example.com', 'Secret123');
      expect(auth.role, AppRole.tenant);
      expect(open, isTrue);
      expect(auth.toMap(), isEmpty);
      final closing = auth.signOut();
      expect(auth.role, isNull);
      await closing;
      expect(open, isFalse);
      expect(gateway.signedOut, 1);
      auth.dispose();
    },
  );

  test('Restores a cloud session before exposing its role', () async {
    final auth = LocalAuth();
    final gateway = _RestoringGateway()
      ..restoredSession = const FirebaseAccountSession(
        uid: 'uid-tenant',
        role: AppRole.tenant,
        tenantId: 'tenant-123',
      );
    var privateDataOpen = false;
    auth.configureFirebase(
      gateway: gateway,
      onSignedIn: (session) async {
        expect(auth.role, isNull);
        expect(session.uid, 'uid-tenant');
        privateDataOpen = true;
      },
      onSignedOut: () async {
        privateDataOpen = false;
      },
    );

    expect(await auth.restoreCloudSession(), isTrue);
    expect(auth.role, AppRole.tenant);
    expect(auth.session?.tenantId, 'tenant-123');
    expect(privateDataOpen, isTrue);
    await auth.signOut();
    expect(privateDataOpen, isFalse);
    auth.dispose();
  });
}
