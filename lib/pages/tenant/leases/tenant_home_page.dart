import '../../shared/profile/account_store.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../layouts/role_layout.dart';

import '../../landlord/finance/landlord_finance_models.dart';
import '../../landlord/announcements/models/landlord_announcement.dart';
import '../../landlord/incidents/models/landlord_suco.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../shared/announcements/announcement_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../discovery/tenant_favorites_page.dart';
import '../announcements/tenant_announcements_page.dart';
import '../incidents/tenant_baosuco_page.dart';
import '../invoices/tenant_invoices_page.dart';
import '../invoices/components/tenant_invoice_dashboard_widgets.dart';
import 'tenant_activity_badge.dart';
import 'tenant_lease_contract_page.dart';
import 'components/tenant_lease_overview.dart';
import '../tenant_ui.dart';
import '../tenant_detail_ui.dart';
import '../tenant_settings_page.dart';
import 'components/tenant_lease_member_row.dart';
import '../members/components/tenant_member_requests.dart';

class _TenantActivityItem {
  const _TenantActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.date,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.badgeForeground,
  });

  final IconData icon;
  final Color color;
  final String title;
  final DateTime date;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeForeground;
  final VoidCallback onTap;
}

class TenantHomePage extends StatelessWidget {
  const TenantHomePage({
    super.key,
    this.store,
    String? tenantId,
    this.title = 'Chỗ ở của tôi',
  }) : _tenantId = tenantId ?? '';
  final LandlordDemoStore? store;
  final String _tenantId;
  String get tenantId =>
      _tenantId.isEmpty ? TenantSession.currentTenantId : _tenantId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    final notifications = AnnouncementStore.forRental(data);
    return ListenableBuilder(
      listenable: Listenable.merge([data, notifications]),
      builder: (context, _) {
        final lease = data.currentLeaseForTenant(tenantId);
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
              _heroHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _overviewStats(data, notifications),
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
                    _activityHistorySection(context, data),
                    const SizedBox(height: 18),
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

  Widget _heroHeader(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/tenant_home_hero.png',
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
            top: 0,
            left: 0,
            right: 0,
            child: TenantHeader(
              profileName: AccountStore.instance.profile(AppRole.tenant).name,
              onAvatarTap: () => Scaffold.maybeOf(context)?.openDrawer(),
              onFavoritesTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const TenantFavoritesPage(),
                ),
              ),
              onSettingsTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const TenantSettingsPage(),
                ),
              ),
              overlay: true,
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: MediaQuery.paddingOf(context).top + 83,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102B1B),
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Qu\u1ea3n l\u00fd th\u00f4ng tin ph\u00f2ng tr\u1ecd, h\u1ee3p \u0111\u1ed3ng v\u00e0 c\u00e1c d\u1ecbch v\u1ee5 li\u00ean quan',
                  maxLines: 2,
                  style: TextStyle(
                    color: Color(0xFF263A2F),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
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

  Widget _overviewStats(
    LandlordDemoStore data,
    AnnouncementStore notifications,
  ) {
    final currentLease = data.currentLeaseForTenant(tenantId);
    final unpaidInvoices = data
        .invoicesForTenant(tenantId)
        .where((invoice) => !invoice.cancelled && invoice.remaining > 0)
        .length;
    final unreadNotifications = notifications
        .forTenant(tenantId)
        .where((item) => !notifications.isRead(item.id, tenantId))
        .length;
    final stats = [
      (Icons.home_rounded, currentLease == null ? '0' : '1', 'Phòng đang ở'),
      (
        Icons.description_rounded,
        '${data.leasesForTenant(tenantId).length}',
        'Hợp đồng',
      ),
      (Icons.receipt_long_rounded, '$unpaidInvoices', 'Hóa đơn chưa TT'),
      (Icons.notifications_rounded, '$unreadNotifications', 'Thông báo mới'),
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
              _stayImage(data.property.imageUrl),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _stayAction(
                  icon: Icons.description_rounded,
                  label: 'Xem hợp đồng',
                  onPressed: () => _openPage(
                    context,
                    'Hợp đồng thuê',
                    TenantLeaseContractPage(store: data, tenantId: tenantId),
                  ),
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

  Widget _stayImage(String imageUrl) {
    const placeholder = SizedBox(
      width: 112,
      height: 90,
      child: ColoredBox(
        color: Color(0xFFE9F1EA),
        child: Icon(Icons.home_work_rounded),
      ),
    );
    final source = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: source.isEmpty
          ? placeholder
          : Image.network(
              source,
              width: 112,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
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

  Widget _activityHistorySection(
    BuildContext context,
    LandlordDemoStore data, {
    bool showAll = true,
  }) {
    final activities = <_TenantActivityItem>[];
    for (final lease in data.leasesForTenant(tenantId)) {
      activities.add(
        _TenantActivityItem(
          icon: Icons.description_rounded,
          color: const Color(0xFF1688CC),
          title: 'Hợp đồng thuê phòng ${lease.room}',
          date: lease.startDate,
          onTap: () => _openPage(
            context,
            'Hợp đồng thuê',
            TenantLeaseContractPage(store: data, tenantId: tenantId),
          ),
        ),
      );
    }
    for (final invoice in data.invoicesForTenant(tenantId)) {
      final paid = invoice.status == LandlordInvoiceStatus.paid;
      activities.add(
        _TenantActivityItem(
          icon: Icons.receipt_long_rounded,
          color: paid ? tenantGreen : const Color(0xFF1688CC),
          title: 'Hóa đơn tháng ${invoice.period.month}/${invoice.period.year}',
          date: invoice.period,
          badge: invoice.status.label,
          badgeColor: paid ? const Color(0xFFE4F5E9) : const Color(0xFFF0F2F5),
          badgeForeground: paid ? tenantGreenDark : tenantMuted,
          onTap: () => _openPage(
            context,
            'Hóa đơn',
            TenantInvoicesPage(store: data, tenantId: tenantId),
          ),
        ),
      );
    }
    for (final payment in data.paymentsForTenant(tenantId)) {
      final (
        title,
        badge,
        color,
        badgeColor,
        badgeForeground,
      ) = switch (payment.status) {
        LandlordPaymentStatus.approved => (
          'Thanh toán đã được xác nhận',
          _formatVnd(payment.approvedAmount ?? payment.reportedAmount),
          tenantGreen,
          const Color(0xFFE4F5E9),
          tenantGreenDark,
        ),
        LandlordPaymentStatus.pending => (
          'Đã gửi yêu cầu thanh toán',
          _formatVnd(payment.reportedAmount),
          const Color(0xFFE79A11),
          const Color(0xFFFFF2D9),
          const Color(0xFF8A5A00),
        ),
        LandlordPaymentStatus.rejected => (
          'Thanh toán chưa được duyệt',
          _formatVnd(payment.reportedAmount),
          const Color(0xFFD64545),
          const Color(0xFFFFE7E7),
          const Color(0xFF9B2525),
        ),
      };
      activities.add(
        _TenantActivityItem(
          icon: Icons.credit_card_rounded,
          color: color,
          title: title,
          date: payment.paidAt,
          badge: badge,
          badgeColor: badgeColor,
          badgeForeground: badgeForeground,
          onTap: () => _openPage(
            context,
            'Hóa đơn',
            TenantInvoicesPage(store: data, tenantId: tenantId),
          ),
        ),
      );
    }
    for (final incident in data.incidentsForTenant(tenantId)) {
      activities.add(
        _TenantActivityItem(
          icon: Icons.build_circle_outlined,
          color: incident.status.color,
          title: 'Báo sự cố: ${incident.title}',
          date: _parseIncidentDate(incident.date),
          badge: incident.status.label,
          badgeColor: incident.status.color.withValues(alpha: 0.12),
          badgeForeground: incident.status.color,
          onTap: () => _openPage(
            context,
            'Báo sự cố',
            TenantBaoSuCoPage(store: data, tenantId: tenantId),
          ),
        ),
      );
    }
    activities.sort((a, b) => b.date.compareTo(a.date));
    final visible = showAll ? activities.take(3).toList() : activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: tenantGreenDark,
                size: 20,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Lịch sử hoạt động',
                  style: TextStyle(
                    color: tenantInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showAll && activities.length > 3)
                TextButton.icon(
                  onPressed: () => _openActivityHistory(context, data),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Xem tất cả'),
                  style: TextButton.styleFrom(
                    foregroundColor: tenantGreenDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (visible.isEmpty)
          const TenantSurface(
            child: Text(
              'Chưa có hoạt động nào được ghi nhận.',
              style: TextStyle(color: tenantMuted, fontSize: 12),
            ),
          )
        else
          for (var index = 0; index < visible.length; index++)
            _activityRow(
              icon: visible[index].icon,
              color: visible[index].color,
              title: visible[index].title,
              date: _formatActivityDate(visible[index].date),
              trailing: visible[index].badge == null
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: tenantMuted,
                      size: 21,
                    )
                  : TenantActivityBadge(
                      label: visible[index].badge!,
                      color:
                          visible[index].badgeColor ?? const Color(0xFFF0F2F5),
                      foreground: visible[index].badgeForeground ?? tenantMuted,
                    ),
              onTap: visible[index].onTap,
              isLast: index == visible.length - 1,
            ),
      ],
    );
  }

  Widget _activityRow({
    required IconData icon,
    required Color color,
    required String title,
    required String date,
    required Widget trailing,
    required VoidCallback onTap,
    bool isLast = false,
  }) => IntrinsicHeight(
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
                child: Icon(icon, color: color, size: 19),
              ),
            ],
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: tenantInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              color: tenantMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  static DateTime _parseIncidentDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return DateTime.fromMillisecondsSinceEpoch(0);
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime(year, month, day);
  }

  static String _formatActivityDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final day = '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
    if (date.hour == 0 && date.minute == 0) return day;
    return '$day · ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  static String _formatVnd(int amount) {
    final digits = amount.abs().toString();
    final result = StringBuffer(amount < 0 ? '-' : '');
    for (var index = 0; index < digits.length; index++) {
      result.write(digits[index]);
      final remaining = digits.length - index - 1;
      if (remaining > 0 && remaining % 3 == 0) result.write('.');
    }
    return '${result.toString()}đ';
  }

  void _openActivityHistory(BuildContext context, LandlordDemoStore data) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: tenantCanvas,
          appBar: AppBar(title: const Text('Lịch sử hoạt động')),
          body: TenantPageFrame(
            children: [_activityHistorySection(context, data, showAll: false)],
          ),
        ),
      ),
    );
  }

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

  String _memberInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final parts = words.toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _openPage(BuildContext context, String title, Widget page) {
    if (page is TenantInvoicesPage &&
        RoleLayoutShell.navigateTo(context, 'invoices')) {
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => TenantSubpageScaffold(
          title: title,
          appBar: page is TenantLeaseContractPage
              ? TenantLeaseNavigationBar(
                  onBack: () => Navigator.of(routeContext).maybePop(),
                )
              : page is TenantInvoicesPage
              ? TenantInvoiceNavigationBar(
                  onBack: () => Navigator.of(routeContext).maybePop(),
                  store: page.store,
                  tenantId: page.tenantId,
                )
              : null,
          child: page,
        ),
      ),
    );
  }
}
