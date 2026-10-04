import '../../../tenant/discovery/models/tenant_room_listing.dart';

class LandlordRoomType {
  const LandlordRoomType({
    required this.name,
    required this.description,
    this.sourceType,
    this.requiredTag,
    this.maxOccupants,
  });

  final String name;
  final String description;
  final String? sourceType;
  final String? requiredTag;
  final int? maxOccupants;

  List<TenantRoomListing> get rooms => TenantRoomDemoData.allListings
      .where(
        (room) => sourceType != null
            ? room.roomType == sourceType
            : requiredTag != null
            ? room.tags.contains(requiredTag)
            : false,
      )
      .toList();

  LandlordRoomType edited(String name, String description, int? maxOccupants) =>
      LandlordRoomType(
        name: name,
        description: description,
        sourceType: sourceType,
        requiredTag: requiredTag,
        maxOccupants: maxOccupants,
      );

  static List<LandlordRoomType> initialTypes() => [
    for (final type
        in TenantRoomDemoData.allListings.map((room) => room.roomType).toSet())
      LandlordRoomType(
        name: type,
        sourceType: type,
        description: type == 'Phòng có gác'
            ? 'Phòng có gác lửng, tách khu vực ngủ và sinh hoạt.'
            : 'Các phòng thuộc loại $type trong danh sách nhà trọ.',
      ),
    const LandlordRoomType(
      name: 'Phòng có ban công',
      requiredTag: 'Ban công',
      description: 'Phòng có ban công, không gian thoáng và đón ánh sáng.',
    ),
    const LandlordRoomType(
      name: 'Phòng lớn cho 5 người',
      maxOccupants: 5,
      description:
          'Loại phòng dành cho nhóm tối đa 5 người. Chưa có phòng được gán.',
    ),
  ];
}
