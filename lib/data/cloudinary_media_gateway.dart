import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Client bridge to authenticated integration endpoints that sign Cloudinary
/// uploads and authorize short-lived downloads for private assets.
class CloudinaryMediaGateway {
  Future<String> upload({
    required List<int> bytes,
    required String assetPath,
    required String resourceType,
    required String deliveryType,
    required String fileName,
    required String format,
    bool overwrite = false,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase chưa được khởi tạo để tải ảnh lên Cloudinary.',
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        'Phiên đăng nhập Firebase đã hết hạn. Hãy đăng nhập lại rồi thử lưu ảnh.',
      );
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError(
        'Không lấy được mã xác thực Firebase. Hãy đăng nhập lại rồi thử lưu ảnh.',
      );
    }
    final signedResponse = await http
        .post(
          _integrationUri('cloudinaryUploadSignature'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (_supabasePublishableKey.isNotEmpty)
              'apikey': _supabasePublishableKey,
          },
          body: jsonEncode({
            'assetPath': assetPath,
            'resourceType': resourceType,
            'deliveryType': deliveryType,
            'format': format,
            'overwrite': overwrite,
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (signedResponse.statusCode != 200) {
      var detail = '';
      try {
        final body = jsonDecode(signedResponse.body) as Map<String, dynamic>;
        detail = body['error'] as String? ?? '';
      } catch (_) {
        // Keep the status code below when the Worker response is not JSON.
      }
      throw StateError(
        'Supabase không cấp được chữ ký tải Cloudinary '
        '(${signedResponse.statusCode})${detail.isEmpty ? '.' : ': $detail.'}',
      );
    }

    final signed = jsonDecode(signedResponse.body) as Map<String, dynamic>;
    final cloudName = signed['cloudName'] as String?;
    final publicId = signed['publicId'] as String?;
    final apiKey = signed['apiKey'] as String?;
    final signature = signed['signature'] as String?;
    if (cloudName == null ||
        publicId == null ||
        apiKey == null ||
        signature == null) {
      throw StateError('Cloudinary trả về chữ ký không hợp lệ.');
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.https(
              'api.cloudinary.com',
              '/v1_1/$cloudName/$resourceType/upload',
            ),
          )
          ..fields['api_key'] = apiKey
          ..fields['timestamp'] = '${signed['timestamp']}'
          ..fields['signature'] = signature
          ..fields['public_id'] = publicId
          ..fields['type'] = deliveryType;
    if (overwrite) request.fields['overwrite'] = 'true';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 90)),
    );
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = result['error'] is Map
          ? (result['error'] as Map)['message']
          : response.statusCode;
      throw StateError('Cloudinary từ chối tài nguyên: $message.');
    }
    if (deliveryType == 'authenticated') {
      final uploadedPublicId = result['public_id'] as String? ?? publicId;
      final uploadedFormat = result['format'] as String? ?? format;
      return privateReference(resourceType, uploadedPublicId, uploadedFormat);
    }
    final url = result['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Cloudinary không trả về secure URL.');
    }
    return url;
  }

  Future<Uint8List> downloadPrivateAsset(
    String assetReference, {
    int maxBytes = 10 * 1024 * 1024,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Đăng nhập lại để xem tài liệu riêng tư.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không còn hợp lệ.');
    }
    final response = await http
        .post(
          _integrationUri('cloudinaryPrivateDownloadUrl'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            if (_supabasePublishableKey.isNotEmpty)
              'apikey': _supabasePublishableKey,
          },
          body: jsonEncode({'assetRef': assetReference}),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      var detail = '';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        detail = body['error'] as String? ?? '';
      } catch (_) {
        // Keep the status code below when the function response is not JSON.
      }
      throw StateError(
        'Supabase không cấp được URL tài liệu riêng tư '
        '(${response.statusCode})${detail.isEmpty ? '.' : ': $detail.'}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Thiếu đường dẫn tài liệu.');
    }
    final file = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 40));
    if (file.statusCode != 200) {
      throw StateError('Cloudinary không trả về tài liệu riêng tư.');
    }
    if (file.bodyBytes.length > maxBytes) {
      throw StateError('Tài liệu vượt quá giới hạn kích thước.');
    }
    return Uint8List.fromList(file.bodyBytes);
  }

  static String privateReference(
    String resourceType,
    String publicId,
    String format,
  ) =>
      'cloudinary://$resourceType/authenticated/'
      '${base64Url.encode(utf8.encode(publicId)).replaceAll('=', '')}'
      '?format=${Uri.encodeComponent(format)}';

  static const _configuredBackendUrl = String.fromEnvironment(
    'TROPREMIUM_INTEGRATIONS_BACKEND_URL',
    defaultValue: 'https://hihsjrdzbtfldlscigzi.supabase.co/functions/v1',
  );
  static const _supabasePublishableKey = String.fromEnvironment(
    'TROPREMIUM_SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_2oautia3Tc3XUFP1VGlVQw__uNfvWGC',
  );

  /// Requests a Cloudinary-generated, device-sized variant for public images.
  /// Other image hosts are returned unchanged.
  static String optimizedImageUrl(String url, {int width = 800}) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.toLowerCase() != 'res.cloudinary.com') {
      return url;
    }
    const marker = '/image/upload/';
    final markerIndex = uri.path.indexOf(marker);
    if (markerIndex < 0) return url;
    final insertionIndex = markerIndex + marker.length;
    final pathAfterUpload = uri.path.substring(insertionIndex);
    if (pathAfterUpload.startsWith('f_auto,q_auto,')) return url;
    final safeWidth = width.clamp(120, 2400);
    return uri
        .replace(
          path:
              '${uri.path.substring(0, insertionIndex)}'
              'f_auto,q_auto,c_limit,w_$safeWidth/$pathAfterUpload',
        )
        .toString();
  }

  static Uri _integrationUri(String name) {
    final configuredBase = _configuredBackendUrl.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    if (configuredBase.isEmpty) {
      throw StateError(
        'Chưa cấu hình URL Supabase Edge Functions cho Cloudinary.',
      );
    }
    final endpoint = switch (name) {
      'cloudinaryUploadSignature' => 'cloudinary-upload-signature',
      'cloudinaryPrivateDownloadUrl' => 'cloudinary-private-download-url',
      _ => throw ArgumentError.value(
        name,
        'name',
        'Endpoint không được hỗ trợ.',
      ),
    };
    return Uri.parse('$configuredBase/$endpoint');
  }
}
