import 'package:flutter/material.dart';

import '../../tenant_ui.dart';
import '../models/tenant_room_member.dart';

class TenantRoomMemberCard extends StatelessWidget {
  const TenantRoomMemberCard({super.key, required this.member});
  final TenantRoomMember member;

  @override
  Widget build(BuildContext context) {
    final color = member.isRepresentative
        ? tenantGreen
        : const Color(0xFF7181C1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TenantSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    member.initials,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TenantStatusPill(
                            member.isRepresentative
                                ? 'Người đại diện'
                                : 'Thành viên',
                            color: color,
                          ),
                          if (member.isCurrentUser)
                            const TenantStatusPill('Bạn', color: tenantGreen),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28, color: tenantLine),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 19, color: tenantMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    member.phone,
                    style: const TextStyle(color: tenantInk, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  size: 19,
                  color: tenantMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ngày vào ở: ${member.joinedAt}',
                    style: const TextStyle(color: tenantMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
