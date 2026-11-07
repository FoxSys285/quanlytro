class LandlordPlan {
  const LandlordPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.maxProperties,
    required this.maxRoomsPerProperty,
    required this.description,
  });

  final String id;
  final String name;
  final int monthlyPrice;
  final int maxProperties;
  final int maxRoomsPerProperty;
  final String description;

  String get monthlyPriceLabel => '${_formatVnd(monthlyPrice)} đ/tháng';

  String get propertyLimitLabel => 'Tối đa $maxProperties nhà trọ';
  String get roomLimitLabel => 'Tối đa $maxRoomsPerProperty phòng mỗi nhà';

  static const all = <LandlordPlan>[
    LandlordPlan(
      id: 'free',
      name: 'Free',
      monthlyPrice: 0,
      maxProperties: 1,
      maxRoomsPerProperty: 10,
      description: 'Bắt đầu quản lý nhà trọ của bạn.',
    ),
    LandlordPlan(
      id: 'go',
      name: 'Go',
      monthlyPrice: 39000,
      maxProperties: 2,
      maxRoomsPerProperty: 30,
      description: 'Phù hợp khi bạn mở rộng thêm một cơ sở.',
    ),
    LandlordPlan(
      id: 'plus',
      name: 'Plus',
      monthlyPrice: 99000,
      maxProperties: 4,
      maxRoomsPerProperty: 80,
      description: 'Quản lý danh mục nhà trọ đang phát triển.',
    ),
    LandlordPlan(
      id: 'ultra',
      name: 'Ultra',
      monthlyPrice: 199000,
      maxProperties: 10,
      maxRoomsPerProperty: 100,
      description: 'Dành cho hệ thống nhiều cơ sở và phòng.',
    ),
  ];

  static LandlordPlan byId(String? id) =>
      all.firstWhere((plan) => plan.id == id, orElse: () => all.first);
}

String _formatVnd(int value) {
  final digits = value.toString();
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) grouped.write('.');
    grouped.write(digits[index]);
  }
  return grouped.toString();
}
