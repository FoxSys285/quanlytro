import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/layouts/role_layout.dart';

void main() {
  test(
    'Local sessions survive reopening and end only after sign out',
    () async {
      final firstRun = LocalAuth();
      addTearDown(firstRun.dispose);
      await firstRun.initialize();
      await firstRun.signIn('landlord@tro.local', 'Tro@2026');

      final saved = firstRun.toMap();
      final nextRun = LocalAuth();
      addTearDown(nextRun.dispose);
      await nextRun.initialize(saved);
      expect(nextRun.role, AppRole.landlord);

      await nextRun.signOut();
      final afterSignOut = LocalAuth();
      addTearDown(afterSignOut.dispose);
      await afterSignOut.initialize(nextRun.toMap());
      expect(afterSignOut.role, isNull);
    },
  );

  test('Local role accounts reject invalid passwords and persist changed credentials', () async {
    final auth = LocalAuth();
    addTearDown(auth.dispose);
    await auth.initialize();
    await expectLater(
      auth.signIn('landlord@tro.local', 'wrong'),
      throwsArgumentError,
    );
    expect(auth.role, isNull);
    await auth.signIn(' LANDLORD@tro.local ', 'Tro@2026');
    expect(auth.role, AppRole.landlord);
    await expectLater(
      auth.changePassword('wrong', 'MatKhau@2027'),
      throwsArgumentError,
    );
    await auth.changePassword('Tro@2026', 'MatKhau@2027');
    final saved = auth.toMap();
    expect(saved.toString(), isNot(contains('Tro@2026')));
    expect(saved.toString(), isNot(contains('MatKhau@2027')));
    auth.signOut();
    expect(auth.role, isNull);
    final restored = LocalAuth();
    addTearDown(restored.dispose);
    await restored.initialize(saved);
    await expectLater(
      restored.signIn('landlord@tro.local', 'Tro@2026'),
      throwsArgumentError,
    );
    await restored.signIn('landlord@tro.local', 'MatKhau@2027');
    expect(restored.role, AppRole.landlord);
  });

  test(
    'Only admin can disable accounts and disabled state survives reopening',
    () async {
      final auth = LocalAuth();
      addTearDown(auth.dispose);
      await auth.initialize();
      await auth.signIn('landlord@tro.local', 'Tro@2026');
      expect(() => auth.setDisabled(AppRole.tenant, true), throwsArgumentError);
      auth.signOut();
      await auth.signIn('admin@tro.local', 'Tro@2026');
      expect(() => auth.setDisabled(AppRole.admin, true), throwsArgumentError);
      auth.setDisabled(AppRole.tenant, true);
      final restored = LocalAuth();
      addTearDown(restored.dispose);
      await restored.initialize(auth.toMap());
      await expectLater(
        restored.signIn('tenant@tro.local', 'Tro@2026'),
        throwsArgumentError,
      );
      expect(restored.role, isNull);
    },
  );
}
