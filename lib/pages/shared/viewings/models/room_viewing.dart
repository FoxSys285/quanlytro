enum ViewingStatus {
  pending('Đang chờ xác nhận'),
  confirmed('Đã xác nhận'),
  cancelled('Đã hủy');

  const ViewingStatus(this.label);
  final String label;
}

class RoomViewing {
  const RoomViewing({
    required this.id,
    required this.roomName,
    required this.address,
    required this.startsAt,
    required this.customerName,
    required this.phone,
    required this.personalNeeds,
    required this.status,
    this.propertyId = 'may',
    this.tenantId = '',
    this.attendeeCount,
  });
  final String id;
  final String propertyId;
  final String tenantId;
  final String roomName;
  final String address;
  final DateTime startsAt;
  final String customerName;
  final String phone;
  final String personalNeeds;
  final ViewingStatus status;
  final int? attendeeCount;

  RoomViewing withStatus(ViewingStatus status) => RoomViewing(
    id: id,
    propertyId: propertyId,
    tenantId: tenantId,
    roomName: roomName,
    address: address,
    startsAt: startsAt,
    customerName: customerName,
    phone: phone,
    personalNeeds: personalNeeds,
    status: status,
    attendeeCount: attendeeCount,
  );
}
