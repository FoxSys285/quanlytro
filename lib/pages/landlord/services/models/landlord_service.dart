class LandlordService {
  LandlordService({
    required this.name,
    required this.unit,
    required this.basis,
    required this.price,
    this.active = true,
  });

  String name;
  String unit;

  /// Cách tính: Theo chỉ số / Theo phòng / Theo người / Cố định.
  String basis;
  int price;
  bool active;
}
