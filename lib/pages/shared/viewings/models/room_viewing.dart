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
    this.roomId,
    this.createdAt,
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
  final String? roomId;
  final DateTime? createdAt;

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
    roomId: roomId,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'propertyId': propertyId,
    'tenantId': tenantId,
    'roomName': roomName,
    'address': address,
    'startsAt': startsAt.toIso8601String(),
    'customerName': customerName,
    'phone': phone,
    'personalNeeds': personalNeeds,
    'status': status.name,
    'attendeeCount': attendeeCount,
    'roomId': roomId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory RoomViewing.fromMap(Map<String, dynamic> map) => RoomViewing(
    id: map['id'] as String,
    propertyId: map['propertyId'] as String,
    tenantId: map['tenantId'] as String,
    roomName: map['roomName'] as String,
    address: map['address'] as String,
    startsAt: DateTime.parse(map['startsAt'] as String),
    customerName: map['customerName'] as String,
    phone: map['phone'] as String,
    personalNeeds: map['personalNeeds'] as String,
    status: ViewingStatus.values.byName(map['status'] as String),
    attendeeCount: map['attendeeCount'] as int?,
    roomId: map['roomId'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.parse(map['createdAt'] as String),
  );
}
