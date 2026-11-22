import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'cloudinary_media_gateway.dart';

class FirebaseMediaStore {
  FirebaseMediaStore({
    FirebaseStorage? storage,
    CloudinaryMediaGateway? cloudinary,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _cloudinary = cloudinary ?? CloudinaryMediaGateway();

  final FirebaseStorage _storage;
  final CloudinaryMediaGateway _cloudinary;
  final _downloadUrls = <String, String>{};

  Future<Map<String, Map<String, dynamic>>> prepareForCloud(
    Map<String, Map<String, dynamic>> snapshot, {
    bool uploadPropertyMedia = true,
    bool uploadPaymentProofs = true,
    String? uploaderUid,
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
          cloudinaryOwnerUid: uploaderUid,
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
        await _runInParallelChunks(photos, (photo) async {
          final encoded = photo['bytes'];
          if (encoded is! String || encoded.isEmpty) return;
          final bytes = base64Decode(encoded);
          photo['url'] = await uploadImage(
            bytes,
            'properties/${_segment(propertyId)}/room-types/${_segment(type['id'] as String)}',
            cloudinaryOwnerUid: uploaderUid,
          );
          photo
            ..remove('bytes')
            ..['assetPath'] = '';
        });
        type['photos'] = photos;
      }
      store['roomTypes'] = roomTypes;

      final verificationDocuments =
          (property['verificationDocuments'] as List? ?? [])
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList();
      for (final document in verificationDocuments) {
        final files = (document['files'] as List? ?? [])
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        await _runInParallelChunks(files, (file) async {
          final bytes = file['bytes'];
          if (!uploadPropertyMedia || bytes is! List || bytes.isEmpty) return;
          file['storagePath'] = await uploadVerificationImage(
            List<int>.from(bytes),
            propertyId: propertyId,
            documentId: document['id'] as String,
          );
          file['bytes'] = null;
        });
        document['files'] = files;
      }
      property['verificationDocuments'] = verificationDocuments;
      store['property'] = property;

      final payments = (store['payments'] as List? ?? [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      for (final payment in payments) {
        final proof = payment['proofBytes'];
        if (!uploadPaymentProofs || proof is! List || proof.isEmpty) continue;
        final invoiceId = payment['invoiceId'] as String?;
        final paymentId = payment['id'] as String?;
        if (invoiceId == null ||
            invoiceId.isEmpty ||
            paymentId == null ||
            paymentId.isEmpty) {
          throw ArgumentError(
            'Chứng từ thanh toán thiếu mã hóa đơn hoặc khoản thu.',
          );
        }
        final proofContent = Uint8List.fromList(List<int>.from(proof));
        final proofFormat = _formatForContentType(_contentType(proofContent));
        final proofHash = sha256.convert(proofContent).toString();
        payment['proofUrl'] = await uploadPrivateImage(
          proofContent,
          storagePath:
              'payment-proofs/${_segment(propertyId)}/'
              '${_segment(invoiceId)}/${_segment(paymentId)}/$proofHash',
          fileName: '$paymentId.$proofFormat',
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

  Future<void> _runInParallelChunks<T>(
    List<T> items,
    Future<void> Function(T item) operation, {
    int chunkSize = 3,
  }) async {
    for (var start = 0; start < items.length; start += chunkSize) {
      await Future.wait(items.skip(start).take(chunkSize).map(operation));
    }
  }

  Future<String> uploadImage(
    List<int> bytes,
    String folder, {
    String? cloudinaryOwnerUid,
  }) async {
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
    final format = _formatForContentType(contentType);
    final cloudinaryUrl = await _cloudinary.upload(
      bytes: content,
      assetPath: _cloudinaryPropertyPath(folder, cloudinaryOwnerUid, hash),
      resourceType: 'image',
      deliveryType: 'upload',
      fileName: '$hash.$format',
      format: format,
    );
    _downloadUrls[key] = cloudinaryUrl;
    return cloudinaryUrl;
  }

  /// Uploads identity and ownership evidence to a private path. The caller
  /// stores the path, never a public download URL, in Firestore.
  Future<String> uploadVerificationImage(
    List<int> bytes, {
    required String propertyId,
    required String documentId,
  }) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Mỗi ảnh minh chứng cần có dung lượng tối đa 10 MB.');
    }
    final content = Uint8List.fromList(bytes);
    final contentType = _contentType(content);
    if (!contentType.startsWith('image/')) {
      throw ArgumentError('Ảnh minh chứng cần là JPG, PNG, WebP hoặc GIF.');
    }
    final hash = sha256.convert(content).toString();
    final key =
        'verification-proofs/${_segment(propertyId)}/'
        '${_segment(documentId)}/$hash';
    final format = _formatForContentType(contentType);
    return _cloudinary.upload(
      bytes: content,
      assetPath: _cloudinaryPath(key),
      resourceType: 'image',
      deliveryType: 'authenticated',
      fileName: '$hash.$format',
      format: format,
    );
  }

  Future<String> uploadPrivateImage(
    List<int> bytes, {
    required String storagePath,
    required String fileName,
    bool overwrite = false,
  }) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Mỗi ảnh riêng tư cần có dung lượng tối đa 10 MB.');
    }
    final content = Uint8List.fromList(bytes);
    final contentType = _contentType(content);
    if (!contentType.startsWith('image/')) {
      throw ArgumentError('Chỉ chấp nhận ảnh JPG, PNG, WebP hoặc GIF.');
    }
    final format = _formatForContentType(contentType);
    final cloudinaryPath = storagePath.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return _cloudinary.upload(
      bytes: content,
      assetPath: _cloudinaryPath(cloudinaryPath),
      resourceType: 'image',
      deliveryType: 'authenticated',
      fileName: fileName,
      format: format,
      overwrite: overwrite,
    );
  }

  Future<String> uploadAsset(
    List<int> bytes, {
    required String folder,
    required String fileName,
    required String resourceType,
    String contentType = 'application/octet-stream',
    bool private = false,
  }) async {
    if (bytes.isEmpty || bytes.length > 100 * 1024 * 1024) {
      throw ArgumentError('Tài nguyên cần có dung lượng từ 1 byte đến 100 MB.');
    }
    if (!['image', 'video', 'raw'].contains(resourceType)) {
      throw ArgumentError('Loại tài nguyên không được hỗ trợ.');
    }
    final safeFolder = folder
        .split('/')
        .map(_segment)
        .where((part) => part.isNotEmpty)
        .join('/');
    final extension = fileName.contains('.')
        ? _segment(fileName.split('.').last.toLowerCase())
        : '';
    if (resourceType == 'raw' && extension.isEmpty) {
      throw ArgumentError('Tài liệu cần có phần mở rộng tệp.');
    }
    final hash = sha256.convert(bytes).toString();
    final leaf = resourceType == 'raw' && extension.isNotEmpty
        ? '$hash.$extension'
        : hash;
    final assetPath = _cloudinaryPath('$safeFolder/$leaf');
    return _cloudinary.upload(
      bytes: bytes,
      assetPath: assetPath,
      resourceType: resourceType,
      deliveryType: private ? 'authenticated' : 'upload',
      fileName: fileName,
      format: extension.isNotEmpty
          ? extension
          : _formatForContentType(contentType),
    );
  }

  Future<Uint8List?> downloadPrivateAsset(
    String storagePath, {
    int maxBytes = 10 * 1024 * 1024,
  }) async {
    final cached = _privateAssetCache[storagePath];
    if (cached != null) {
      if (cached.length > maxBytes) {
        throw StateError(
          'TÃ i liá»‡u vÆ°á»£t quÃ¡ giá»›i háº¡n kÃ­ch thÆ°á»›c.',
        );
      }
      _privateAssetCache
        ..remove(storagePath)
        ..[storagePath] = cached;
      return cached;
    }
    final existing = _privateAssetDownloads[storagePath];
    if (existing != null) {
      final bytes = await existing;
      if (bytes != null && bytes.length > maxBytes) {
        throw StateError(
          'TÃ i liá»‡u vÆ°á»£t quÃ¡ giá»›i háº¡n kÃ­ch thÆ°á»›c.',
        );
      }
      return bytes;
    }
    final download = storagePath.startsWith('cloudinary://')
        ? _cloudinary.downloadPrivateAsset(storagePath, maxBytes: maxBytes)
        : _storage.ref(storagePath).getData(maxBytes);
    _privateAssetDownloads[storagePath] = download;
    try {
      final bytes = await download;
      if (bytes != null) {
        _privateAssetCache
          ..remove(storagePath)
          ..[storagePath] = bytes;
        while (_privateAssetCache.length > 12 ||
            _privateAssetCache.values.fold<int>(
                  0,
                  (sum, value) => sum + value.length,
                ) >
                32 * 1024 * 1024) {
          _privateAssetCache.remove(_privateAssetCache.keys.first);
        }
      }
      return bytes;
    } finally {
      if (identical(_privateAssetDownloads[storagePath], download)) {
        _privateAssetDownloads.remove(storagePath);
      }
    }
  }

  static final _privateAssetCache = <String, Uint8List>{};
  static final _privateAssetDownloads = <String, Future<Uint8List?>>{};

  static String _cloudinaryPath(String value) =>
      'tropremium/${value.split('/').map(_segment).where((part) => part.isNotEmpty).join('/')}';

  static String _cloudinaryPropertyPath(
    String folder,
    String? ownerUid,
    String hash,
  ) {
    final parts = folder.split('/');
    if (ownerUid == null ||
        ownerUid.isEmpty ||
        parts.length < 2 ||
        parts[0] != 'properties') {
      return _cloudinaryPath('$folder/$hash');
    }
    return _cloudinaryPath(
      'properties/${parts[1]}/${_segment(ownerUid)}/'
      '${parts.skip(2).join('/')}/$hash',
    );
  }

  static String _formatForContentType(String contentType) =>
      switch (contentType) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/gif' => 'gif',
        _ => 'bin',
      };

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
