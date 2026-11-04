import 'package:flutter/material.dart';

import '../pages/landlord/landlord_demo_store.dart';
import '../pages/shared/profile/account_store.dart';
import '../pages/shared/announcements/announcement_store.dart';
import '../pages/shared/conversations/conversation_store.dart';
import '../pages/shared/rental/tenant_session.dart';
import '../pages/tenant/discovery/tenant_favorites_page.dart';
import '../pages/tenant/tenant_settings_page.dart';
import '../pages/tenant/tenant_page_router.dart';
import '../pages/tenant/tenant_ui.dart';
import '../pages/tenant/tenant_navigation_bar.dart';
import '../pages/tenant/leases/components/tenant_lease_overview.dart';
import '../pages/tenant/invoices/components/tenant_invoice_dashboard_widgets.dart';
import 'role_layout.dart';

class TenantLayout extends StatelessWidget {
  const TenantLayout({
    super.key,
    this.displayName,
    this.contextLabel = 'Người thuê',
    this.onPreviewRoleSelected,
    this.pageBuilder,
    this.onLogout,
  });

  final String? displayName;
  final String contextLabel;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final RolePageBuilder? pageBuilder;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final store = LandlordDemoStore.instance;
    const tenantTabs = [
      RoleTab(
        label: 'Khám phá',
        icon: Icons.travel_explore_rounded,
        selectedIcon: Icons.home_rounded,
        destinationId: 'discovery',
      ),
      RoleTab(
        label: 'Chỗ ở của tôi',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        destinationId: 'my_lease',
      ),
      RoleTab(
        label: 'Tin nhắn',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum_rounded,
        destinationId: 'conversations',
      ),
      RoleTab(
        label: 'Thông báo',
        icon: Icons.notifications_none_rounded,
        selectedIcon: Icons.notifications_rounded,
        destinationId: 'announcements',
      ),
    ];
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
        accentColor: const Color(0xFF08A94F),
        initialDestinationId: 'discovery',
        showMoreTab: false,
        hideAppBarOnDestinations: const {
          'discovery',
          'viewings',
          'my_lease',
          'lease_contract',
          'members',
          'invoices',
          'conversations',
          'announcements',
          'incidents',
          'support',
          'settings',
        },
        topBarBuilder:
            (context, destination, onOpenDrawer, onSelectDestination, onBack) {
              if (destination.id == 'invoices') {
                return TenantInvoiceNavigationBar(
                  onBack: onBack,
                  onNotifications: () => onSelectDestination('announcements'),
                  store: store,
                  tenantId: TenantSession.currentTenantId,
                );
              }
              if (destination.id == 'lease_contract') {
                return TenantLeaseNavigationBar(onBack: onBack);
              }
              if (const {
                'discovery',
                'my_lease',
                'conversations',
                'announcements',
              }.contains(destination.id)) {
                return const SizedBox.shrink();
              }
              if (const {
                'settings',
                'profile',
                'notifications',
                'viewings',
                'members',
                'incidents',
                'support',
              }.contains(destination.id)) {
                return TenantNavigationBar(
                  title: destination.label,
                  onBack: onBack,
                  onNotifications: () => onSelectDestination('announcements'),
                  notifications: AnnouncementStore.forRental(store),
                  tenantId: TenantSession.currentTenantId,
                );
              }
              return TenantHeader(
                profileName:
                    displayName ??
                    AccountStore.instance.profile(AppRole.tenant).name,
                onAvatarTap: onOpenDrawer,
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
              );
            },
        bottomNavigationBuilder: (context, selectedIndex, onSelected) =>
            _TenantBottomNavigation(
              tabs: tenantTabs,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
        onPreviewRoleSelected: onPreviewRoleSelected,
        onLogout: onLogout,
        tabs: tenantTabs,
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
            id: 'lease_contract',
            label: 'Hợp đồng thuê',
            icon: Icons.description_outlined,
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

class _TenantBottomNavigation extends StatelessWidget {
  const _TenantBottomNavigation({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RoleTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ConversationStore.instance,
      AnnouncementStore.instance,
    ]),
    builder: (context, _) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x100D1C18),
            blurRadius: 16,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 7, 4, 3),
          child: Row(
            children: [
              for (var index = 0; index < tabs.length; index++)
                Expanded(
                  child: _TenantBottomNavigationItem(
                    tab: tabs[index],
                    selected: index == selectedIndex,
                    unreadCount: switch (tabs[index].destinationId) {
                      'conversations' =>
                        ConversationStore.instance
                            .forTenant(TenantSession.currentTenantId)
                            .fold<int>(
                              0,
                              (sum, item) => sum + item.tenantUnread,
                            ),
                      'announcements' =>
                        AnnouncementStore.instance
                            .forTenant(TenantSession.currentTenantId)
                            .where(
                              (item) => !AnnouncementStore.instance.isRead(
                                item.id,
                                TenantSession.currentTenantId,
                              ),
                            )
                            .length,
                      _ => 0,
                    },
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TenantBottomNavigationItem extends StatelessWidget {
  const _TenantBottomNavigationItem({
    required this.tab,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  final RoleTab tab;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF08A94F) : const Color(0xFF676B78);
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 29,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      selected ? tab.selectedIcon : tab.icon,
                      color: color,
                      size: 25,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -9,
                        top: -5,
                        child: Container(
                          key: ValueKey(
                            'tenant-${tab.destinationId}-unread-badge',
                          ),
                          constraints: const BoxConstraints(minWidth: 19),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          height: 19,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE83D3D),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 54,
                height: 3,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF08A94F)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
