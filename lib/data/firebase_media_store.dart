import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseMediaStore {
  FirebaseMediaStore({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final _downloadUrls = <String, String>{};

  Future<Map<String, Map<String, dynamic>>> prepareForCloud(
    Map<String, Map<String, dynamic>> snapshot, {
    bool uploadPropertyMedia = true,
  }) async {
    final prepared = _copy(snapshot);
    final stores = prepared['portfolio']?['properties'] as List? ?? [];
    for (final rawStore in stores) {
      final store = Map<String, dynamic>.from(rawStore as Map);
      final propertyId = (store['property'] as Map)['id'] as String;
      final property = Map<String, dynamic>.from(store['property'] as Map);
      final propertyBytes = property['imageBytes'];
      if (uploadPropertyMedia &&
          propertyBytes is List &&
          propertyBytes.isNotEmpty) {
        property['imageUrl'] = await uploadImage(
          List<int>.from(propertyBytes),
          'properties/${_segment(propertyId)}/cover',
        );
        property['imageBytes'] = null;
      }
      store['property'] = property;

      final roomTypes = (store['roomTypes'] as List? ?? [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      for (final type in roomTypes) {
        if (!uploadPropertyMedia) continue;
        final photos = (type['photos'] as List? ?? [])
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        for (final photo in photos) {
          final encoded = photo['bytes'];
          if (encoded is! String || encoded.isEmpty) continue;
          final bytes = base64Decode(encoded);
          photo['url'] = await uploadImage(
            bytes,
            'properties/${_segment(propertyId)}/room-types/${_segment(type['id'] as String)}',
          );
          photo
            ..remove('bytes')
            ..['assetPath'] = '';
        }
        type['photos'] = photos;
      }
      store['roomTypes'] = roomTypes;

      final payments = (store['payments'] as List? ?? [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      for (final payment in payments) {
        final proof = payment['proofBytes'];
        if (proof is! List || proof.isEmpty) continue;
        final invoiceId = payment['invoiceId'] as String?;
        final paymentId = payment['id'] as String?;
        if (invoiceId == null ||
            invoiceId.isEmpty ||
            paymentId == null ||
            paymentId.isEmpty) {
          throw ArgumentError('Chứng từ thanh toán thiếu mã hóa đơn hoặc khoản thu.');
        }
        payment['proofUrl'] = await uploadImage(
          List<int>.from(proof),
          'payment-proofs/${_segment(propertyId)}/${_segment(invoiceId)}/'
              '${_segment(paymentId)}',
        );
        payment['proofBytes'] = null;
      }
      store['payments'] = payments;
      rawStore
        ..clear()
        ..addAll(store);
    }
    return prepared;
  }

  Future<String> uploadImage(List<int> bytes, String folder) async {
    if (bytes.isEmpty) throw ArgumentError('Ảnh tải lên đang trống.');
    if (bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Mỗi ảnh cần có dung lượng tối đa 10 MB.');
    }
    final content = Uint8List.fromList(bytes);
    final contentType = _contentType(content);
    if (!contentType.startsWith('image/')) {
      throw ArgumentError('Chỉ chấp nhận tệp ảnh JPG, PNG, WebP hoặc GIF.');
    }
    final hash = sha256.convert(content).toString();
    final key = '$folder/$hash';
    final cached = _downloadUrls[key];
    if (cached != null) return cached;
    try {
      final reference = _storage.ref(key);
      try {
        final existingUrl = await reference.getDownloadURL();
        _downloadUrls[key] = existingUrl;
        return existingUrl;
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
      await reference.putData(
        content,
        SettableMetadata(contentType: contentType),
      );
      final url = await reference.getDownloadURL();
      _downloadUrls[key] = url;
      return url;
    } on FirebaseException catch (error) {
      throw StateError('Không tải được ảnh lên Firebase Storage: ${error.code}.');
    }
  }

  static String _contentType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 6 &&
        (String.fromCharCodes(bytes.take(6)) == 'GIF87a' ||
            String.fromCharCodes(bytes.take(6)) == 'GIF89a')) {
      return 'image/gif';
    }
    return 'application/octet-stream';
  }

  static String _segment(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  static Map<String, Map<String, dynamic>> _copy(
    Map<String, Map<String, dynamic>> value,
  ) => {
    for (final entry in value.entries)
      entry.key: Map<String, dynamic>.from(_copyValue(entry.value) as Map),
  };

  static Object? _copyValue(Object? value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key.toString(): _copyValue(entry.value),
      };
    }
    if (value is List) return value.map(_copyValue).toList();
    return value;
  }
}
