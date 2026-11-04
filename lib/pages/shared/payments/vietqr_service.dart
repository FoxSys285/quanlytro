import 'dart:convert';

import 'package:http/http.dart' as http;

class VietQrException implements Exception {
  const VietQrException(this.message);
  final String message;
  @override
  String toString() => message;
}

class VietQrImage {
  const VietQrImage({required this.uri, required this.svg});
  final Uri uri;
  final String svg;
}

/// Resolves an exact bank identity before requesting a VietQR Quick Link SVG.
/// No account-owner lookup or payment confirmation is performed here.
class VietQrService {
  VietQrService({this.client});
  static final instance = VietQrService();
  final http.Client? client;
  List<Map<String, dynamic>>? _banks;
  DateTime? _loadedAt;
  Future<List<Map<String, dynamic>>>? _pendingBanks;

  Future<http.Response> _get(Uri uri) =>
      (client?.get(uri) ?? http.get(uri)).timeout(const Duration(seconds: 12));

  Future<List<Map<String, dynamic>>> _loadBanks() async {
    if (_banks != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(days: 1)) {
      return _banks!;
    }
    if (_pendingBanks != null) return _pendingBanks!;
    final request = _fetchBanks();
    _pendingBanks = request;
    try {
      return await request;
    } finally {
      _pendingBanks = null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBanks() async {
    final response = await _get(Uri.https('api.vietqr.io', '/v2/banks'));
    if (response.statusCode != 200) {
      throw const VietQrException('Chưa tải được danh sách ngân hàng.');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map || json['code'] != '00' || json['data'] is! List) {
      throw const VietQrException('Danh sách ngân hàng không hợp lệ.');
    }
    final banks = (json['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((bank) => RegExp(r'^\d{6}$').hasMatch('${bank['bin']}'))
        .toList();
    if (banks.isEmpty) {
      throw const VietQrException('Chưa có ngân hàng hỗ trợ tạo QR.');
    }
    _banks = banks;
    _loadedAt = DateTime.now();
    return banks;
  }

  Future<Uri> paymentUri({
    required String bankName,
    required String accountNumber,
    String reference = '',
    int? amount,
  }) async {
    final account = accountNumber.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^[a-zA-Z0-9]{1,19}$').hasMatch(account)) {
      throw const VietQrException('Số tài khoản chưa hợp lệ để tạo QR.');
    }
    final name = _normalize(bankName);
    if (name.isEmpty) {
      throw const VietQrException('Chủ trọ chưa cung cấp tên ngân hàng.');
    }
    if (amount != null && (amount <= 0 || amount > 9999999999999)) {
      throw const VietQrException('Số tiền tạo QR không hợp lệ.');
    }
    final matches = (await _loadBanks()).where((bank) {
      return ['bin', 'code', 'shortName', 'short_name', 'name'].any(
        (key) => bank[key] is String && _normalize(bank[key] as String) == name,
      );
    }).toList();
    if (matches.length != 1) {
      throw const VietQrException(
        'Chưa nhận diện được ngân hàng. Vui lòng nhờ chủ trọ kiểm tra tên ngân hàng.',
      );
    }
    final description = _ascii(reference)
        .replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return Uri.https(
      'img.vietqr.io',
      '/image/${matches.single['bin']}-$account-qr_only.svg',
      {
        if (amount != null) 'amount': '$amount',
        if (description.isNotEmpty)
          'addInfo': description.length > 50
              ? description.substring(0, 50).trimRight()
              : description,
      },
    );
  }

  Future<VietQrImage> load({
    required String bankName,
    required String accountNumber,
    String reference = '',
    int? amount,
  }) async {
    try {
      final uri = await paymentUri(
        bankName: bankName,
        accountNumber: accountNumber,
        reference: reference,
        amount: amount,
      );
      final response = await _get(uri);
      final svg = utf8.decode(response.bodyBytes);
      if (response.statusCode != 200 || !svg.contains('<svg')) {
        throw const VietQrException('Chưa tải được mã QR thanh toán.');
      }
      return VietQrImage(uri: uri, svg: svg);
    } on VietQrException {
      rethrow;
    } catch (_) {
      throw const VietQrException(
        'Không kết nối được VietQR. Bạn có thể sao chép số tài khoản để chuyển khoản.',
      );
    }
  }

  static String _normalize(String input) =>
      _ascii(input)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .replaceFirst(RegExp(r'^nganhang(tmcp)?'), '');

  static String _ascii(String input) {
    const groups = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    var result = input;
    for (final entry in groups.entries) {
      result = result
          .replaceAll(RegExp('[${entry.value}]'), entry.key)
          .replaceAll(
            RegExp('[${entry.value.toUpperCase()}]'),
            entry.key.toUpperCase(),
          );
    }
    return result;
  }
}
