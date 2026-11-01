import '../../../shared/media/room_photo.dart';

class LandlordRoomType {
  const LandlordRoomType({
    required this.id,
    required this.name,
    required this.monthlyRent,
    this.photos = const [],
  });
  final String id;
  final String name;
  final int monthlyRent;
  final List<RoomPhoto> photos;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'monthlyRent': monthlyRent,
    'photos': photos.map((photo) => photo.toMap()).toList(),
  };

  factory LandlordRoomType.fromMap(Map<String, dynamic> map) =>
      LandlordRoomType(
        id: map['id'] as String,
        name: map['name'] as String,
        monthlyRent: map['monthlyRent'] as int,
        photos: map.containsKey('photos')
            ? List.unmodifiable(
                (map['photos'] as List).map(
                  (photo) => RoomPhoto.fromMap(
                    Map<String, dynamic>.from(photo as Map),
                  ),
                ),
              )
            : RoomPhoto.demoForType(map['id'] as String),
      );
}

String formatRoomTypePrice(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} đ/tháng';
