import 'package:flutter/material.dart';

import '../pages/tenant_pages.dart';
import 'role_layout.dart';

class TenantLayout extends StatelessWidget {
  const TenantLayout({
    super.key,
    this.displayName = 'Minh Anh',
    this.contextLabel = 'Khu vực người thuê',
    this.onPreviewRoleSelected,
    this.pageBuilder,
  });

  final String displayName;
  final String contextLabel;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final RolePageBuilder? pageBuilder;

  @override
  Widget build(BuildContext context) {
    return RoleLayoutShell(
      role: AppRole.tenant,
      displayName: displayName,
      contextLabel: contextLabel,
      accentColor: const Color(0xFF16836F),
      initialDestinationId: 'discovery',
      onPreviewRoleSelected: onPreviewRoleSelected,
      tabs: const [
        RoleTab(
          label: 'Khám phá',
          icon: Icons.search_rounded,
          selectedIcon: Icons.travel_explore_rounded,
          destinationId: 'discovery',
        ),
        RoleTab(
          label: 'Chỗ ở',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          destinationId: 'my_lease',
        ),
        RoleTab(
          label: 'Hóa đơn',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          destinationId: 'invoices',
        ),
        RoleTab(
          label: 'Lịch sử',
          icon: Icons.history_rounded,
          selectedIcon: Icons.history_rounded,
          destinationId: 'payments',
        ),
      ],
      destinations: const [
        RoleDestination(
          id: 'discovery',
          label: 'Khám phá nhà trọ',
          icon: Icons.travel_explore_rounded,
          group: 'Bắt đầu',
        ),
        RoleDestination(
          id: 'viewings',
          label: 'Lịch xem phòng',
          icon: Icons.calendar_month_outlined,
          group: 'Bắt đầu',
        ),
        RoleDestination(
          id: 'my_lease',
          label: 'Chỗ ở của tôi',
          icon: Icons.home_outlined,
          group: 'Chỗ ở hiện tại',
        ),
        RoleDestination(
          id: 'members',
          label: 'Thành viên phòng',
          icon: Icons.group_outlined,
          group: 'Chỗ ở hiện tại',
        ),
        RoleDestination(
          id: 'invoices',
          label: 'Hóa đơn',
          icon: Icons.receipt_long_outlined,
          group: 'Thanh toán',
        ),
        RoleDestination(
          id: 'payments',
          label: 'Lịch sử thanh toán',
          icon: Icons.account_balance_wallet_outlined,
          group: 'Thanh toán',
        ),
        RoleDestination(
          id: 'conversations',
          label: 'Tin nhắn',
          icon: Icons.forum_outlined,
          group: 'Trao đổi',
        ),
        RoleDestination(
          id: 'announcements',
          label: 'Thông báo nhà trọ',
          icon: Icons.campaign_outlined,
          group: 'Trao đổi',
        ),
        RoleDestination(
          id: 'incidents',
          label: 'Báo sự cố',
          icon: Icons.build_outlined,
          group: 'Trao đổi',
        ),
        RoleDestination(
          id: 'notifications',
          label: 'Thông báo ứng dụng',
          icon: Icons.notifications_none_rounded,
          group: 'Tài khoản',
        ),
        RoleDestination(
          id: 'profile',
          label: 'Hồ sơ cá nhân',
          icon: Icons.person_outline_rounded,
          group: 'Tài khoản',
        ),
        RoleDestination(
          id: 'support',
          label: 'Trợ giúp',
          icon: Icons.help_outline_rounded,
          group: 'Tài khoản',
        ),
        RoleDestination(
          id: 'settings',
          label: 'Cài đặt',
          icon: Icons.settings_outlined,
          group: 'Tài khoản',
        ),
      ],
      pageBuilder: pageBuilder ?? buildTenantPage,
    );
  }
}
