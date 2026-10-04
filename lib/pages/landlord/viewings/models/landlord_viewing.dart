enum ViewingStatus {
  pending('Chờ xác nhận'),
  confirmed('Đã xác nhận');

  const ViewingStatus(this.label);
  final String label;
}

class LandlordViewing {
  const LandlordViewing({
    required this.id,
    required this.roomName,
    required this.address,
    required this.startsAt,
    required this.customerName,
    required this.phone,
    required this.personalNeeds,
    required this.status,
  });

  final String id;
  final String roomName;
  final String address;
  final DateTime startsAt;
  final String customerName;
  final String phone;
  final String personalNeeds;
  final ViewingStatus status;
}
