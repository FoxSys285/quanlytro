import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../layouts/role_layout.dart';
import 'auth_validation.dart';
import 'firebase_account_gateway.dart';
import 'account_provider.dart';

/// Local demo accounts, or Firebase accounts when explicitly configured.
class LocalAuth extends ChangeNotifier {
  static final instance = LocalAuth();
  AccountGateway? _gateway;
  Future<void> Function(FirebaseAccountSession)? _onSignedIn;
  Future<void> Function()? _onSignedOut;
  FirebaseAccountSession? _session;
  FirebaseAccountSession? get session => _session;
  bool get isCloudMode => _gateway != null;
  Future<void> _closing = Future.value();

  Future<TenantAccountContact?> lookupTenantContact(String tenantId) async {
    final gateway = _gateway;
    if (gateway is TenantAccountLookupGateway) {
      return (gateway as TenantAccountLookupGateway).lookupTenantContact(
        tenantId,
      );
    }
    return null;
  }

  Future<bool> tenantCodeExists(String tenantId) async {
    final gateway = _gateway;
    if (gateway is TenantAccountLookupGateway) {
      return (gateway as TenantAccountLookupGateway).tenantCodeExists(tenantId);
    }
    return false;
  }

  AccountProviderGateway get _providers {
    final gateway = _gateway;
    if (gateway is AccountProviderGateway) {
      return gateway as AccountProviderGateway;
    }
    throw ArgumentError(
      'Đăng nhập Google và SMS cần kết nối Firebase. Vui lòng dùng email.',
    );
  }

  ProviderAccountIdentity? get pendingIdentity =>
      _role == null && _gateway is AccountProviderGateway
      ? (_gateway as AccountProviderGateway).pendingIdentity
      : null;

  Future<bool> _acceptProviderSession(FirebaseAccountSession? session) async {
    if (session == null) return false;
    await _onSignedIn!(session);
    _session = session;
    _role = session.role;
    notifyListeners();
    return true;
  }

