import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../layouts/role_layout.dart';

class DeviceLoginAccount {
  const DeviceLoginAccount({
    required this.identifier,
    required this.displayName,
    required this.role,
  });

  final String identifier;
  final String displayName;
  final AppRole role;

  Map<String, Object?> toMap() => {
    'identifier': identifier,
    'displayName': displayName,
    'role': role.name,
  };

  static DeviceLoginAccount? fromMap(Object? value) {
    if (value is! Map) return null;
    final identifier = value['identifier'];
    final displayName = value['displayName'];
    final roleName = value['role'];
    if (identifier is! String || identifier.trim().isEmpty) return null;
    final roles = AppRole.values.where((role) => role.name == roleName);
    if (roles.length != 1 || roles.single == AppRole.admin) return null;
    return DeviceLoginAccount(
      identifier: identifier.trim(),
      displayName: displayName is String ? displayName.trim() : '',
      role: roles.single,
    );
  }
}

/// Stores account identities used on this device, without saving passwords.
class DeviceLoginHistory {
  DeviceLoginHistory._();

  static const _storageKey = 'device_login_history_v1';

  static Future<List<DeviceLoginAccount>> accountsFor(AppRole role) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_storageKey);
      if (encoded == null) return const [];
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return [
        for (final value in decoded)
          if (DeviceLoginAccount.fromMap(value) case final account?)
            if (account.role == role) account,
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> remember({
    required String identifier,
    required String displayName,
    required AppRole role,
  }) async {
    final cleanIdentifier = identifier.trim();
    if (cleanIdentifier.isEmpty || role == AppRole.admin) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_storageKey);
      final accounts = <DeviceLoginAccount>[];
      if (encoded != null) {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          for (final value in decoded) {
            final account = DeviceLoginAccount.fromMap(value);
            if (account != null) accounts.add(account);
          }
        }
      }

      final normalizedIdentifier = cleanIdentifier.toLowerCase();
      accounts.removeWhere(
        (account) =>
            account.identifier.toLowerCase() == normalizedIdentifier &&
            account.role == role,
      );
      accounts.insert(
        0,
        DeviceLoginAccount(
          identifier: cleanIdentifier,
          displayName: displayName.trim(),
          role: role,
        ),
      );
      await preferences.setString(
        _storageKey,
        jsonEncode(accounts.map((account) => account.toMap()).toList()),
      );
    } catch (_) {
      // This list is a testing convenience and must not block authentication.
    }
  }
}
