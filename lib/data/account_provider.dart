import 'firebase_account_gateway.dart';
import '../layouts/role_layout.dart';

class AccountSignInCancelled implements Exception {
  const AccountSignInCancelled();
}

class ProviderAccountIdentity {
  const ProviderAccountIdentity({
    this.email = '',
    this.displayName = '',
    this.phoneNumber = '',
  });
  final String email;
  final String displayName;
  final String phoneNumber;
}

/// A challenge sends no credentials to the app until the user confirms the code.
class PhoneCodeChallenge {
  const PhoneCodeChallenge({
    required this.confirm,
    this.resendToken,
    this.automaticallyVerified = false,
  });
  final Future<FirebaseAccountSession?> Function(String code) confirm;
  final int? resendToken;
  final bool automaticallyVerified;
}

abstract interface class AccountProviderGateway {
  ProviderAccountIdentity? get pendingIdentity;
  Future<FirebaseAccountSession?> signInWithGoogle();
  Future<PhoneCodeChallenge> requestPhoneCode(
    String phoneNumber, {
    int? resendToken,
    bool linkToCurrentUser = false,
  });
  Future<FirebaseAccountSession> completeProviderRegistration({
    required String displayName,
    required String phoneNumber,
    required AppRole requestedRole,
  });
}

class TenantAccountContact {
  const TenantAccountContact({required this.name, required this.phoneNumber});

  final String name;
  final String phoneNumber;
}

abstract interface class TenantAccountLookupGateway {
  Future<TenantAccountContact?> lookupTenantContact(String tenantId);
  Future<bool> tenantCodeExists(String tenantId);
}
