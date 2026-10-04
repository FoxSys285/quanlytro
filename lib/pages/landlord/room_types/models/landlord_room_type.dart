class LandlordRoomType {
  const LandlordRoomType({
    required this.id,
    required this.name,
    required this.monthlyRent,
  });
  final String id;
  final String name;
  final int monthlyRent;
}

String formatRoomTypePrice(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} đ/tháng';
