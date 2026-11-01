import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../layouts/role_layout.dart';
import 'firebase_account_gateway.dart';

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
