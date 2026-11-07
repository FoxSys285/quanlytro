import '../../../shared/media/room_photo.dart';

typedef RoomTypeImage = RoomPhoto;

class LandlordRoomType {
  const LandlordRoomType({
    required this.id,
    required this.name,
    required this.monthlyRent,
    this.serviceIds = const [],
    this.servicePrices = const {},
    List<RoomPhoto> photos = const [],
    List<RoomTypeImage>? images,
  }) : photos = images ?? photos;
  final String id;
  final String name;
  final int monthlyRent;
  final List<String> serviceIds;

  /// A room type keeps its own rate for each selected service.
  final Map<String, int> servicePrices;
  final List<RoomPhoto> photos;
  List<RoomTypeImage> get images => photos;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'monthlyRent': monthlyRent,
    'serviceIds': serviceIds,
    'servicePrices': servicePrices,
    'photos': photos.map((photo) => photo.toMap()).toList(),
  };

  factory LandlordRoomType.fromMap(Map<String, dynamic> map) =>
      LandlordRoomType(
        id: map['id'] as String,
        name: map['name'] as String,
        monthlyRent: map['monthlyRent'] as int,
        serviceIds: List.unmodifiable(
          List<String>.from(
            map['serviceIds'] as List? ?? const ['electricity', 'water'],
          ),
        ),
        servicePrices: Map<String, int>.unmodifiable(
          Map<String, int>.from(map['servicePrices'] as Map? ?? const {}),
        ),
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
