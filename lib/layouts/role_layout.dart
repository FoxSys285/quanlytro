import 'package:flutter/material.dart';

enum AppRole { tenant, landlord, admin }

extension AppRoleLabel on AppRole {
  String get label {
    switch (this) {
      case AppRole.tenant:
        return 'Người thuê';
      case AppRole.landlord:
        return 'Chủ trọ';
      case AppRole.admin:
        return 'Quản trị viên';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.tenant:
        return Icons.person_outline_rounded;
      case AppRole.landlord:
        return Icons.home_work_outlined;
      case AppRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}

@immutable
class RoleDestination {
  const RoleDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.group,
  });

  final String id;
  final String label;
  final IconData icon;
  final String group;
}

@immutable
class RoleTab {
  const RoleTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.destinationId,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  final String destinationId;
}

typedef RolePageBuilder = Widget Function(
  BuildContext context,
  RoleDestination destination,
);

class RoleLayoutShell extends StatefulWidget {
  const RoleLayoutShell({
    super.key,
    required this.role,
    required this.displayName,
    required this.contextLabel,
    required this.accentColor,
    required this.destinations,
    required this.tabs,
    required this.initialDestinationId,
    this.appName = 'An Cư',
    this.pageBuilder,
    this.onPreviewRoleSelected,
    this.onLogout,
  });

  final AppRole role;
  final String displayName;
  final String contextLabel;
  final Color accentColor;
  final List<RoleDestination> destinations;
  final List<RoleTab> tabs;
  final String initialDestinationId;
  final String appName;
  final RolePageBuilder? pageBuilder;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final VoidCallback? onLogout;

  @override
  State<RoleLayoutShell> createState() => _RoleLayoutShellState();
}

class _RoleLayoutShellState extends State<RoleLayoutShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _selectedDestinationId = widget.initialDestinationId;
  late int _selectedTabIndex = 0;

  RoleDestination get _selectedDestination => widget.destinations.firstWhere(
    (destination) => destination.id == _selectedDestinationId,
    orElse: () => widget.destinations.first,
  );

  void _selectDestination(String id) {
    if (!widget.destinations.any((destination) => destination.id == id)) {
      return;
    }

    setState(() {
      _selectedDestinationId = id;
      final tabIndex = widget.tabs.indexWhere((tab) => tab.destinationId == id);
      // The final tab is the drawer shortcut for secondary destinations.
      _selectedTabIndex = tabIndex == -1 ? widget.tabs.length : tabIndex;
    });
  }

  void _onTabSelected(int index) {
    if (index == widget.tabs.length) {
      setState(() => _selectedTabIndex = index);
      _scaffoldKey.currentState?.openDrawer();
      return;
    }

    _selectDestination(widget.tabs[index].destinationId);
  }

  void _showLogoutMessage() {
    if (widget.onLogout != null) {
      widget.onLogout!.call();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kết nối chức năng đăng xuất tại đây.')),
    );
  }

  String get _avatarInitials {
    final words = widget.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words.first[0].toUpperCase();
    return words.first[0].toUpperCase() + words.last[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final destination = _selectedDestination;
    final page =
        widget.pageBuilder?.call(context, destination) ??
        _LayoutPlaceholder(
          role: widget.role,
          destination: destination,
          accentColor: widget.accentColor,
        );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _RoleDrawer(
        role: widget.role,
        appName: widget.appName,
        displayName: widget.displayName,
        contextLabel: widget.contextLabel,
        initials: _avatarInitials,
        accentColor: widget.accentColor,
        destinations: widget.destinations,
        selectedDestinationId: _selectedDestinationId,
        onDestinationSelected: _selectDestination,
        onPreviewRoleSelected: widget.onPreviewRoleSelected,
        onLogout: _showLogoutMessage,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        leading: IconButton(
          tooltip: 'Mở danh mục chức năng',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF17212B),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.contextLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF788492),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => _selectDestination('notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE45A65),
                      border: Border.all(color: Colors.white, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 16),
            child: PopupMenuButton<String>(
              tooltip: 'Tài khoản',
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutMessage();
                } else {
                  _selectDestination(value);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.person_outline_rounded),
                    title: Text('Hồ sơ'),
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Cài đặt'),
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.logout_rounded),
                    title: Text('Đăng xuất'),
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 17,
                backgroundColor: widget.accentColor.withValues(alpha: 0.12),
                child: Text(
                  _avatarInitials,
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(top: false, child: page),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: widget.accentColor.withValues(alpha: 0.12),
        selectedIndex: _selectedTabIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _onTabSelected,
        destinations: [
          for (final tab in widget.tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Thêm',
          ),
        ],
      ),
    );
  }
}

