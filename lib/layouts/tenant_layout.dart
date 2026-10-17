import 'package:flutter/material.dart';

import '../pages/tenant/tenant_page_router.dart';
import '../pages/landlord/landlord_demo_store.dart';
import '../pages/shared/profile/account_store.dart';
import 'role_layout.dart';

class TenantLayout extends StatelessWidget {
  const TenantLayout({
    super.key,
    this.displayName,
    this.contextLabel = 'Người thuê',
    this.onPreviewRoleSelected,
    this.pageBuilder,
  });

  final String? displayName;
  final String contextLabel;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final RolePageBuilder? pageBuilder;

  @override
  Widget build(BuildContext context) {
    final store = LandlordDemoStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AccountStore.instance]),
      builder: (context, _) => RoleLayoutShell(
        role: AppRole.tenant,
        notificationsEnabled: AccountStore.instance.notificationsEnabled(
          AppRole.tenant,
        ),
        displayName:
            displayName ?? AccountStore.instance.profile(AppRole.tenant).name,
        contextLabel: contextLabel,
        accentColor: const Color(0xFF16836F),
        initialDestinationId: 'discovery',
        showMoreTab: false,
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
            label: 'Tin nhắn',
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum_rounded,
            destinationId: 'conversations',
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
            drawerLabel: 'Hóa đơn & thanh toán',
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
            id: 'support',
            label: 'Trợ giúp',
            icon: Icons.help_outline_rounded,
            group: 'Tài khoản',
          ),
          RoleDestination(
            id: 'ai_chat',
            label: 'Trợ lý AI',
            icon: Icons.auto_awesome_outlined,
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
      ),
    );
  }
}
