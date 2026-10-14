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

String formatTenantAnnouncementDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
    ' · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