  Future<bool> signInWithGoogle() async {
    await _closing;
    if (_role != null) await signOut();
    try {
      return await _acceptProviderSession(await _providers.signInWithGoogle());
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  Future<PhoneCodeChallenge> requestPhoneCode(
    String phoneNumber, {
    int? resendToken,
    bool linkToCurrentUser = false,
  }) async {
    final error = validateAccountPhone(phoneNumber);
    if (error != null) throw ArgumentError(error);
    await _closing;
    if (linkToCurrentUser && _role == null) {
      throw ArgumentError(
        'Vui lòng đăng nhập trước khi liên kết số điện thoại.',
      );
    }
    if (!linkToCurrentUser && _role != null) await signOut();
    return _providers.requestPhoneCode(
      normalizeVietnamesePhone(phoneNumber),
      resendToken: resendToken,
      linkToCurrentUser: linkToCurrentUser,
    );
  }

  Future<bool> confirmPhoneCode(
    PhoneCodeChallenge challenge,
    String code, {
    bool linkToCurrentUser = false,
  }) async {
    if (linkToCurrentUser) {
      final uid = _session?.uid;
      if (uid == null) throw ArgumentError('Vui lòng đăng nhập lại.');
      final session = await challenge.confirm(code);
      if (session == null || session.uid != uid || _session?.uid != uid) {
        throw ArgumentError('Phiên đăng nhập đã thay đổi. Vui lòng thử lại.');
      }
      _session = session;
      notifyListeners();
      return true;
    }
    try {
      return await _acceptProviderSession(await challenge.confirm(code));
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  Future<void> completeProviderRegistration({
    required String displayName,
    required String phoneNumber,
    required AppRole requestedRole,
  }) async {
    // Form/network failures preserve the pending identity for another attempt.
    final session = await _providers.completeProviderRegistration(
      displayName: displayName,
      phoneNumber: phoneNumber,
      requestedRole: requestedRole,
    );
    try {
      await _acceptProviderSession(session);
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  void configureFirebase({
    required AccountGateway gateway,
    required Future<void> Function(FirebaseAccountSession) onSignedIn,
    required Future<void> Function() onSignedOut,
  }) {
    _gateway = gateway;
    _onSignedIn = onSignedIn;
    _onSignedOut = onSignedOut;
    _role = null;
    _session = null;
    _credentials.clear();
    _disabled.clear();
  }

  final _credentials = <String, Map<String, dynamic>>{};
  final _disabled = <String>{};
  AppRole? _role;
  AppRole? get role => _role;
  bool _foreground = true;
  bool get isForeground => _foreground;
  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    notifyListeners();
  }

  // Chỉ trả thông tin quản lý, không đưa hash/salt ra giao diện.
  List<({String email, AppRole role, bool disabled})> get localAccounts => [
    for (final entry in _credentials.entries)
      (
        email: entry.key,
        role: AppRole.values.byName(entry.value['role'] as String),
        disabled: _disabled.contains(entry.key),
      ),
  ];
  static String emailFor(AppRole role) => '${role.name}@tro.local';

  Future<void> initialize([Map<String, dynamic>? saved]) async {
    if (isCloudMode) return;
    _credentials.clear();
    _disabled.clear();
    _role = null;
    if (saved != null) {
      (saved['credentials'] as Map).forEach(
        (k, v) =>
            _credentials[k as String] = Map<String, dynamic>.from(v as Map),
      );
      _disabled.addAll(List<String>.from(saved['disabled'] as List? ?? []));
      return;
    }
    for (final role in AppRole.values) {
      final salt = base64Encode(
        List.generate(24, (_) => Random.secure().nextInt(256)),
      );
      final hash = await compute(_derivePassword, ['Tro@2026', salt]);
      _credentials[emailFor(role)] = {
        'salt': salt,
        'hash': hash,
        'role': role.name,
      };
    }
  }

  Future<void> signIn(String email, String password) async {
    await _closing;
    if (_role != null) await signOut();
    final key = email.trim().toLowerCase();
    final gateway = _gateway;
    if (gateway != null) {
      try {
        final session = await gateway.signIn(key, password);
        await _onSignedIn!(session);
        _session = session;
        _role = session.role;
        notifyListeners();
        return;
      } catch (error) {
        try {
          await _onSignedOut!();
        } finally {
          await gateway.signOut();
          _session = null;
          _role = null;
        }
        if (error is ArgumentError) rethrow;
        throw ArgumentError(
          'Không thể mở dữ liệu tài khoản. Vui lòng thử lại.',
        );
      }
    }
    final account = _credentials[key];
    if (account == null || _disabled.contains(key)) {
      throw ArgumentError(
        'Tài khoản hoặc mật khẩu không đúng, hoặc tài khoản đã bị khóa.',
      );
    }
    final actual = await compute(_derivePassword, [
      password,
      account['salt'] as String,
    ]);
    final expected = account['hash'] as String;
    var different = actual.length ^ expected.length;
    for (var i = 0; i < actual.length && i < expected.length; i++) {
      different |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    if (different != 0) {
      throw ArgumentError('Tài khoản hoặc mật khẩu không đúng.');
    }
    _role = AppRole.values.byName(account['role'] as String);
    notifyListeners();
  }

  Future<void> register(
    String email,
    String password, {
    String displayName = '',
    String phoneNumber = '',
    AppRole requestedRole = AppRole.tenant,
  }) async {
    final error =
        validateAccountEmail(email) ??
        validateAccountPhone(phoneNumber) ??
        validateAccountPassword(password);
    if (error != null) throw ArgumentError(error);
    await _closing;
    if (_role != null) {
      throw ArgumentError('Vui lòng đăng xuất trước khi tạo tài khoản mới.');
    }
    final gateway = _gateway;
    if (gateway == null) {
      throw ArgumentError(
        'Đăng ký qua email chưa khả dụng trong bản dùng thử. Bạn có thể dùng tài khoản mẫu hoặc liên hệ quản trị viên để được cấp tài khoản.',
      );
    }
    if (gateway is AccountRegistrationGateway) {
      final registrationGateway = gateway as AccountRegistrationGateway;
      final session = await registrationGateway.registerAccount(
        email.trim().toLowerCase(),
        password,
        displayName: displayName,
        phoneNumber: normalizeVietnamesePhone(phoneNumber),
        requestedRole: requestedRole,
      );
      try {
        await _onSignedIn!(session);
        _session = session;
        _role = session.role;
        notifyListeners();
      } catch (_) {
        try {
          await _onSignedOut!();
        } finally {
          await gateway.signOut();
          _session = null;
          _role = null;
        }
        rethrow;
      }
    } else {
      await gateway.register(email.trim().toLowerCase(), password);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    final error = validateAccountEmail(email);
    if (error != null) throw ArgumentError(error);
    final gateway = _gateway;
    if (gateway == null) {
      throw ArgumentError(
        'Bản dùng thử không gửi email khôi phục. Mật khẩu ban đầu của tài khoản mẫu là Tro@2026. Nếu đã đổi mật khẩu, vui lòng liên hệ quản trị viên.',
      );
    }
    await gateway.requestPasswordReset(email.trim().toLowerCase());
  }

  Future<void> signOut() {
    _role = null;
    _session = null;
    notifyListeners();
    if (!isCloudMode) return Future.value();
    _closing = () async {
      try {
        await _onSignedOut!();
      } finally {
        await _gateway!.signOut();
      }
    }();
    return _closing;
  }

  bool isDisabled(AppRole role) => _disabled.contains(emailFor(role));
  void setDisabled(AppRole role, bool disabled) {
    if (isCloudMode) {
      throw ArgumentError('Quản lý quyền tài khoản trong Firebase Console.');
    }
    if (_role != AppRole.admin) {
      throw ArgumentError('Chỉ quản trị viên được khóa tài khoản.');
    }
    if (role == AppRole.admin) {
      throw ArgumentError('Không thể khóa tài khoản quản trị hiện tại.');
    }
    if (disabled) {
      _disabled.add(emailFor(role));
    } else {
      _disabled.remove(emailFor(role));
    }
    notifyListeners();
  }

  Future<void> changePassword(String current, String password) async {
    final role = _role;
    if (role == null) throw ArgumentError('Vui lòng đăng nhập lại.');
    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      throw ArgumentError('Mật khẩu mới cần ít nhất 8 ký tự, gồm chữ và số.');
    }
    if (_gateway != null) {
      await _gateway!.changePassword(current, password);
      return;
    }
    final account = _credentials[emailFor(role)]!;
    final hash = await compute(_derivePassword, [
      current,
      account['salt'] as String,
    ]);
    if (hash != account['hash']) {
      throw ArgumentError('Mật khẩu hiện tại không đúng.');
    }
    final salt = base64Encode(
      List.generate(24, (_) => Random.secure().nextInt(256)),
    );
    account['salt'] = salt;
    account['hash'] = await compute(_derivePassword, [password, salt]);
    notifyListeners();
  }

  Map<String, dynamic> toMap() => isCloudMode
      ? {}
      : {'credentials': _credentials, 'disabled': _disabled.toList()};
}

// PBKDF2-HMAC-SHA256, one 256-bit block. Runs in an isolate to keep UI responsive.
String _derivePassword(List<String> values) {
  final hmac = Hmac(sha256, utf8.encode(values[0]));
  var block = hmac.convert([...base64Decode(values[1]), 0, 0, 0, 1]).bytes;
  final result = List<int>.of(block);
  for (var i = 1; i < 120000; i++) {
    block = hmac.convert(block).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= block[j];
    }
  }
  return base64Encode(result);
}
