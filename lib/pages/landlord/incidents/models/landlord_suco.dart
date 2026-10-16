import 'package:flutter/material.dart';

import '../../landlord_ui.dart';

/// Trạng thái sự cố theo nghiệp vụ quản lý phòng trọ:
/// - newly: Mới tạo
/// - inProgress: Đang xử lý
/// - resolved: Đã xử lý (chờ khách thuê xác nhận)
/// - closed: Đã đóng / hoàn tất
enum IncidentStatus { newly, inProgress, resolved, closed }

/// Tiện ích mở rộng lấy nhãn tiếng Việt và màu sắc hiển thị cho từng trạng thái
extension IncidentStatusX on IncidentStatus {
  // Lấy tên hiển thị tiếng Việt của trạng thái
  String get label {
    if (this == IncidentStatus.newly) {
      return 'Mới';
    } else if (this == IncidentStatus.inProgress) {
      return 'Đang xử lý';
    } else if (this == IncidentStatus.resolved) {
      return 'Đã xử lý';
    } else {
      return 'Đã đóng';
    }
  }

  // Lấy màu sắc đặc trưng đại diện cho trạng thái
  Color get color {
    if (this == IncidentStatus.newly) {
      return const Color(0xFFD64545); // Màu đỏ cảnh báo
    } else if (this == IncidentStatus.inProgress) {
      return const Color(0xFFE08A1E); // Màu cam đang tiến hành
    } else if (this == IncidentStatus.resolved) {
      return const Color(0xFF16836F); // Màu xanh lá hoàn thành
    } else {
      return landlordMuted; // Màu xám đã đóng
    }
  }
}

/// Model đại diện cho một sự cố / yêu cầu sửa chữa
class LandlordIncident {
  // Hàm khởi tạo thông tin sự cố
  LandlordIncident({
    required this.title,
    required this.room,
    required this.reporter,
    required this.category,
    required this.description,
    required this.date,
    required this.id,
    required this.leaseId,
    required this.reporterId,
    this.status = IncidentStatus.newly,
    this.urgent = false,
  });

  // Tiêu đề sự cố (ví dụ: Hư vòi nước, Cháy bóng đèn)
  final String title;

  // Mã định danh duy nhất của sự cố
  final String id;

  // Mã hợp đồng thuê của phòng gặp sự cố
  final String leaseId;

  // Mã người gửi báo cáo sự cố
  final String reporterId;

  // Tên phòng gặp sự cố (ví dụ: 101, 202)
  final String room;

  // Tên người báo sự cố
  final String reporter;

  // Phân loại sự cố (Điện, Nước, Điện lạnh, Internet, Khác)
  final String category;

  // Mô tả chi tiết tình trạng hư hỏng
  final String description;

  // Ngày gửi báo cáo sự cố (dd/MM/yyyy)
  final String date;

  // Cờ đánh dấu sự cố khẩn cấp
  final bool urgent;

  // Trạng thái xử lý hiện tại của sự cố
  IncidentStatus status;
}

// Biệt danh tiếng Việt dễ nhớ
typedef TrangThaiSuCo = IncidentStatus;
typedef LandlordSuCo = LandlordIncident;

