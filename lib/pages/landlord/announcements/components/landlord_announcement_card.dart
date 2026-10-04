import 'package:flutter/material.dart';

import '../models/landlord_announcement.dart';

IconData announcementIcon(AnnouncementCategory category) => switch (category) {
  AnnouncementCategory.finance => Icons.payments_outlined,
  AnnouncementCategory.incident => Icons.build_outlined,
  AnnouncementCategory.viewing => Icons.calendar_month_outlined,
  AnnouncementCategory.lease => Icons.description_outlined,
  AnnouncementCategory.system => Icons.settings_outlined,
  AnnouncementCategory.operations => Icons.campaign_outlined,
};

class LandlordAnnouncementCard extends StatelessWidget {
  const LandlordAnnouncementCard({
    super.key,
    required this.announcement,
    required this.propertyName,
    required this.now,
    required this.onTap,
    this.isSent = false,
  });
  final LandlordAnnouncement announcement;
  final String propertyName;
  final DateTime now;
  final VoidCallback onTap;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    final unread = !isSent && !announcement.isRead;
    final priority = announcement.priority;
    final priorityColor = priority == AnnouncementPriority.urgent
        ? const Color(0xFFBC3434)
        : const Color(0xFF946000);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: unread ? const Color(0xFFCAD9F5) : const Color(0xFFE7ECEF),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  announcementIcon(announcement.category),
                  color: const Color(0xFF3769D6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          propertyName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          announcement.category.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Text(
                          announcementTimeLabel(announcement.createdAt, now),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        if (priority != AnnouncementPriority.normal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priority.label,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (isSent)
                          Text(
                            'Gửi thử · ${announcement.recipients.length} phòng',
                            style: const TextStyle(
                              color: Color(0xFF16836F),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 5),
                  child: Semantics(
                    label: 'Chưa đọc',
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
