import '../models/landlord_announcement.dart';

class LandlordAnnouncementDemoData {
  static const properties = [
    AnnouncementProperty(
      id: 'may',
      name: 'Mây House',
      rooms: {'101': 1, '102': 1, '201': 2, '202': 2},
    ),
    AnnouncementProperty(
      id: 'nau',
      name: 'Nhà Nâu',
      rooms: {'101': 1, '102': 1, '201': 2},
    ),
    AnnouncementProperty(
      id: 'mai',
      name: 'Ban Mai',
      rooms: {'101': 1, '201': 2, '301': 3},
    ),
  ];

  static List<LandlordAnnouncement> inbox(DateTime now) => [
    LandlordAnnouncement(
      id: 'payment',
      propertyId: 'may',
      title: 'Phòng 102 - Đã gửi minh chứng chuyển khoản',
      content:
          'Người thuê gửi minh chứng thanh toán 3.800.000 đ. '
          'Chủ trọ cần đối chiếu giao dịch trước khi duyệt thanh toán.',
      category: AnnouncementCategory.finance,
      priority: AnnouncementPriority.high,
      createdAt: now.subtract(const Duration(minutes: 10)),
    ),
    LandlordAnnouncement(
      id: 'ac',
      propertyId: 'may',
      title: 'Phòng 201 - Báo hỏng máy lạnh',
      content:
          'Máy lạnh không làm mát và có tiếng ồn. Người thuê có mặt '
          'sau 18:00, đề nghị liên hệ để sắp xếp kiểm tra.',
      category: AnnouncementCategory.incident,
      priority: AnnouncementPriority.urgent,
      createdAt: now.subtract(const Duration(minutes: 25)),
    ),
    LandlordAnnouncement(
      id: 'debt',
      propertyId: 'nau',
      title: 'Phòng 101 - Chậm thanh toán tiền nhà',
      content:
          'Hóa đơn tháng này đã quá hạn 3 ngày, còn 3.400.000 đ '
          'chưa thanh toán. Có thể soạn thông báo nhắc riêng phòng 101.',
      category: AnnouncementCategory.finance,
      priority: AnnouncementPriority.high,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    LandlordAnnouncement(
      id: 'viewing',
      propertyId: 'mai',
      title: 'Ban Mai - Có lịch xem phòng mới',
      content:
          'Lê Thu Hà đặt lịch xem studio lúc 16:00 ngày mai. '
          'Nhu cầu: nội thất sẵn, không gian làm việc yên tĩnh.',
      category: AnnouncementCategory.viewing,
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    LandlordAnnouncement(
      id: 'water',
      propertyId: 'nau',
      title: 'Phòng 201 - Báo rỉ nước trong nhà tắm',
      content:
          'Vòi nước bị rỉ liên tục. Người thuê đề nghị kiểm tra '
          'vào buổi sáng và báo trước thời gian đến.',
      category: AnnouncementCategory.incident,
      priority: AnnouncementPriority.high,
      createdAt: DateTime(now.year, now.month, now.day - 1, 14, 30),
    ),
    LandlordAnnouncement(
      id: 'lease',
      propertyId: 'may',
      title: 'Phòng 202 - Hợp đồng sắp hết hạn',
      content:
          'Hợp đồng còn 15 ngày. Liên hệ người thuê để trao đổi '
          'gia hạn hoặc kế hoạch bàn giao phòng.',
      category: AnnouncementCategory.lease,
      isRead: true,
      createdAt: DateTime(now.year, now.month, now.day - 1, 9, 0),
    ),
    LandlordAnnouncement(
      id: 'meter',
      propertyId: 'mai',
      title: 'Ban Mai - Nhắc chốt chỉ số điện nước',
      content:
          'Đến kỳ chốt điện nước. Kiểm tra chỉ số và đơn giá '
          'trước khi lập hóa đơn cho người thuê.',
      category: AnnouncementCategory.finance,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    LandlordAnnouncement(
      id: 'maintenance',
      title: 'Hệ thống - Lịch bảo trì ứng dụng',
      content:
          'Thông báo mẫu từ ban quản trị: bảo trì dự kiến '
          'từ 01:00 đến 02:00 vào ngày mai.',
      category: AnnouncementCategory.system,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}
