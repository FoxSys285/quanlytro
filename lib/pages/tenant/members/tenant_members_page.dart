import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../shared/rental/tenant_session.dart';
import 'components/tenant_member_requests.dart';
import '../tenant_ui.dart';
import 'components/tenant_room_member_card.dart';
import 'models/tenant_room_member.dart';

class TenantMembersPage extends StatelessWidget {
  const TenantMembersPage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final LandlordDemoStore? store;
  final String tenantId;
  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final lease = data.currentLeaseForTenant(tenantId);
        if (lease == null) {
          return const TenantPageFrame(
            children: [
              TenantEmptyState(
                icon: Icons.people_outline,
                title: 'Chưa có phòng đang thuê',
                subtitle: 'Thành viên xuất hiện khi hợp đồng có hiệu lực.',
              ),
            ],
          );
        }
        final members = data.membersForLease(lease.id);
        final room = data.roomByCode(lease.room)!;
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
                  Text(
                    'Phòng ${lease.room}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('${data.property.name} · Tầng ${room.floor}'),
                  const SizedBox(height: 15),
                  Text('${members.length} / ${room.capacity} người'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (members.length / room.capacity).clamp(0, 1),
                    color: tenantGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const TenantSectionHeading('Danh sách thành viên'),
            for (final member in members)
              TenantRoomMemberCard(
                member: TenantRoomMember(
                  name: member.name,
                  initials: member.name
                      .split(' ')
                      .where((part) => part.isNotEmpty)
                      .map((part) => part[0])
                      .take(2)
                      .join(),
                  phone: member.phone,
                  joinedAt: landlordDate(member.joinedAt),
                  isRepresentative: member.isRepresentative,
                  isCurrentUser: member.tenantId == tenantId,
                ),
              ),
            TenantMemberRequests(store: data, tenantId: tenantId),
          ],
        );
      },
    );
  }
}
