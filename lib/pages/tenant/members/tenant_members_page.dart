import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import 'components/tenant_room_member_card.dart';
import 'models/tenant_room_member.dart';

class TenantMembersPage extends StatelessWidget {
  const TenantMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const members = TenantRoomMembersDemoData.members;
    const capacity = TenantRoomMembersDemoData.capacity;
    return TenantPageFrame(
      children: [
        const TenantPageTitle(
          title: 'Thành viên phòng',
          subtitle: 'Những người đang ở cùng phòng với bạn.',
        ),
        TenantSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 30,
                    color: tenantGreen,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng ${TenantRoomMembersDemoData.roomName}',
                          style: TextStyle(
                            color: tenantInk,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${TenantRoomMembersDemoData.propertyName} · Tầng 3',
                          style: TextStyle(color: tenantMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28, color: tenantLine),
              Text(
                '${members.length} / $capacity người',
                style: const TextStyle(
                  color: tenantGreenDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: members.length / capacity,
                  minHeight: 7,
                  color: tenantGreen,
                  backgroundColor: tenantGreen.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Số người hiện tại / số người tối đa của phòng.',
                style: TextStyle(color: tenantMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const TenantSectionHeading('Danh sách thành viên'),
        for (final member in members) TenantRoomMemberCard(member: member),
      ],
    );
  }
}
