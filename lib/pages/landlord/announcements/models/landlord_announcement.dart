enum AnnouncementCategory {
  finance('Tài chính & Hóa đơn'),
  incident('Báo cáo sự cố'),
  viewing('Lịch xem phòng'),
  lease('Hợp đồng'),
  system('Cập nhật hệ thống'),
  operations('Vận hành');

  const AnnouncementCategory(this.label);
  final String label;
}

enum AnnouncementPriority {
  normal('Thông thường'),
  high('Ưu tiên cao'),
  urgent('Khẩn cấp');

  const AnnouncementPriority(this.label);
  final String label;
}

class LandlordAnnouncement {
  const LandlordAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.propertyId,
    this.isRead = false,
    this.priority = AnnouncementPriority.normal,
    this.recipients = const [],
    this.audienceLabel,
  });
  final String id;
  final String title;
  final String content;
  final AnnouncementCategory category;
  final DateTime createdAt;
  final String? propertyId;
  final bool isRead;
  final AnnouncementPriority priority;
  final List<String> recipients;
  final String? audienceLabel;

  LandlordAnnouncement read() => LandlordAnnouncement(
    id: id,
    title: title,
    content: content,
    category: category,
    createdAt: createdAt,
    propertyId: propertyId,
    isRead: true,
    priority: priority,
    recipients: recipients,
    audienceLabel: audienceLabel,
  );
}

class AnnouncementProperty {
  const AnnouncementProperty({
    required this.id,
    required this.name,
    required this.rooms,
  });
  final String id;
  final String name;
  final Map<String, int> rooms; // Room code -> floor, for the sample audience.
}

String announcementTimeLabel(DateTime date, DateTime now) {
  final elapsed = now.difference(date);
  if (elapsed.inSeconds < 60) return 'Vừa xong';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} phút trước';
  final time =
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Hôm nay, $time';
  if (day == DateTime(now.year, now.month, now.day - 1)) {
    return 'Hôm qua, $time';
  }
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}, $time';
}
