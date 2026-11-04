import 'package:flutter/material.dart';

import '../pages/landlord/landlord_demo_store.dart';
import '../pages/landlord/landlord_theme.dart';
import '../pages/shared/announcements/announcement_store.dart';
import 'role_layout.dart';

const landlordTabs = [
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
    label: 'Thu chi',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet_rounded,
    destinationId: 'billing',
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

int landlordTabIndex(String destinationId) => switch (destinationId) {
  'rooms' ||
  'properties' ||
  'room_types' ||
  'services' ||
  'meter_readings' ||
  'viewings' ||
  'leases' ||
  'members' => 1,
  'billing' || 'payments' || 'payment_accounts' => 2,
  'conversations' => 3,
  'announcements' || 'incidents' || 'staff' => 4,
  _ => 0,
};

class LandlordBottomNavigation extends StatelessWidget {
  const LandlordBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final announcements = AnnouncementStore.forRental(
      LandlordDemoStore.activeInstance,
    );
    return ListenableBuilder(
      listenable: announcements,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          boxShadow: [
            BoxShadow(
              color: palette.ink.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 7, 4, 3),
            child: Row(
              children: [
                for (var index = 0; index < landlordTabs.length; index++)
                  Expanded(
                    child: _NavigationItem(
                      tab: landlordTabs[index],
                      selected: index == selectedIndex,
                      badge: index == 4
                          ? announcements.inbox
                                .where((item) => !item.isRead)
                                .length
                          : 0,
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
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.tab,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final RoleTab tab;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final color = selected ? palette.primary : palette.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    color: color,
                    size: 23,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8475B),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? palette.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps the five owner tabs visible while a detail page is open.
class LandlordNavigation {
  static Future<T?> push<T>(
    BuildContext context, {
    required Widget page,
    required String destinationId,
    String? title,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => Scaffold(
          appBar: title == null ? null : AppBar(title: Text(title)),
          body: page,
          bottomNavigationBar: LandlordBottomNavigation(
            selectedIndex: landlordTabIndex(destinationId),
            onSelected: (index) {
              Navigator.of(context).pop();
              if (context.mounted) {
                RoleLayoutShell.navigateTo(
                  context,
                  landlordTabs[index].destinationId,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
