import '../../finance/landlord_finance_models.dart';
import '../../room_types/models/landlord_room_type.dart';

enum LandlordRoomStatus {
  vacant('Phòng trống'),
  occupied('Đang thuê'),
  upcoming('Sắp nhận phòng');

  const LandlordRoomStatus(this.label);
  final String label;
}

class LandlordRoom {
  const LandlordRoom({
    required this.code,
    required this.floor,
    required this.roomTypeId,
    required this.area,
    required this.capacity,
    this.leaseRoomCode,
  });
  final String code;
  final int floor;
  final String roomTypeId;
  final int area;
  final int capacity;
  // Some existing contracts include the building prefix in their room code.
  final String? leaseRoomCode;
}

class LandlordRoomDetails {
  const LandlordRoomDetails({required this.room, this.type, this.lease});
  final LandlordRoom room;
  final LandlordRoomType? type;
  final LandlordLease? lease;
  String get typeName => type?.name ?? 'Chưa gán loại phòng';
  int? get monthlyRent => lease?.monthlyRent ?? type?.monthlyRent;
  LandlordRoomStatus get status => lease == null
      ? LandlordRoomStatus.vacant
      : lease!.isCurrent
      ? LandlordRoomStatus.occupied
      : LandlordRoomStatus.upcoming;
}
