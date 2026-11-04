import 'dart:convert';

import 'package:http/http.dart' as http;

class TenantAdministrativeUnit {
  const TenantAdministrativeUnit({required this.code, required this.name});

  final int code;
  final String name;

  factory TenantAdministrativeUnit.fromJson(dynamic json) {
    if (json is! Map ||
        json['code'] is! int ||
        json['name'] is! String ||
        (json['name'] as String).trim().isEmpty) {
      throw const FormatException('Invalid administrative unit');
    }
    return TenantAdministrativeUnit(
      code: json['code'] as int,
      name: (json['name'] as String).trim(),
    );
  }
}

class TenantAdministrativeFailure implements Exception {
  const TenantAdministrativeFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Province Open API v2 uses the two-level province/ward structure.
class TenantAdministrativeService {
  TenantAdministrativeService({this.client});

  static final instance = TenantAdministrativeService();
  final http.Client? client;
  final _cache = <String, List<TenantAdministrativeUnit>>{};
  final _loadedAt = <String, DateTime>{};
  final _pending = <String, Future<List<TenantAdministrativeUnit>>>{};

  Future<List<TenantAdministrativeUnit>> provinces() => _load('p/');

  Future<List<TenantAdministrativeUnit>> wards(int provinceCode) =>
      _load('p/$provinceCode');

  Future<List<TenantAdministrativeUnit>> _load(String path) async {
    if (_cache.containsKey(path) &&
        DateTime.now().difference(_loadedAt[path]!) < const Duration(days: 1)) {
      return _cache[path]!;
    }
    if (_pending.containsKey(path)) return _pending[path]!;
    final request = _fetch(path);
    _pending[path] = request;
    try {
      return await request;
    } finally {
      _pending.remove(path);
    }
  }

  Future<List<TenantAdministrativeUnit>> _fetch(String path) async {
    final isProvinceList = path == 'p/';
    try {
      final uri = Uri.https(
        'provinces.open-api.vn',
        '/api/v2/$path',
        isProvinceList ? null : {'depth': '2'},
      );
      final response = await (client?.get(uri) ?? http.get(uri)).timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != 200) {
        throw const FormatException('Unsuccessful response');
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic items = isProvinceList
          ? json
          : (json is Map ? json['wards'] : null);
      if (items is! List || (isProvinceList && items.isEmpty)) {
        throw const FormatException('Invalid administrative list');
      }
      final units = List<TenantAdministrativeUnit>.unmodifiable(
        items.map(TenantAdministrativeUnit.fromJson),
      );
      _cache[path] = units;
      _loadedAt[path] = DateTime.now();
      return units;
    } catch (_) {
      throw TenantAdministrativeFailure(
        isProvinceList
            ? 'Không tải được danh sách tỉnh / thành phố. Kiểm tra kết nối và thử lại.'
            : 'Không tải được danh sách xã / phường. Kiểm tra kết nối và thử lại.',
      );
    }
  }
}
