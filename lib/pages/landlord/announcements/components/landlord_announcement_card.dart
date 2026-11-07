import 'package:flutter/material.dart';

import '../../landlord_theme.dart';
import '../models/landlord_announcement.dart';

IconData announcementIcon(AnnouncementCategory category) => switch (category) {
  AnnouncementCategory.finance => Icons.payments_outlined,
  AnnouncementCategory.incident => Icons.warning_amber_rounded,
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
    this.onAction,
    this.isSent = false,
  });

  final LandlordAnnouncement announcement;
  final String propertyName;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final bool isSent;

  String get _actionLabel => announcement.id.startsWith('payment:')
      ? 'Duyệt phiếu thu'
      : switch (announcement.category) {
          AnnouncementCategory.finance => 'Xem hóa đơn',
          AnnouncementCategory.incident => 'Xử lý sự cố',
          AnnouncementCategory.viewing => 'Xem lịch hẹn',
          AnnouncementCategory.lease => 'Xem hợp đồng',
          _ => 'Xem chi tiết',
        };

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final unread = !isSent && !announcement.isRead;
    final urgent = announcement.priority == AnnouncementPriority.urgent;
    final color = urgent
        ? const Color(0xFFF04457)
        : announcement.category == AnnouncementCategory.finance
        ? const Color(0xFFF0A01B)
        : const Color(0xFF2864E9);
    final room = RegExp(r'Phòng\s+([^\s-]+)')
        .firstMatch(announcement.title)
        ?.group(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: color),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 12, 11, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              announcementIcon(announcement.category),
                              color: color,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  announcement.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontSize: 12,
                                    fontWeight: unread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                if (urgent)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Khẩn cấp',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (unread)
                            Container(
                              margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${room == null ? propertyName : 'Phòng $room'} · ${announcement.category.label}  ·  ${announcementTimeLabel(announcement.createdAt, now)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Đã gửi · ${announcement.recipients.length} phòng',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10,
                          ),
                        ),
                      ] else if (onAction != null) ...[
                        const SizedBox(height: 9),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: onTap,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                ),
                              ),
                              child: const Text(
                                'Chi tiết',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 5),
                            FilledButton(
                              onPressed: onAction,
                              style: FilledButton.styleFrom(
                                backgroundColor: color,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 30),
                              ),
                              child: Text(
                                _actionLabel,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