class _RoleDrawer extends StatelessWidget {
  const _RoleDrawer({
    required this.role,
    required this.appName,
    required this.displayName,
    required this.contextLabel,
    required this.initials,
    required this.accentColor,
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.onPreviewRoleSelected,
    required this.onLogout,
  });

  final AppRole role;
  final String appName;
  final String displayName;
  final String contextLabel;
  final String initials;
  final Color accentColor;
  final List<RoleDestination> destinations;
  final String selectedDestinationId;
  final ValueChanged<String> onDestinationSelected;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<RoleDestination>>{};
    for (final destination in destinations) {
      groups.putIfAbsent(destination.group, () => []).add(destination);
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 440 ? screenWidth * 0.88 : 380.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFFFCFDFE),
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              appName: appName,
              role: role,
              displayName: displayName,
              contextLabel: contextLabel,
              initials: initials,
              accentColor: accentColor,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                children: [
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 15, 12, 6),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF8B97A4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    for (final destination in entry.value)
                      _DrawerDestinationTile(
                        destination: destination,
                        selected: destination.id == selectedDestinationId,
                        accentColor: accentColor,
                        onTap: () {
                          Navigator.of(context).pop();
                          onDestinationSelected(destination.id);
                        },
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9EDF2)),
            if (onPreviewRoleSelected != null)
              PopupMenuButton<AppRole>(
                tooltip: 'Chuyển vai trò xem thử',
                onSelected: (selectedRole) {
                  Navigator.of(context).pop();
                  onPreviewRoleSelected!.call(selectedRole);
                },
                itemBuilder: (context) => [
                  for (final option in AppRole.values)
                    PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 19),
                          const SizedBox(width: 12),
                          Text(option.label),
                          if (option == role) ...[
                            const Spacer(),
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: accentColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
                child: ListTile(
                  leading: Icon(Icons.swap_horiz_rounded, color: accentColor),
                  title: const Text('Xem thử giao diện vai trò'),
                  trailing: const Icon(Icons.unfold_more_rounded, size: 18),
                  dense: true,
                ),
              ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF7A8793),
              ),
              title: const Text('Đăng xuất'),
              dense: true,
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.appName,
    required this.role,
    required this.displayName,
    required this.contextLabel,
    required this.initials,
    required this.accentColor,
  });

  final String appName;
  final AppRole role;
  final String displayName;
  final String contextLabel;
  final String initials;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor.withValues(alpha: 0.13), Colors.white],
        ),
        border: const Border(bottom: BorderSide(color: Color(0xFFE9EDF2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                appName,
                style: const TextStyle(
                  color: Color(0xFF17212B),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role.label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: accentColor.withValues(alpha: 0.16),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17212B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF788492),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerDestinationTile extends StatelessWidget {
  const _DrawerDestinationTile({
    required this.destination,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final RoleDestination destination;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: accentColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        leading: Icon(
          destination.icon,
          color: selected ? accentColor : const Color(0xFF6D7986),
          size: 21,
        ),
        title: Text(
          destination.label,
          style: TextStyle(
            color: selected ? accentColor : const Color(0xFF344252),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? Icon(Icons.chevron_right_rounded, color: accentColor, size: 20)
            : null,
        dense: true,
        onTap: onTap,
      ),
    );
  }
}

class _LayoutPlaceholder extends StatelessWidget {
  const _LayoutPlaceholder({
    required this.role,
    required this.destination,
    required this.accentColor,
  });

  final AppRole role;
  final RoleDestination destination;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final roleHint = switch (role) {
      AppRole.tenant => 'Không gian dành cho người thuê',
      AppRole.landlord => 'Không gian quản lý nhà trọ',
      AppRole.admin => 'Không gian quản trị hệ thống',
    };

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 34, 28, 34),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE9EDF2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0B1B2B3B),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        destination.icon,
                        color: accentColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      roleHint.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF17212B),
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Vùng nội dung của màn hình này để nhóm bạn tự thiết kế. Thanh điều hướng, menu chức năng và khung trang đã sẵn sàng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF788492),
                        height: 1.55,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
