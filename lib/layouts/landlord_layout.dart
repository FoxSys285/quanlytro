import 'package:flutter/material.dart';

import 'role_layout.dart';

class LandlordLayout extends StatelessWidget {
  const LandlordLayout({
    super.key,
    this.displayName = 'Nguyễn Văn An',
    this.contextLabel = 'Nhà trọ Bình An',
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
      role: AppRole.landlord,
      displayName: displayName,
      contextLabel: contextLabel,
      accentColor: const Color(0xFF3769D6),
      initialDestinationId: 'dashboard',
      onPreviewRoleSelected: onPreviewRoleSelected,
      pageBuilder: pageBuilder,
      tabs: const [
        RoleTab(
          label: 'Tổng quan',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          destinationId: 'dashboard',
        ),
        RoleTab(
          label: 'Phòng',
          icon: Icons.meeting_room_outlined,
          selectedIcon: Icons.meeting_room_rounded,
          destinationId: 'rooms',
        ),
        RoleTab(
          label: 'Hợp đồng',
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_rounded,
          destinationId: 'leases',
        ),
        RoleTab(
          label: 'Hóa đơn',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          destinationId: 'billing',
        ),
      ],
      destinations: const [
        RoleDestination(
          id: 'dashboard',
          label: 'Tổng quan',
          icon: Icons.dashboard_outlined,
          group: 'Điều hành',
        ),
        RoleDestination(
          id: 'properties',
          label: 'Nhà trọ',
          icon: Icons.home_work_outlined,
          group: 'Điều hành',
        ),
        RoleDestination(
          id: 'rooms',
          label: 'Phòng trọ',
          icon: Icons.meeting_room_outlined,
          group: 'Quản lý nhà',
        ),
        RoleDestination(
          id: 'room_types',
          label: 'Loại phòng',
          icon: Icons.category_outlined,
          group: 'Quản lý nhà',
        ),
        RoleDestination(
          id: 'services',
          label: 'Dịch vụ và bảng giá',
          icon: Icons.price_change_outlined,
          group: 'Quản lý nhà',
        ),
        RoleDestination(
          id: 'meter_readings',
          label: 'Chỉ số điện nước',
          icon: Icons.bolt_outlined,
          group: 'Quản lý nhà',
        ),
        RoleDestination(
          id: 'viewings',
          label: 'Lịch xem phòng',
          icon: Icons.calendar_month_outlined,
          group: 'Cho thuê',
        ),
        RoleDestination(
          id: 'leases',
          label: 'Hợp đồng',
          icon: Icons.description_outlined,
          group: 'Cho thuê',
        ),
        RoleDestination(
          id: 'members',
          label: 'Người thuê',
          icon: Icons.groups_outlined,
          group: 'Cho thuê',
        ),
        RoleDestination(
          id: 'conversations',
          label: 'Tin nhắn',
          icon: Icons.forum_outlined,
          group: 'Cho thuê',
        ),
        RoleDestination(
          id: 'billing',
          label: 'Lập hóa đơn',
          icon: Icons.receipt_long_outlined,
          group: 'Thu chi',
        ),
        RoleDestination(
          id: 'payments',
          label: 'Duyệt thanh toán',
          icon: Icons.fact_check_outlined,
          group: 'Thu chi',
        ),
        RoleDestination(
          id: 'payment_accounts',
          label: 'Tài khoản nhận tiền',
          icon: Icons.account_balance_outlined,
          group: 'Thu chi',
        ),
        RoleDestination(
          id: 'announcements',
          label: 'Gửi thông báo',
          icon: Icons.campaign_outlined,
          group: 'Vận hành',
        ),
        RoleDestination(
          id: 'incidents',
          label: 'Yêu cầu sửa chữa',
          icon: Icons.build_outlined,
          group: 'Vận hành',
        ),
        RoleDestination(
          id: 'staff',
          label: 'Nhân viên quản lý',
          icon: Icons.badge_outlined,
          group: 'Vận hành',
        ),
        RoleDestination(
          id: 'reports',
          label: 'Báo cáo',
          icon: Icons.query_stats_rounded,
          group: 'Vận hành',
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
    );
  }
}
