import 'dart:typed_data';

class RoomTypeImage {
  const RoomTypeImage({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

class LandlordRoomType {
  const LandlordRoomType({
    required this.id,
    required this.name,
    required this.monthlyRent,
    this.images = const [],
  });
  final String id;
  final String name;
  final int monthlyRent;
  final List<RoomTypeImage> images;
}

String formatRoomTypePrice(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} đ/tháng';
