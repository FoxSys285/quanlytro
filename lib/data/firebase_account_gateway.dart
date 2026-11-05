import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../layouts/role_layout.dart';

class FirebaseAccountSession {
  const FirebaseAccountSession({
    required this.uid,
    required this.role,
    this.tenantId,
    this.email = '',
    this.displayName = '',
  });

  final String uid;
  final AppRole role;
  final String? tenantId;
  final String email;
  final String displayName;

  factory FirebaseAccountSession.fromProfile(
    String uid,
    Map<String, dynamic>? profile, {
    String authEmail = '',
  }) {
    if (profile == null || profile['disabled'] != false) {
      throw ArgumentError('Tài khoản chưa được cấp quyền hoặc đã bị khóa.');
    }
    final roles = AppRole.values.where((r) => r.name == profile['role']);
    if (roles.isEmpty) {
      throw ArgumentError('Tài khoản chưa được cấp vai trò hợp lệ.');
    }
    final tenantId = profile['tenantId'];
    if (roles.single == AppRole.tenant && tenantId == null) {
      throw ArgumentError('Tài khoản chưa được liên kết với người thuê.');
    }
    if (tenantId != null &&
        (tenantId is! String ||
            tenantId.trim().isEmpty ||
            tenantId != tenantId.trim() ||
            tenantId.contains('/') ||
            tenantId.contains(':'))) {
      throw ArgumentError('Hồ sơ người thuê chưa hợp lệ.');
    }
    return FirebaseAccountSession(
      uid: uid,
      role: roles.single,
      tenantId: tenantId as String?,
      email: profile['email'] as String? ?? authEmail,
      displayName: profile['displayName'] as String? ?? '',
    );
  }
}

abstract interface class AccountGateway {
  Future<FirebaseAccountSession> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> requestPasswordReset(String email);
  Future<void> signOut();
  Future<void> changePassword(String current, String password);
}

abstract interface class AccountRegistrationGateway {
  Future<FirebaseAccountSession> registerAccount(
    String email,
    String password, {
    required String displayName,
    required AppRole requestedRole,
  });
}

/// Firebase authentication with role-limited, Rules-validated self-registration.
class FirebaseAccountGateway
    implements AccountGateway, AccountRegistrationGateway {
  FirebaseAccountGateway({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<void> register(String email, String password) async {
    await registerAccount(
      email,
      password,
      displayName: email.split('@').first,
      requestedRole: AppRole.tenant,
    );
    await _auth.signOut();
  }

  @override
  Future<FirebaseAccountSession> registerAccount(
    String email,
    String password, {
    required String displayName,
    required AppRole requestedRole,
  }) async {
    if (_auth.currentUser != null) {
      throw ArgumentError('Vui lòng đăng xuất trước khi tạo tài khoản mới.');
    }
    if (![AppRole.landlord, AppRole.tenant].contains(requestedRole)) {
      throw ArgumentError(
        'Chỉ hỗ trợ đăng ký tài khoản chủ trọ hoặc người thuê.',
      );
    }
    final name = displayName.trim();
    if (name.isEmpty || name.length > 100) {
      throw ArgumentError('Họ tên cần từ 1 đến 100 ký tự.');
    }
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) throw ArgumentError('Không thể tạo tài khoản.');
      final profile = _newProfile(
        uid: user.uid,
        email: user.email ?? email,
        displayName: name,
        role: requestedRole,
      );
      await _firestore.collection('users').doc(user.uid).set(profile);
      return FirebaseAccountSession.fromProfile(
        user.uid,
        profile,
        authEmail: user.email ?? email,
      );
    } on FirebaseAuthException catch (error) {
      throw ArgumentError(_message(error.code));
    } on FirebaseException catch (error) {
      await _auth.signOut();
      throw ArgumentError(
        'Đã tạo tài khoản nhưng chưa lưu được hồ sơ. Kiểm tra Firestore Rules rồi thử đăng nhập lại. ($error)',
      );
    }
  }

  Map<String, dynamic> _newProfile({
    required String uid,
    required String email,
    required String displayName,
    required AppRole role,
  }) => {
    'email': email,
    'displayName': displayName,
    'role': role.name,
    'disabled': false,
    if (role == AppRole.tenant) 'tenantId': 'tenant-$uid',
    'createdAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Use the same confirmation for known and unknown addresses.
      if (error.code == 'user-not-found') return;
      throw ArgumentError(_message(error.code));
    }
  }

  @override
  Future<FirebaseAccountSession> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user == null) throw ArgumentError('Không thể xác thực tài khoản.');
      final profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      var profileData = profile.data();
      if (profileData == null) {
        // Existing signups from the former approval flow can activate their
        // own landlord/tenant profile from their immutable self-owned request.
        final legacyRequest = await _firestore
            .collection('account_requests')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
        final request = legacyRequest.data();
        final requestedRole = request?['requestedRole'];
        final requestedEmail = request?['email'];
        final requestDisplayName = request?['displayName'];
        if (request != null &&
            request['status'] == 'pending' &&
            (requestedRole == AppRole.landlord.name ||
                requestedRole == AppRole.tenant.name) &&
            requestedEmail is String &&
            requestedEmail.trim().toLowerCase() ==
                (user.email ?? '').trim().toLowerCase()) {
          final role = AppRole.values.byName(requestedRole as String);
          profileData = _newProfile(
            uid: user.uid,
            email: user.email ?? requestedEmail,
            displayName: requestDisplayName is String
                ? requestDisplayName.trim()
                : '',
            role: role,
          );
          await _firestore.collection('users').doc(user.uid).set(profileData);
        }
      }
      return FirebaseAccountSession.fromProfile(
        user.uid,
        profileData,
        authEmail: user.email ?? '',
      );
    } catch (error) {
      await _auth.signOut();
      if (error is ArgumentError) rethrow;
      if (error is FirebaseAuthException) {
        throw ArgumentError(_message(error.code));
      }
      throw ArgumentError(
        'Không thể kiểm tra quyền tài khoản. Vui lòng kiểm tra mạng và thử lại.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> changePassword(String current, String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw ArgumentError('Vui lòng đăng nhập lại.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: current),
      );
      await user.updatePassword(password);
    } on FirebaseAuthException catch (error) {
      throw ArgumentError(_message(error.code));
    }
  }

  static String _message(String code) => switch (code) {
    'email-already-in-use' =>
      'Email này đã được đăng ký. Hãy đăng nhập hoặc khôi phục mật khẩu.',
    'invalid-email' => 'Địa chỉ email chưa hợp lệ.',
    'operation-not-allowed' =>
      'Email/Password chưa được bật trên Firebase Console.',
    'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
    'too-many-requests' => 'Đã thử quá nhiều lần. Vui lòng thử lại sau.',
    'weak-password' => 'Mật khẩu chưa đủ mạnh.',
    _ => 'Email hoặc mật khẩu không đúng, hoặc tài khoản đã bị khóa.',
  };
}
