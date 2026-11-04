import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../layouts/role_layout.dart';

class FirebaseAccountSession {
  const FirebaseAccountSession({
    required this.uid,
    required this.role,
    this.tenantId,
  });

  final String uid;
  final AppRole role;
  final String? tenantId;

  factory FirebaseAccountSession.fromProfile(
    String uid,
    Map<String, dynamic>? profile,
  ) {
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

/// Authentication and server-provisioned profiles only; never grants roles.
class FirebaseAccountGateway implements AccountGateway {
  FirebaseAccountGateway({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<void> register(String email, String password) async {
    if (_auth.currentUser != null) {
      throw ArgumentError('Vui lòng đăng xuất trước khi tạo tài khoản mới.');
    }
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Creating an Auth identity never provisions a role or opens private data.
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw ArgumentError(_message(error.code));
    }
  }

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
      // A cached role is never sufficient to authorize a fresh session.
      final profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      return FirebaseAccountSession.fromProfile(user.uid, profile.data());
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
