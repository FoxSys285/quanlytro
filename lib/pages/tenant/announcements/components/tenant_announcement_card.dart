import 'package:flutter/material.dart';

import '../../tenant_ui.dart';
import '../models/tenant_announcement.dart';

class TenantAnnouncementCard extends StatelessWidget {
  const TenantAnnouncementCard({
    super.key,
    required this.announcement,
    required this.isRead,
    required this.onTap,
  });

  final TenantAnnouncement announcement;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (announcement.category) {
      'Điện nước' => Icons.electrical_services_outlined,
      'Thanh toán' => Icons.payments_outlined,
      _ => Icons.campaign_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: tenantLine),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tenantGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: tenantGreen, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: TextStyle(
                          color: tenantInk,
                          fontSize: 15,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 10),
                      Semantics(
                        label: 'Chưa đọc',
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD64545),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TenantStatusPill(announcement.category, color: tenantGreen),
                    if (announcement.isImportant)
                      const TenantStatusPill(
                        'Quan trọng',
                        color: Color(0xFFD64545),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  announcement.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: tenantMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const Divider(height: 24, color: tenantLine),
                Text(
                  announcement.recipient,
                  style: const TextStyle(
                    color: tenantInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatTenantAnnouncementDate(announcement.publishedAt),
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        color: tenantGreenDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: tenantGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
