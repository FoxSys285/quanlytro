import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import 'property_image_picker.dart';

Future<List<SelectedPropertyImage>> pickPropertyVerificationImages() async {
  final files = await ImagePicker().pickMultiImage(
    maxWidth: 1920,
    maxHeight: 1440,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (files.length > 8) {
    throw const FormatException('Mỗi mục hồ sơ chọn tối đa 8 ảnh.');
  }
  final selected = <SelectedPropertyImage>[];
  for (final file in files) {
    if (await file.length() > 10 * 1024 * 1024) {
      throw const FormatException('Mỗi ảnh minh chứng tối đa 10 MB.');
    }
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    codec.dispose();
    selected.add(SelectedPropertyImage(bytes: bytes, name: file.name));
  }
  return selected;
}
