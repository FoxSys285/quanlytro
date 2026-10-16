class LandlordService {
  LandlordService({
    required this.name,
    required this.unit,
    required this.basis,
    required this.price,
    this.id = '',
    this.active = true,
  });

  String name;
  final String id;
  String unit;

  /// Cách tính: Theo chỉ số / Theo phòng / Theo người / Cố định.
  String basis;
  int price;
  bool active;
}
