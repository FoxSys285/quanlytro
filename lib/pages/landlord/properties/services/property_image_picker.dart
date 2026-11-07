import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../../../shared/media/media_permission_service.dart';

class SelectedPropertyImage {
  const SelectedPropertyImage({required this.bytes, required this.name});
  final Uint8List bytes;
  final String name;
}

Future<SelectedPropertyImage?> pickPropertyImage() async {
  if (!await MediaPermissionService.checkBeforePicker(RentalMediaKind.image)) {
    throw const FormatException(
      'Hãy cho phép truy cập ảnh trong Cài đặt để chọn hình.',
    );
  }
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1440,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (file == null) return null;
  if (await file.length() > 10 * 1024 * 1024) {
    throw const FormatException('Chọn ảnh có dung lượng tối đa 10 MB.');
  }
  final bytes = await file.readAsBytes();
  // Validate the image before replacing the currently displayed one.
  final codec = await ui.instantiateImageCodec(bytes);
  codec.dispose();
  return SelectedPropertyImage(bytes: bytes, name: file.name);
}
