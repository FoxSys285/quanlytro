import 'package:flutter/material.dart';

import '../pages/landlord/landlord_theme.dart';
import 'role_layout.dart';

const landlordTabs = [
  RoleTab(
    label: 'Tổng quan',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    destinationId: 'dashboard',
  ),
  RoleTab(
    label: 'Nhà trọ',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    destinationId: 'properties',
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
  _ => -1,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? palette.canvas : const Color(0xFFF1F4FF),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          padding: const EdgeInsets.fromLTRB(7, 5, 7, 2),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: dark ? palette.line : Colors.white,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x295C7EB9),
                blurRadius: 24,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < landlordTabs.length; index++)
                Expanded(
                  child: _NavigationItem(
                    tab: landlordTabs[index],
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
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
    required this.onTap,
  });

  final RoleTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final color = selected ? const Color(0xFF0866FF) : const Color(0xFF7886A8);
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 75,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? palette.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: selected ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0866FF)
                      : Colors.transparent,
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

/// Keeps the four owner tabs visible while a detail page is open.
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
