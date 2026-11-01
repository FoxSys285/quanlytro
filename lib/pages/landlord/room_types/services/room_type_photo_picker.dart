import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../../../shared/media/room_photo.dart';

typedef RoomTypePhotoPicker = Future<List<RoomPhoto>> Function(int remaining);

Future<List<RoomPhoto>> pickRoomTypePhotos(int remaining) async {
  final files = await ImagePicker().pickMultiImage(
    maxWidth: 1600,
    maxHeight: 1200,
    imageQuality: 82,
    limit: remaining,
    requestFullMetadata: false,
  );
  if (files.length > remaining) {
    throw FormatException('Bạn có thể thêm tối đa $remaining ảnh nữa.');
  }
  final photos = <RoomPhoto>[];
  for (final file in files) {
    if (await file.length() > 10 * 1024 * 1024) {
      throw const FormatException('Mỗi ảnh cần có dung lượng tối đa 10 MB.');
    }
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    codec.dispose();
    photos.add(RoomPhoto(name: file.name, bytes: bytes));
  }
  return photos;
}
