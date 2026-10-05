class TenantAnnouncement {
  const TenantAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.recipient,
    required this.publishedAt,
    this.isImportant = false,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final String recipient;
  final DateTime publishedAt;
  final bool isImportant;
  final bool isRead;
}

class TenantAnnouncementDemoData {
  static const propertyName = 'Mây House';
  static const sender = 'Chủ trọ · Nguyễn Văn An';

  static final List<TenantAnnouncement> announcements = List.unmodifiable([
    TenantAnnouncement(
      id: 'power',
      title: 'Tạm ngừng cấp điện để bảo trì',
      category: 'Điện nước',
      recipient: 'Tất cả các phòng',
      publishedAt: DateTime(2026, 10, 5, 8, 30),
      isImportant: true,
      content:
          'Nhà trọ sẽ tạm ngừng cấp điện từ 09:00 đến 11:00 ngày 06/10/2026 '
          'để kiểm tra hệ thống điện.\n\n'
          'Mọi người vui lòng sạc các thiết bị cần thiết trước thời gian bảo trì '
          'và tắt thiết bị điện khi ra khỏi phòng. Chủ trọ sẽ thông báo khi có điện trở lại.',
    ),
    TenantAnnouncement(
      id: 'rent',
      title: 'Nhắc thanh toán tiền phòng tháng 10',
      category: 'Thanh toán',
      recipient: 'Phòng A.302',
      publishedAt: DateTime(2026, 10, 4, 19),
      content:
          'Hóa đơn tháng 10 của phòng A.302 đã được cập nhật. '
          'Vui lòng kiểm tra các khoản trong mục Hóa đơn và thanh toán trước ngày 10/10/2026.\n\n'
          'Khi chuyển khoản, ghi rõ nội dung: A.302 - tiền phòng tháng 10. '
          'Nếu thông tin hóa đơn chưa đúng, hãy nhắn cho chủ trọ để được kiểm tra.',
    ),
    TenantAnnouncement(
      id: 'meters',
      title: 'Kiểm tra chỉ số điện nước tháng này',
      category: 'Điện nước',
      recipient: 'Phòng A.302',
      publishedAt: DateTime(2026, 10, 3, 9),
      isRead: true,
      content:
          'Chủ trọ sẽ kiểm tra chỉ số điện nước vào lúc 18:00 ngày 07/10/2026. '
          'Vui lòng sắp xếp một người có mặt tại phòng.\n\n'
          'Nếu không có người ở nhà, hãy liên hệ trước để thống nhất thời gian khác.',
    ),
    TenantAnnouncement(
      id: 'cleaning',
      title: 'Giữ vệ sinh khu vực sinh hoạt chung',
      category: 'Sinh hoạt',
      recipient: 'Tất cả các phòng',
      publishedAt: DateTime(2026, 10, 2, 17, 30),
      isRead: true,
      content:
          'Mọi người vui lòng để rác đúng nơi quy định, không để đồ cá nhân '
          'ở hành lang và dọn sạch khu vực giặt sau khi sử dụng.\n\n'
          'Khu vực chung sẽ được tổng vệ sinh lúc 08:00 ngày 10/10/2026. '
          'Cảm ơn mọi người đã cùng giữ nhà trọ sạch sẽ.',
    ),
  ]);
}

String formatTenantAnnouncementDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
    ' · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
