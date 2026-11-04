import 'package:flutter/material.dart';

import 'role_layout.dart';
import '../pages/admin/admin_page_router.dart';
import '../pages/admin/admin_ui.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    this.displayName = 'Quản trị viên',
    this.contextLabel = 'Quản trị hệ thống',
    this.onPreviewRoleSelected,
    this.pageBuilder,
    this.onLogout,
  });

  final String displayName;
  final String contextLabel;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final RolePageBuilder? pageBuilder;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: adminBlue)
            .copyWith(primary: adminBlue, secondary: adminTeal),
        scaffoldBackgroundColor: adminCanvas,
        dividerColor: adminLine,
        splashFactory: InkRipple.splashFactory,
        textTheme: Theme.of(context).textTheme
            .apply(bodyColor: adminInk, displayColor: adminInk),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: adminMuted, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: adminLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: adminLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: adminBlue, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ).copyWith(enableFeedback: true),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            foregroundColor: adminBlue,
            side: const BorderSide(color: adminLine),
            textStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ).copyWith(enableFeedback: true),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ).copyWith(enableFeedback: true),
        ),
        chipTheme: Theme.of(context).chipTheme.copyWith(
          backgroundColor: Colors.white,
          selectedColor: adminBlue.withValues(alpha: 0.1),
          checkmarkColor: adminBlue,
          labelStyle: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontSize: 13, color: adminInk),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: adminLine),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? adminBlue
                  : adminMuted,
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? adminBlue.withValues(alpha: 0.1)
                  : Colors.white,
            ),
            side: const WidgetStatePropertyAll(BorderSide(color: adminLine)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          modalBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      ),
      child: RoleLayoutShell(
        useSidebar: true,
        role: AppRole.admin,
        displayName: displayName,
        contextLabel: contextLabel,
        accentColor: adminBlue,
        initialDestinationId: 'dashboard',
        onPreviewRoleSelected: onPreviewRoleSelected,
        onLogout: onLogout,
        pageBuilder: pageBuilder ?? buildAdminPage,
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
            label: 'Hoa hồng',
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet_rounded,
            destinationId: 'commissions',
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
            id: 'commissions',
            label: 'Đối soát hoa hồng',
            icon: Icons.account_balance_wallet_outlined,
            group: 'Quản trị',
          ),
          RoleDestination(
            id: 'activity',
            label: 'Hoạt động ứng dụng',
            icon: Icons.sensors_rounded,
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
            label: 'Kiểm duyệt tin đăng',
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
      ),
    );
  }
}
