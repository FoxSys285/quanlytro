import 'package:flutter/material.dart';

import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';
import '../models/tenant_announcement.dart';

IconData tenantAnnouncementIcon(String category) => switch (category) {
  'Điện nước' => Icons.electrical_services_outlined,
  'Thanh toán' || 'Tài chính & Hóa đơn' => Icons.receipt_long_outlined,
  'Báo cáo sự cố' => Icons.handyman_outlined,
  'Lịch xem phòng' => Icons.event_outlined,
  'Hợp đồng' => Icons.description_outlined,
  'Cập nhật hệ thống' => Icons.settings_outlined,
  _ => Icons.campaign_outlined,
};

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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TenantSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TenantDetailIcon(
                    tenantAnnouncementIcon(announcement.category),
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: TextStyle(
                            color: tenantInk,
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatTenantAnnouncementDate(
                            announcement.publishedAt,
                          ),
                          style: const TextStyle(
                            color: tenantMuted,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead) ...[
                    const SizedBox(width: 9),
                    Semantics(
                      label: 'Chưa đọc',
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 7),
                        decoration: const BoxDecoration(
                          color: tenantGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TenantStatusPill(
                    announcement.category,
                    color: tenantGreenDark,
                  ),
                  if (announcement.isImportant)
                    const TenantStatusPill(
                      'Quan trọng',
                      color: Color(0xFFD64545),
                      icon: Icons.priority_high_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: tenantMuted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const TenantThinDivider(),
              Row(
                children: [
                  const Icon(Icons.home_outlined, color: tenantMuted, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      announcement.recipient,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: tenantMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      color: tenantGreenDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: tenantGreenDark,
                    size: 18,
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
