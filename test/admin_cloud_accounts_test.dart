import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/admin/admin_users_page.dart';

class _Gateway extends Fake implements AccountGateway {
  AppRole role = AppRole.admin;
  @override
  Future<FirebaseAccountSession> signIn(String email, String password) async =>
      FirebaseAccountSession(uid: 'admin-a', role: role);
  @override
  Future<void> signOut() async {}
}

void main() {
  test('Cloud lock rejects self, invalid IDs and non-admin sessions', () async {
    final gateway = _Gateway();
    final auth = LocalAuth.instance;
    auth.configureFirebase(
      gateway: gateway,
      onSignedIn: (_) async {},
      onSignedOut: () async {},
    );
    await auth.signIn('admin@example.com', 'secret');
    for (final uid in ['admin-a', '', 'users/tenant-a']) {
      await expectLater(
        setAdminAccountDisabled(uid, true),
        throwsArgumentError,
      );
    }
    gateway.role = AppRole.tenant;
    await auth.signIn('tenant@example.com', 'secret');
    await expectLater(
      setAdminAccountDisabled('tenant-b', false),
      throwsArgumentError,
    );
    await auth.signOut();
  });
}
