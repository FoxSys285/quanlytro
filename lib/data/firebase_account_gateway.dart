import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../layouts/role_layout.dart';
import 'auth_validation.dart';
import 'account_provider.dart';

const _tenantCodeAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String _generateTenantCode() {
  final random = Random.secure();
  return List.generate(
    8,
    (_) => _tenantCodeAlphabet[random.nextInt(_tenantCodeAlphabet.length)],
  ).join();
}

class FirebaseAccountSession {
  const FirebaseAccountSession({
    required this.uid,
    required this.role,
    this.tenantId,
    this.email = '',
    this.displayName = '',
    this.phoneNumber = '',
    this.phoneIsSynthetic = false,
  });

  final String uid;
  final AppRole role;
  final String? tenantId;
  final String email;
  final String displayName;
  final String phoneNumber;
  final bool phoneIsSynthetic;

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
      phoneNumber: profile['phoneNumber'] as String? ?? '',
      phoneIsSynthetic: profile['phoneIsSynthetic'] == true,
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

abstract interface class AccountSessionRestoreGateway {
  Future<FirebaseAccountSession?> restoreSession();
}

abstract interface class AccountRegistrationGateway {
  Future<FirebaseAccountSession> registerAccount(
    String email,
    String password, {
    required String displayName,
    required AppRole requestedRole,
    required String phoneNumber,
  });
}

/// Firebase authentication with role-limited, Rules-validated self-registration.
class FirebaseAccountGateway
    implements
        AccountGateway,
        AccountSessionRestoreGateway,
        AccountRegistrationGateway,
        AccountProviderGateway,
        TenantAccountLookupGateway {
  FirebaseAccountGateway({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Future<void>? _googleInitialization;

  @override
  Future<void> register(String email, String password) async {
    throw ArgumentError(
      'Vui lòng đăng ký bằng biểu mẫu có họ tên và số điện thoại.',
    );
  }

  @override
  Future<FirebaseAccountSession> registerAccount(
    String email,
    String password, {
    required String displayName,
    required AppRole requestedRole,
    required String phoneNumber,
  }) async {
    if (_auth.currentUser != null) {
      throw ArgumentError('Vui lòng đăng xuất trước khi tạo tài khoản mới.');
    }
    final phoneError = validateAccountPhone(phoneNumber);
    if (phoneError != null) throw ArgumentError(phoneError);
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
      final profile = await _saveProfileIfMissing(
        uid: user.uid,
        email: user.email ?? email,
        displayName: name,
        role: requestedRole,
        phoneNumber: normalizeVietnamesePhone(phoneNumber),
      );
      final session = FirebaseAccountSession.fromProfile(
        user.uid,
        profile,
        authEmail: user.email ?? email,
      );
      await _syncTenantContact(session);
      return session;
    } on FirebaseAuthException catch (error) {
      throw ArgumentError(_message(error.code));
    } on FirebaseException catch (error) {
      await _auth.signOut();
      throw ArgumentError(
        'Đã tạo tài khoản nhưng chưa lưu được hồ sơ. Kiểm tra Firestore Rules rồi thử đăng nhập lại. ($error)',
      );
    } catch (error) {
      await _auth.signOut();
      throw _friendlyError(error);
    }
  }

  Map<String, dynamic> _newProfile({
    required String email,
    required String displayName,
    required AppRole role,
    String phoneNumber = '',
    String? tenantId,
    bool phoneVerified = false,
  }) => {
    'email': email,
    'displayName': displayName,
    'role': role.name,
    'disabled': false,
    if (phoneNumber.isNotEmpty) ...{
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'phoneIsSynthetic': false,
    },
    if (role == AppRole.tenant) 'tenantId': tenantId,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// Saves a new profile atomically with a unique tenant-code reservation.
  /// Retrying the transaction handles the very unlikely case of a collision.
  Future<Map<String, dynamic>> _saveProfileIfMissing({
    required String uid,
    required String email,
    required String displayName,
    required AppRole role,
    String phoneNumber = '',
    bool phoneVerified = false,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    if (role != AppRole.tenant) {
      return _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(userRef);
        if (existing.exists) return existing.data()!;
        final profile = _newProfile(
          email: email,
          displayName: displayName,
          role: role,
          phoneNumber: phoneNumber,
          phoneVerified: phoneVerified,
        );
        transaction.set(userRef, profile);
        return profile;
      });
    }

    for (var attempt = 0; attempt < 20; attempt++) {
      final tenantId = _generateTenantCode();
      final codeRef = _firestore.collection('tenant_codes').doc(tenantId);
      final saved = await _firestore.runTransaction<Map<String, dynamic>?>((
        transaction,
      ) async {
        final existingProfile = await transaction.get(userRef);
        if (existingProfile.exists) return existingProfile.data()!;
        final existingCode = await transaction.get(codeRef);
        if (existingCode.exists) return null;
        final profile = _newProfile(
          email: email,
          displayName: displayName,
          role: role,
          phoneNumber: phoneNumber,
          tenantId: tenantId,
          phoneVerified: phoneVerified,
        );
        transaction.set(codeRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.set(userRef, profile);
        return profile;
      });
      if (saved != null) return saved;
    }
    throw ArgumentError('Chưa thể tạo mã người thuê. Vui lòng thử lại.');
  }

  @override
  Future<TenantAccountContact?> lookupTenantContact(String tenantId) async {
    final code = tenantId.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) return null;
    final snapshot = await _firestore
        .collection('tenant_contacts')
        .doc(code)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data == null) return null;
    return TenantAccountContact(
      name: data['displayName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
    );
  }

  @override
  Future<bool> tenantCodeExists(String tenantId) async {
    final code = tenantId.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) return false;
    final snapshot = await _firestore
        .collection('tenant_codes')
        .doc(code)
        .get(const GetOptions(source: Source.server));
    return snapshot.exists;
  }

  Future<void> _syncTenantContact(FirebaseAccountSession session) async {
    final tenantId = session.tenantId;
    if (session.role != AppRole.tenant || tenantId == null) return;
    try {
      await _firestore.collection('tenant_contacts').doc(tenantId).set({
        'displayName': session.displayName,
        'phoneNumber': session.phoneNumber,
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      // Profile sync must remain available even before contact lookup rules are
      // deployed; the next sign-in can retry this noncritical directory entry.
      debugPrint('Tenant contact sync warning: $error');
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
      return (await _sessionForUser(user))!;
    } catch (error) {
      await _auth.signOut();
      throw _friendlyError(error);
    }
  }

  @override
  Future<FirebaseAccountSession?> restoreSession() async {
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    try {
      return await _sessionForUser(user, syncTenantContact: false);
    } catch (error) {
      await _auth.signOut();
      throw _friendlyError(error);
    }
  }

  Future<FirebaseAccountSession?> _sessionForUser(
    User user, {
    bool allowNewProfile = false,
    bool syncTenantContact = true,
  }) async {
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
        profileData = await _saveProfileIfMissing(
          uid: user.uid,
          email: user.email ?? requestedEmail,
          displayName: requestDisplayName is String
              ? requestDisplayName.trim()
              : '',
          role: role,
        );
      }
    }
    if (profileData == null && allowNewProfile) return null;
    final session = FirebaseAccountSession.fromProfile(
      user.uid,
      profileData,
      authEmail: user.email ?? '',
    );
    if (syncTenantContact) await _syncTenantContact(session);
    return session;
  }

  @override
  ProviderAccountIdentity? get pendingIdentity {
    final user = _auth.currentUser;
    return user == null
        ? null
        : ProviderAccountIdentity(
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            phoneNumber: user.phoneNumber ?? '',
          );
  }

  @override
  Future<FirebaseAccountSession?> signInWithGoogle() async {
    try {
      UserCredential result;
      if (kIsWeb) {
        result = await _auth.signInWithPopup(
          GoogleAuthProvider()
            ..setCustomParameters({'prompt': 'select_account'}),
        );
      } else {
        if (![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform)) {
          throw ArgumentError(
            'Đăng nhập Google khả dụng trên Android và trình duyệt web.',
          );
        }
        try {
          await (_googleInitialization ??= GoogleSignIn.instance.initialize());
        } catch (_) {
          _googleInitialization = null;
          rethrow;
        }
        final account = await GoogleSignIn.instance.authenticate();
        final token = account.authentication.idToken;
        if (token == null) {
          throw ArgumentError(
            'Chưa lấy được xác thực Google. Vui lòng thử lại.',
          );
        }
        result = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: token),
        );
      }
      if (result.user == null) {
        throw ArgumentError('Không thể xác thực tài khoản Google.');
      }
      return await _sessionForUser(result.user!, allowNewProfile: true);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AccountSignInCancelled();
      }
      throw ArgumentError(
        'Chưa thể đăng nhập Google. Vui lòng thử lại hoặc dùng email.',
      );
    } on FirebaseAuthException catch (error) {
      if ([
        'popup-closed-by-user',
        'cancelled-popup-request',
      ].contains(error.code)) {
        throw const AccountSignInCancelled();
      }
      throw _friendlyError(error);
    } catch (error) {
      throw _friendlyError(error);
    }
  }

  @override
  Future<PhoneCodeChallenge> requestPhoneCode(
    String phoneNumber, {
    int? resendToken,
    bool linkToCurrentUser = false,
  }) async {
    final validation = validateAccountPhone(phoneNumber);
    if (validation != null) throw ArgumentError(validation);
    final phone = normalizeVietnamesePhone(phoneNumber);
    final linkingUser = linkToCurrentUser ? _auth.currentUser : null;
    if (linkToCurrentUser && linkingUser == null) {
      throw ArgumentError(
        'Vui lòng đăng nhập bằng email trước khi liên kết số điện thoại.',
      );
    }
    try {
      if (kIsWeb) {
        final confirmation = linkingUser == null
            ? await _auth.signInWithPhoneNumber(phone)
            : await linkingUser.linkWithPhoneNumber(phone);
        return PhoneCodeChallenge(
          confirm: (code) async {
            try {
              final result = await confirmation.confirm(code);
              return await _finishPhoneUser(
                result.user!,
                phone,
                linkingUser?.uid,
              );
            } catch (error) {
              throw _friendlyError(error);
            }
          },
        );
      }
      if (![
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform)) {
        throw ArgumentError(
          'Đăng nhập bằng SMS khả dụng trên Android và trình duyệt web.',
        );
      }
      final completer = Completer<PhoneCodeChallenge>();
      PhoneCodeChallenge challenge(
        String id,
        int? token, [
        PhoneAuthCredential? automatic,
      ]) => PhoneCodeChallenge(
        resendToken: token,
        automaticallyVerified: automatic != null,
        confirm: (code) async {
          try {
            if (linkingUser != null &&
                _auth.currentUser?.uid != linkingUser.uid) {
              throw ArgumentError(
                'Phiên đăng nhập đã thay đổi. Vui lòng thử lại.',
              );
            }
            final credential =
                automatic ??
                PhoneAuthProvider.credential(verificationId: id, smsCode: code);
            User? verifiedUser;
            if (linkingUser == null) {
              verifiedUser = (await _auth.signInWithCredential(credential))
                  .user;
            } else if (linkingUser.phoneNumber == null) {
              verifiedUser = (await linkingUser.linkWithCredential(credential))
                  .user;
            } else {
              await linkingUser.updatePhoneNumber(credential);
              verifiedUser = _auth.currentUser;
            }
            if (verifiedUser == null) {
              throw ArgumentError('Không thể xác thực số điện thoại.');
            }
            return await _finishPhoneUser(
              verifiedUser,
              phone,
              linkingUser?.uid,
            );
          } catch (error) {
            throw _friendlyError(error);
          }
        },
      );
      unawaited(
        _auth
            .verifyPhoneNumber(
              phoneNumber: phone,
              forceResendingToken: resendToken,
              verificationCompleted: (credential) {
                if (!completer.isCompleted) {
                  completer.complete(challenge('', null, credential));
                }
              },
              verificationFailed: (error) {
                if (!completer.isCompleted) {
                  completer.completeError(_friendlyError(error));
                }
              },
              codeSent: (id, token) {
                if (!completer.isCompleted) {
                  completer.complete(challenge(id, token));
                }
              },
              codeAutoRetrievalTimeout: (id) {
                if (!completer.isCompleted) {
                  completer.complete(challenge(id, null));
                }
              },
            )
            .catchError((Object error) {
              if (!completer.isCompleted) {
                completer.completeError(_friendlyError(error));
              }
            }),
      );
      return await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () =>
            throw ArgumentError('Gửi mã xác thực quá lâu. Vui lòng thử lại.'),
      );
    } catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<FirebaseAccountSession?> _finishPhoneUser(
    User user,
    String phone,
    String? linkingUid,
  ) async {
    if (linkingUid != null) {
      if (user.uid != linkingUid) {
        throw ArgumentError('Phiên đăng nhập đã thay đổi.');
      }
      await user.getIdToken(true);
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumber': phone,
        'phoneVerified': true,
        'phoneIsSynthetic': false,
      });
    }
    return _sessionForUser(user, allowNewProfile: linkingUid == null);
  }

  @override
  Future<FirebaseAccountSession> completeProviderRegistration({
    required String displayName,
    required String phoneNumber,
    required AppRole requestedRole,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw ArgumentError('Vui lòng đăng nhập lại.');
    final phoneError = validateAccountPhone(phoneNumber);
    if (phoneError != null) throw ArgumentError(phoneError);
    final name = displayName.trim();
    if (name.isEmpty ||
        name.length > 100 ||
        ![AppRole.landlord, AppRole.tenant].contains(requestedRole)) {
      throw ArgumentError(
        'Vui lòng nhập họ tên và chọn chủ trọ hoặc người thuê.',
      );
    }
    try {
      final saved = await _saveProfileIfMissing(
        uid: user.uid,
        email: user.email ?? '',
        displayName: name,
        role: requestedRole,
        phoneNumber: normalizeVietnamesePhone(phoneNumber),
        phoneVerified:
            user.phoneNumber == normalizeVietnamesePhone(phoneNumber),
      );
      final session = FirebaseAccountSession.fromProfile(
        user.uid,
        saved,
        authEmail: user.email ?? '',
      );
      await _syncTenantContact(session);
      return session;
    } catch (error) {
      throw _friendlyError(error);
    }
  }

  static ArgumentError _friendlyError(Object error) {
    if (error is ArgumentError) return error;
    if (error is FirebaseAuthException) {
      return ArgumentError(_message(error.code));
    }
    return ArgumentError(
      'Chưa thể xác thực tài khoản. Vui lòng kiểm tra mạng và thử lại.',
    );
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
    'operation-not-allowed' => 'Phương thức đăng nhập này chưa được bật. Vui lòng dùng email hoặc thử lại sau.',
    'invalid-phone-number' => 'Số điện thoại chưa hợp lệ.',
    'invalid-verification-code' => 'Mã OTP không đúng. Vui lòng nhập lại.',
    'session-expired' => 'Mã OTP đã hết hạn. Vui lòng gửi lại mã.',
    'quota-exceeded' =>
      'Tạm hết lượt gửi SMS. Vui lòng thử lại sau hoặc dùng email.',
    'credential-already-in-use' =>
      'Số điện thoại đã liên kết với tài khoản khác.',
    'account-exists-with-different-credential' =>
      'Email này đã có tài khoản. Hãy đăng nhập bằng phương thức đã đăng ký.',
    'invalid-app-credential' ||
    'missing-client-identifier' ||
    'app-not-authorized' => 'Chưa thể xác minh ứng dụng để gửi SMS. Vui lòng dùng email và thử lại sau.',
    'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
    'too-many-requests' => 'Đã thử quá nhiều lần. Vui lòng thử lại sau.',
    'weak-password' => 'Mật khẩu chưa đủ mạnh.',
    _ => 'Email hoặc mật khẩu không đúng, hoặc tài khoản đã bị khóa.',
  };
}
