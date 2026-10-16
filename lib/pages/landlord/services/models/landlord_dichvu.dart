/// Model quản lý thông tin dịch vụ và bảng giá phía chủ trọ
class LandlordService {
  // Hàm khởi tạo dịch vụ
  LandlordService({
    required this.name,
    required this.unit,
    required this.basis,
    required this.price,
    this.id = '',
    this.active = true,
  });

  // Tên dịch vụ (ví dụ: Điện, Nước, Internet, Vệ sinh)
  String name;

  // Mã định danh duy nhất của dịch vụ
  final String id;

  // Đơn vị tính (ví dụ: kWh, m3, tháng, người)
  String unit;

  /// Cách tính: Theo chỉ số / Theo phòng / Theo người / Cố định
  String basis;

  // Đơn giá dịch vụ (VNĐ)
  int price;

  // Trạng thái kích hoạt (true: đang áp dụng, false: tạm dừng)
  bool active;
}

// Biệt danh tiếng Việt dễ nhớ
typedef LandlordDichVu = LandlordService;

