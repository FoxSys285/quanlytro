import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../landlord/announcements/models/landlord_announcement.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../shared/announcements/announcement_store.dart';
import '../../shared/profile/account_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../announcements/tenant_announcements_page.dart';
import '../../shared/settings/account_settings_page.dart';
import '../incidents/tenant_baosuco_page.dart';
import '../invoices/tenant_invoices_page.dart';
import '../tenant_ui.dart';
import 'components/tenant_lease_member_row.dart';
import '../members/components/tenant_member_requests.dart';

class TenantHomePage extends StatelessWidget {
  const TenantHomePage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
    this.title = 'Chỗ ở của tôi',
  });
  final LandlordDemoStore? store;
  final String tenantId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    final notifications = AnnouncementStore.forRental(data);
    return ListenableBuilder(
      listenable: Listenable.merge([
        data,
        notifications,
        AccountStore.instance,
      ]),
      builder: (context, _) {
        final lease = data.currentLeaseForTenant(tenantId);
        final members = lease == null
            ? const []
            : data.membersForLease(lease.id);
        var profileName = AccountStore.instance.profile(AppRole.tenant).name;
        for (final member in members) {
          if (member.tenantId == tenantId) {
            profileName = member.name;
            break;
          }
        }
        final latestNotifications = notifications.forTenant(tenantId)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: TenantPageFrame(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              _heroHeader(context, profileName),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _overviewStats(),
                    const SizedBox(height: 17),
                    if (lease == null)
                      const TenantEmptyState(
                        icon: Icons.home_outlined,
                        title: 'Chưa có hợp đồng đang hiệu lực',
                        subtitle: 'Thông tin chỗ ở sẽ xuất hiện khi chủ trọ kích hoạt hợp đồng.',
                      )
                    else
                      _currentStayCard(context, data, lease),
                    const SizedBox(height: 23),
                    _membersSection(data, lease),
                    const SizedBox(height: 23),
                    _notificationsSection(
                      context,
                      notifications,
                      latestNotifications.take(5).toList(),
                    ),
                    const SizedBox(height: 18),
                    _verifiedBanner(context),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroHeader(BuildContext context, String profileName) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 246,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/tenant_discovery_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xF2F7FFF9),
                  Color(0xC7EAF8EE),
                  Color(0x52CDE9D8),
                ],
              ),
            ),
          ),
          Positioned(
            top: topInset + 12,
            left: 18,
            right: 18,
            child: Row(
              children: [
                TenantProfileAvatar(name: profileName, radius: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF2E5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: tenantGreen,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Người thuê',
                              style: TextStyle(
                                color: tenantGreenDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          backgroundColor: tenantCanvas,
                          appBar: AppBar(title: const Text('Cài đặt')),
                          body: const AccountSettingsPage(role: AppRole.tenant),
                        ),
                      ),
                    ),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.settings_rounded,
                        color: tenantInk,
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: topInset + 104,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102B1B),
                    fontSize: 31,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quản lý thông tin phòng trọ, hợp đồng\nvà các dịch vụ liên quan',
                  maxLines: 2,
                  style: TextStyle(
                    color: Color(0xFF263A2F),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: tenantGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewStats() {
    const stats = [
      (Icons.home_rounded, '1', 'Phòng đang ở'),
      (Icons.description_rounded, '1', 'Hợp đồng'),
      (Icons.receipt_long_rounded, '2', 'Hóa đơn chưa TT'),
      (Icons.notifications_rounded, '0', 'Thông báo mới'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12101824),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0) Container(width: 1, height: 58, color: tenantLine),
            Expanded(
              child: Column(
                children: [
                  Icon(stats[index].$1, color: tenantGreen, size: 23),
                  const SizedBox(height: 4),
                  Text(
                    stats[index].$2,
                    style: const TextStyle(
                      color: tenantInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      stats[index].$3,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF394153),
                        fontSize: 9,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _currentStayCard(
    BuildContext context,
    LandlordDemoStore data,
    LandlordLease lease,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF32AE7F), Color(0xFF69C875), Color(0xFFB5E68B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A078843),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x55045F36),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text(
                        'Phòng hiện tại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Phòng ${lease.room}, ${data.property.name}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.property.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/room_types/interior.webp',
                  width: 112,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 112,
                    height: 90,
                    child: ColoredBox(
                      color: Color(0xFFE9F1EA),
                      child: Icon(Icons.home_work_rounded),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _stayAction(
                  icon: Icons.description_rounded,
                  label: 'Xem hợp đồng',
                  onPressed: () => _showContractDetails(context, data, lease),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _stayAction(
                  icon: Icons.credit_card_rounded,
                  label: 'Thanh toán',
                  onPressed: () => _openPage(
                    context,
                    'Thanh toán',
                    TenantInvoicesPage(store: data, tenantId: tenantId),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _stayAction(
                  icon: Icons.build_rounded,
                  label: 'Báo sự cố',
                  onPressed: () => _openPage(
                    context,
                    'Báo sự cố',
                    TenantBaoSuCoPage(store: data, tenantId: tenantId),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stayAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 14),
    label: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: tenantGreenDark,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      minimumSize: const Size(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
  );

  Widget _membersSection(LandlordDemoStore data, LandlordLease? lease) {
    final members = lease == null ? const [] : data.membersForLease(lease.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TenantSectionHeading(
          'Danh sách thành viên',
          trailing: TenantStatusPill(
            '${members.length} thành viên',
            color: tenantGreen,
          ),
        ),
        TenantSurface(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Column(
            children: [
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Chưa có thành viên trong phòng.',
                    style: TextStyle(color: tenantMuted, fontSize: 12),
                  ),
                ),
              for (final member in members)
                TenantLeaseMemberRow(
                  initials: _memberInitials(member.name),
                  name: member.name,
                  detail:
                      '${member.tenantId == tenantId ? 'Bạn · ' : ''}${member.isRepresentative ? 'Người đại diện' : 'Thành viên'}',
                  color: member.isRepresentative
                      ? tenantGreen
                      : const Color(0xFF7181C1),
                ),
              if (lease != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 6),
                  child: TenantMemberRequests(store: data, tenantId: tenantId),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notificationsSection(
    BuildContext context,
    AnnouncementStore notifications,
    List<LandlordAnnouncement> items,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TenantSectionHeading(
        'Thông báo',
        trailing: TextButton.icon(
          onPressed: () => _openNotifications(context, notifications),
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('Xem tất cả'),
          style: TextButton.styleFrom(
            foregroundColor: tenantGreenDark,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          ),
        ),
      ),
      if (items.isEmpty)
        const TenantSurface(
          child: Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: tenantGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chưa có thông báo mới.',
                  style: TextStyle(color: tenantMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        )
      else
        for (var index = 0; index < items.length; index++)
          _notificationRow(
            context,
            notifications,
            items[index],
            isLast: index == items.length - 1,
          ),
    ],
  );

  Widget _notificationRow(
    BuildContext context,
    AnnouncementStore notifications,
    LandlordAnnouncement item, {
    required bool isLast,
  }) {
    final icon = switch (item.category) {
      AnnouncementCategory.finance => Icons.receipt_long_rounded,
      AnnouncementCategory.incident => Icons.warning_amber_rounded,
      AnnouncementCategory.viewing => Icons.calendar_month_rounded,
      AnnouncementCategory.lease => Icons.description_rounded,
      _ => Icons.campaign_rounded,
    };
    final color = item.priority == AnnouncementPriority.urgent
        ? const Color(0xFFE79A11)
        : item.category == AnnouncementCategory.incident
        ? const Color(0xFFE79A11)
        : item.category == AnnouncementCategory.finance
        ? const Color(0xFF078843)
        : const Color(0xFF1688CC);
    final unread = !notifications.isRead(item.id, tenantId);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 26,
                    bottom: 0,
                    left: 20,
                    child: Container(width: 1, color: tenantLine),
                  ),
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showNotification(context, notifications, item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tenantInk,
                                fontSize: 12,
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.category.label} · ${announcementTimeLabel(item.createdAt, DateTime.now())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: tenantMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      if (unread)
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFFE83D3D),
                        )
                      else
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: tenantMuted,
                          size: 19,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotification(
    BuildContext context,
    AnnouncementStore notifications,
    LandlordAnnouncement item,
  ) {
    if (!notifications.isRead(item.id, tenantId)) {
      notifications.markTenantRead(item.id, tenantId);
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          item.title,
          style: const TextStyle(
            color: tenantInk,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.category.label} · ${announcementTimeLabel(item.createdAt, DateTime.now())}',
                  style: const TextStyle(color: tenantMuted, fontSize: 11),
                ),
                const SizedBox(height: 13),
                Text(
                  item.content,
                  style: const TextStyle(
                    color: tenantInk,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _openNotifications(
    BuildContext context,
    AnnouncementStore notifications,
  ) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: tenantCanvas,
          appBar: AppBar(title: const Text('Thông báo')),
          body: TenantAnnouncementsPage(
            store: notifications,
            tenantId: tenantId,
          ),
        ),
      ),
    );
  }

  Widget _verifiedBanner(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFDDF3E5),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_user_rounded, color: tenantGreen, size: 36),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An tâm hơn với nhà trọ được xác minh',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF0A3D27),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Thông tin rõ ràng, chủ trọ uy tín',
                style: TextStyle(color: Color(0xFF52685C), fontSize: 10),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tìm hiểu thêm',
          onPressed: () => showTenantPreviewNotice(context),
          icon: const Icon(Icons.arrow_forward_rounded, color: tenantGreenDark),
        ),
      ],
    ),
  );

  String _memberInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final parts = words.toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _openPage(BuildContext context, String title, Widget page) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: page,
          ),
        ),
      );

  void _showContractDetails(
    BuildContext context,
    LandlordDemoStore data,
    LandlordLease lease,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListenableBuilder(
        listenable: data,
        builder: (context, _) => TenantBottomSheetSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TenantSheetHandle(),
              Text(
                '${lease.id} · Phòng ${lease.room}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              TenantSurface(
                child: Column(
                  children: [
                    TenantDataRow(label: 'Chủ trọ', value: lease.landlordName),
                    TenantDataRow(
                      label: 'Địa chỉ bên A',
                      value: lease.landlordPermanentAddress,
                    ),
                    TenantDataRow(
                      label: 'CCCD bên A',
                      value: lease.landlordCitizenId,
                    ),
                    TenantDataRow(
                      label: 'Điện thoại/Zalo',
                      value: lease.landlordContact,
                    ),
                    const TenantThinDivider(),
                    TenantDataRow(
                      label: 'Người đại diện thuê',
                      value: lease.tenantName,
                    ),
                    TenantDataRow(
                      label: 'Năm sinh',
                      value: lease.tenantBirthYear,
                    ),
                    TenantDataRow(
                      label: 'CCCD bên B',
                      value: lease.tenantCitizenId,
                    ),
                    TenantDataRow(
                      label: 'Ngày cấp',
                      value: lease.tenantCitizenIssueDate == null
                          ? '—'
                          : landlordDate(lease.tenantCitizenIssueDate!),
                    ),
                    TenantDataRow(
                      label: 'Thường trú bên B',
                      value: lease.tenantPermanentAddress,
                    ),
                    TenantDataRow(
                      label: 'Điện thoại bên B',
                      value: lease.phone,
                    ),
                    const TenantThinDivider(),
                    TenantDataRow(
                      label: 'Thời hạn',
                      value:
                          '${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
                    ),
                    TenantDataRow(
                      label: 'Số tháng thuê',
                      value: '${lease.termMonths} tháng',
                    ),
                    TenantDataRow(
                      label: 'Tiền thuê',
                      value: '${formatTenantMoney(lease.monthlyRent)}/tháng',
                    ),
                    TenantDataRow(
                      label: 'Tiền đặt cọc',
                      value: formatTenantMoney(lease.deposit),
                    ),
                    TenantDataRow(
                      label: 'Ngày thanh toán',
                      value: 'Ngày ${lease.dueDay} hằng tháng',
                    ),
                    TenantDataRow(
                      label: 'Giá điện',
                      value: '${formatTenantMoney(lease.electricityPrice)}/kWh',
                    ),
                    TenantDataRow(
                      label: 'Giá nước',
                      value:
                          '${formatTenantMoney(lease.waterPrice)}/${lease.waterType == 'Theo tháng' ? 'tháng' : 'm³'}',
                    ),
                    TenantDataRow(
                      label: 'Tiền xe',
                      value: formatTenantMoney(lease.vehicleFee),
                    ),
                    TenantDataRow(
                      label: 'Tiền dịch vụ',
                      value: formatTenantMoney(lease.serviceFee),
                    ),
                    TenantDataRow(
                      label: 'Số người ở',
                      value:
                          '${data.membersForLease(lease.id).length} / ${data.roomByCode(lease.room)?.capacity ?? '—'} người',
                    ),
                    if (lease.cashPaymentEnabled)
                      TenantDataRow(
                        label: 'Tiền mặt',
                        value: lease.cashPaymentLocation,
                      ),
                    if (lease.bankTransferEnabled) ...[
                      TenantDataRow(
                        label: 'Ngân hàng trong hợp đồng',
                        value: lease.bankName,
                      ),
                      TenantDataRow(
                        label: 'Tài khoản trong hợp đồng',
                        value: lease.bankAccountNumber,
                      ),
                    ],
                    TenantDataRow(
                      label: 'Ghi chú',
                      value: lease.note.isEmpty ? '—' : lease.note,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
