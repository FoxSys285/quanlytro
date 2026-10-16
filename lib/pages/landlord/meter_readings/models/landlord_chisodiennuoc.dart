/// Model quản lý chỉ số điện nước theo từng phòng phía chủ trọ
class LandlordMeterReading {
  // Hàm khởi tạo chỉ số điện nước
  LandlordMeterReading({
    required this.room,
    required this.oldElectric,
    required this.oldWater,
    required this.period,
    this.newElectric,
    this.newWater,
  });

  // Tên phòng (ví dụ: 101, 202)
  final String room;

  // Kỳ ghi chỉ số (tháng/năm)
  final DateTime period;

  // Chỉ số điện cũ (đầu kỳ)
  final int oldElectric;

  // Chỉ số nước cũ (đầu kỳ)
  final int oldWater;

  // Chỉ số điện mới (cuối kỳ, có thể null nếu chưa ghi)
  int? newElectric;

  // Chỉ số nước mới (cuối kỳ, có thể null nếu chưa ghi)
  int? newWater;

  // Kiểm tra xem phòng này đã được ghi xong cả điện lẫn nước hay chưa
  bool get isDone {
    if (newElectric != null && newWater != null) {
      return true;
    } else {
      return false;
    }
  }

  // Tính số lượng điện đã tiêu thụ trong kỳ (mới - cũ)
  int get electricUsage {
    if (newElectric != null) {
      return newElectric! - oldElectric;
    } else {
      return 0;
    }
  }

  // Tính số khối nước đã tiêu thụ trong kỳ (mới - cũ)
  int get waterUsage {
    if (newWater != null) {
      return newWater! - oldWater;
    } else {
      return 0;
    }
  }
}

// Biệt danh tiếng Việt dễ nhớ
typedef LandlordChiSoDienNuocModel = LandlordMeterReading;

