import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../shared/rental/tenant_session.dart';
import 'components/tenant_member_requests.dart';
import '../tenant_ui.dart';
import '../tenant_feature_ui.dart';
import '../tenant_detail_ui.dart';
import 'components/tenant_room_member_card.dart';
import 'models/tenant_room_member.dart';

class TenantMembersPage extends StatelessWidget {
  const TenantMembersPage({super.key, this.store, String? tenantId})
    : _tenantId = tenantId ?? '';
  final LandlordDemoStore? store;
  final String _tenantId;
  String get tenantId =>
      _tenantId.isEmpty ? TenantSession.currentTenantId : _tenantId;
  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final lease = data.currentLeaseForTenant(tenantId);
        if (lease == null) {
          return const TenantFeatureFrame(
            artwork: TenantFeatureArtwork.members,
            title: 'Thành viên phòng',
            subtitle: 'Quản lý thông tin những người ở cùng bạn.',
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
        final room = data.roomByCode(lease.room);
        final capacity = room?.capacity ?? lease.occupantCount;
        return TenantFeatureFrame(
          artwork: TenantFeatureArtwork.members,
          title: 'Thành viên phòng',
          subtitle: 'Những người đang ở cùng phòng với bạn.',
          children: [
            TenantSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TenantDetailIcon(Icons.home_work_rounded, size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phòng ${lease.room}',
                              style: const TextStyle(
                                color: tenantInk,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data.property.name}${room == null ? '' : ' · Tầng ${room.floor}'}',
                              style: const TextStyle(
                                color: tenantMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Số người đang ở',
                          style: TextStyle(color: tenantMuted, fontSize: 12),
                        ),
                      ),
                      TenantStatusPill(
                        '${members.length} / $capacity người',
                        color: tenantGreenDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: capacity <= 0
                          ? 0
                          : (members.length / capacity).clamp(0, 1),
                      color: tenantGreen,
                      backgroundColor: const Color(0xFFEAF5EE),
                    ),
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
            const SizedBox(height: 20),
            const TenantFeatureBanner(
              icon: Icons.people_alt_rounded,
              title: 'Cùng nhau xây dựng không gian sống',
              subtitle: 'Thông tin người ở cùng được cập nhật sau khi chủ trọ duyệt yêu cầu.',
            ),
          ],
        );
      },
    );
  }
}
