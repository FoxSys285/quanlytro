import 'package:flutter/material.dart';

import 'role_layout.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    this.displayName = 'Quản trị viên',
    this.contextLabel = 'Quản trị hệ thống',
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
      role: AppRole.admin,
      displayName: displayName,
      contextLabel: contextLabel,
      accentColor: const Color(0xFF7153C8),
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
          label: 'Người dùng',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts_rounded,
          destinationId: 'users',
        ),
        RoleTab(
          label: 'Hỗ trợ',
          icon: Icons.support_agent_outlined,
          selectedIcon: Icons.support_agent_rounded,
          destinationId: 'support',
        ),
      ],
      destinations: const [
        RoleDestination(
          id: 'dashboard',
          label: 'Tổng quan',
          icon: Icons.dashboard_outlined,
          group: 'Quản trị',
        ),
        RoleDestination(
          id: 'users',
          label: 'Người dùng',
          icon: Icons.manage_accounts_outlined,
          group: 'Quản trị',
        ),
        RoleDestination(
          id: 'property_verification',
          label: 'Xác minh nhà trọ',
          icon: Icons.verified_user_outlined,
          group: 'Kiểm duyệt',
        ),
        RoleDestination(
          id: 'moderation',
          label: 'Kiểm duyệt và báo cáo',
          icon: Icons.flag_outlined,
          group: 'Kiểm duyệt',
        ),
        RoleDestination(
          id: 'support',
          label: 'Yêu cầu hỗ trợ',
          icon: Icons.support_agent_outlined,
          group: 'Hỗ trợ',
        ),
        RoleDestination(
          id: 'audit_logs',
          label: 'Nhật ký hoạt động',
          icon: Icons.manage_search_rounded,
          group: 'Hệ thống',
        ),
        RoleDestination(
          id: 'settings',
          label: 'Cấu hình nền tảng',
          icon: Icons.settings_outlined,
          group: 'Hệ thống',
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
      ],
    );
  }
}
