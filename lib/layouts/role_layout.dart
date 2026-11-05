import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/shared/widgets/app_brand.dart' as brand;

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
    this.drawerLabel,
  });

  final String id;
  final String label;
  final IconData icon;
  final String group;
  final String? drawerLabel;
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

typedef RoleBottomNavigationBuilder = Widget Function(
  BuildContext context,
  int selectedIndex,
  ValueChanged<int> onDestinationSelected,
);

typedef RoleTopBarBuilder = Widget Function(
  BuildContext context,
  RoleDestination destination,
  VoidCallback onOpenDrawer,
  ValueChanged<String> onSelectDestination,
  VoidCallback onBack,
);

class RoleLayoutShell extends StatefulWidget {
  /// Opens a destination inside the existing role shell when one is present.
  static bool navigateTo(BuildContext context, String destinationId) =>
      tryNavigateTo(context, destinationId);

  static bool tryNavigateTo(BuildContext context, String destinationId) {
    final shell = context.findAncestorStateOfType<_RoleLayoutShellState>();
    if (shell == null ||
        !shell.widget.destinations.any((item) => item.id == destinationId)) {
      return false;
    }
    shell._selectDestination(destinationId);
    return true;
  }

  const RoleLayoutShell({
    super.key,
    required this.role,
    required this.displayName,
    required this.contextLabel,
    required this.accentColor,
    required this.destinations,
    required this.tabs,
    required this.initialDestinationId,
    this.appName = brand.appName,
    this.showMoreTab = true,
    this.pageBuilder,
    this.onPreviewRoleSelected,
    this.onLogout,
    this.notificationsEnabled = true,
    this.topBar,
    this.topBarBuilder,
    this.themeAction,
    this.useSidebar = false,
    this.hideAppBarOnDestination,
    this.hideAppBarOnDestinations,
    this.hideTopBarOnDestinations,
    this.bottomNavigationBuilder,
    this.retainedDestinationIds = const {},
  });

  final AppRole role;
  final String displayName;
  final String contextLabel;
  final Color accentColor;
  final List<RoleDestination> destinations;
  final List<RoleTab> tabs;
  final String initialDestinationId;
  final String appName;
  final bool showMoreTab;
  final RolePageBuilder? pageBuilder;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final VoidCallback? onLogout;
  final bool notificationsEnabled;
  final Widget? topBar;
  final RoleTopBarBuilder? topBarBuilder;
  final Widget? themeAction;
  final bool useSidebar;
  final String? hideAppBarOnDestination;
  final Set<String>? hideAppBarOnDestinations;
  final Set<String>? hideTopBarOnDestinations;
  final RoleBottomNavigationBuilder? bottomNavigationBuilder;
  final Set<String> retainedDestinationIds;

  @override
  State<RoleLayoutShell> createState() => _RoleLayoutShellState();
}

class _RoleLayoutShellState extends State<RoleLayoutShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _drawerScrollController = ScrollController();
  final _drawerViewportKey = GlobalKey();
  final _selectedDrawerItemKey = GlobalKey();
  late String _selectedDestinationId = widget.initialDestinationId;
  late int _selectedTabIndex = _tabIndexFor(widget.initialDestinationId);
  String? _previousDestinationId;
  final _visitedRetainedDestinations = <String>{};

  @override
  void dispose() {
    _drawerScrollController.dispose();
    super.dispose();
  }

  void _onDrawerChanged(bool isOpen) {
    if (!isOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scaffoldKey.currentState?.isDrawerOpen != true) return;
      final itemContext = _selectedDrawerItemKey.currentContext;
      final item = itemContext?.findRenderObject();
      final viewport = _drawerViewportKey.currentContext?.findRenderObject();
      if (itemContext == null || item is! RenderBox || viewport is! RenderBox) {
        return;
      }
      final top = item.localToGlobal(Offset.zero, ancestor: viewport).dy;
      // Preserve the current offset if the selected destination is already visible.
      if (top >= 0 && top + item.size.height <= viewport.size.height) return;
      Scrollable.ensureVisible(itemContext, alignment: 0.5);
    });
  }

  int _tabIndexFor(String id) {
    final index = widget.tabs.indexWhere((tab) => tab.destinationId == id);
    if (index != -1) return index;
    if (widget.role == AppRole.landlord && !widget.showMoreTab) {
      const roomPages = {
        'properties',
        'room_types',
        'services',
        'meter_readings',
        'viewings',
        'leases',
        'members',
      };
      const financePages = {'payments', 'payment_accounts'};
      const noticePages = {'incidents', 'staff'};
      if (roomPages.contains(id)) return 1;
      if (financePages.contains(id)) return 2;
      if (noticePages.contains(id)) return 4;
    }
    return widget.showMoreTab ? widget.tabs.length : 0;
  }

  RoleDestination get _selectedDestination => widget.destinations.firstWhere(
    (destination) => destination.id == _selectedDestinationId,
    orElse: () => widget.destinations.first,
  );

  void _selectDestination(String id) {
    if (!widget.destinations.any((destination) => destination.id == id)) {
      return;
    }

    if (id != _selectedDestinationId) {
      _previousDestinationId = _selectedDestinationId;
    }
    if (widget.role == AppRole.admin &&
        widget.useSidebar &&
        id != _selectedDestinationId) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _selectedDestinationId = id;
      // Highlight the drawer shortcut when available for secondary destinations.
      _selectedTabIndex = _tabIndexFor(id);
    });
  }

  void _goBackToPreviousDestination() {
    final previous = _previousDestinationId ?? widget.initialDestinationId;
    _selectDestination(previous);
  }

  void _onTabSelected(int index) {
    if (widget.showMoreTab && index == widget.tabs.length) {
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
    final topBar =
        widget.topBarBuilder?.call(
          context,
          destination,
          () => _scaffoldKey.currentState?.openDrawer(),
          _selectDestination,
          _goBackToPreviousDestination,
        ) ??
        widget.topBar;
    final landlordTheme = widget.role == AppRole.landlord;
    final scheme = Theme.of(context).colorScheme;
    final console = widget.role == AppRole.admin && widget.useSidebar;
    const consoleInk = Colors.white;
    final adminWide =
        widget.useSidebar && MediaQuery.sizeOf(context).width >= 1100;
    final page =
        widget.pageBuilder?.call(context, destination) ??
        _LayoutPlaceholder(
          role: widget.role,
          destination: destination,
          accentColor: widget.accentColor,
        );
    if (widget.retainedDestinationIds.contains(destination.id)) {
      _visitedRetainedDestinations.add(destination.id);
    }
    final retained = widget.destinations
        .where(
          (item) =>
              _visitedRetainedDestinations.contains(item.id) &&
              widget.retainedDestinationIds.contains(item.id),
        )
        .toList();
    final retainedIndex = retained.indexWhere(
      (item) => item.id == destination.id,
    );
    final content = retained.isNotEmpty
        ? IndexedStack(
            index: retainedIndex < 0 ? retained.length : retainedIndex,
            children: [
              for (final item in retained)
                TickerMode(
                  key: ValueKey('retained-${item.id}'),
                  enabled: item.id == destination.id,
                  child: item.id == destination.id
                      ? page
                      : widget.pageBuilder?.call(context, item) ??
                            _LayoutPlaceholder(
                              role: widget.role,
                              destination: item,
                              accentColor: widget.accentColor,
                            ),
                ),
              if (retainedIndex < 0)
                KeyedSubtree(key: ValueKey(destination.id), child: page),
            ],
          )
        : console
        ? AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(key: ValueKey(destination.id), child: page),
          )
        : page;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.role == AppRole.admin
          ? const Color(0xFFF0F6FA)
          : widget.role == AppRole.tenant
          ? const Color(0xFFFCFCFC)
          : Theme.of(context).scaffoldBackgroundColor,
      onDrawerChanged: _onDrawerChanged,
      drawer: _RoleDrawer(
        scrollController: _drawerScrollController,
        viewportKey: _drawerViewportKey,
        selectedItemKey: _selectedDrawerItemKey,
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
      appBar:
          _selectedDestinationId == widget.hideAppBarOnDestination ||
              (widget.hideAppBarOnDestinations?.contains(
                    _selectedDestinationId,
                  ) ??
                  false)
          ? null
          : AppBar(
              backgroundColor: console
                  ? const Color(0xFF0F2537)
                  : widget.role == AppRole.tenant
                  ? const Color(0xFFFCFCFC)
                  : landlordTheme
                  ? scheme.surface
                  : Colors.white,
              foregroundColor: console ? consoleInk : null,
              iconTheme: console ? IconThemeData(color: consoleInk) : null,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: console ? 56 : 68,
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
                    console && destination.id == 'dashboard'
                        ? 'Quản trị'
                        : destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: console
                          ? consoleInk
                          : landlordTheme
                          ? scheme.onSurface
                          : const Color(0xFF17212B),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!console) const SizedBox(height: 2),
                  if (!console)
                    Text(
                      widget.contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: landlordTheme
                            ? scheme.onSurface.withValues(alpha: 0.7)
                            : const Color(0xFF788492),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              actions: [
                ?widget.themeAction,
                IconButton(
                  tooltip: 'Thông báo',
                  onPressed: () => _selectDestination(
                    widget.role == AppRole.admin
                        ? 'notifications'
                        : 'announcements',
                  ),
                  icon: widget.role != AppRole.admin
                      ? const Icon(Icons.notifications_none_rounded)
                      : Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              widget.notificationsEnabled
                                  ? Icons.notifications_none_rounded
                                  : Icons.notifications_off_outlined,
                            ),
                            if (widget.notificationsEnabled && !console)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE45A65),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
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
                    itemBuilder: (context) => [
                      if (widget.role == AppRole.admin)
                        const PopupMenuItem(
                          value: 'profile',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.person_outline_rounded),
                            title: Text('Hồ sơ'),
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.settings_outlined),
                          title: Text('Cài đặt'),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
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
                      backgroundColor: widget.accentColor.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        _avatarInitials,
                        style: TextStyle(
                          color: console ? consoleInk : widget.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!(widget.hideTopBarOnDestinations?.contains(
                  _selectedDestinationId,
                ) ??
                false))
              ?topBar,
            Expanded(
              child: adminWide
                  ? Row(
                      children: [
                        Container(
                          width: 224,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F2537),
                            border: Border(
                              right: BorderSide(color: Color(0xFFDCE6F1)),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(12, 16, 12, 24),
                                  child: Text(
                                    'Quản trị trọ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                for (final item in widget.destinations)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: ListTile(
                                      selected:
                                          item.id == _selectedDestinationId,
                                      selectedTileColor: const Color(
                                        0xFF0284C7,
                                      ),
                                      selectedColor: Colors.white,
                                      textColor: const Color(0xFFD0E4F5),
                                      iconColor: const Color(0xFF93B8D8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      leading: Icon(item.icon, size: 19),
                                      title: Text(
                                        item.label,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onTap: () => _selectDestination(item.id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(child: content),
                      ],
                    )
                  : content,
            ),
          ],
        ),
      ),
      bottomNavigationBar: adminWide
          ? null
          : widget.bottomNavigationBuilder?.call(
                  context,
                  widget.role == AppRole.tenant &&
                          !widget.tabs.any(
                            (tab) =>
                                tab.destinationId == _selectedDestinationId,
                          )
                      ? -1
                      : _selectedTabIndex,
                  _onTabSelected,
                ) ??
                NavigationBar(
                  height: 70,
                  backgroundColor: landlordTheme
                      ? scheme.surface
                      : Colors.white,
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
                    if (widget.showMoreTab)
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
    required this.scrollController,
    required this.viewportKey,
    required this.selectedItemKey,
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
  final ScrollController scrollController;
  final GlobalKey viewportKey;
  final GlobalKey selectedItemKey;
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
    final landlordTheme = role == AppRole.landlord;
    final scheme = Theme.of(context).colorScheme;
    final groups = <String, List<RoleDestination>>{};
    for (final destination in destinations) {
      groups.putIfAbsent(destination.group, () => []).add(destination);
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 440 ? screenWidth * 0.88 : 380.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: landlordTheme ? scheme.surface : const Color(0xFFFCFDFE),
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
              child: SizedBox(
                key: viewportKey,
                child: SingleChildScrollView(
                  key: PageStorageKey('role-drawer-${role.name}'),
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 15, 12, 6),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              color: landlordTheme
                                  ? scheme.onSurface.withValues(alpha: 0.58)
                                  : const Color(0xFF8B97A4),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        for (final destination in entry.value)
                          _DrawerDestinationTile(
                            itemKey: destination.id == selectedDestinationId
                                ? selectedItemKey
                                : null,
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
              ),
            ),
            Divider(
              height: 1,
              color: landlordTheme ? scheme.outline : const Color(0xFFE9EDF2),
            ),
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
    final landlordTheme = role == AppRole.landlord;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: landlordTheme
              ? [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                  Theme.of(context).colorScheme.surface,
                ]
              : [accentColor.withValues(alpha: 0.13), Colors.white],
        ),
        border: Border(
          bottom: BorderSide(
            color: landlordTheme
                ? Theme.of(context).colorScheme.outline
                : const Color(0xFFE9EDF2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const brand.AppLogo(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: landlordTheme
                        ? Theme.of(context).colorScheme.onSurface
                        : const Color(0xFF17212B),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: landlordTheme
                      ? accentColor.withValues(alpha: 0.12)
                      : accentColor.withValues(alpha: 0.1),
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
                backgroundColor: landlordTheme
                    ? accentColor.withValues(alpha: 0.14)
                    : accentColor.withValues(alpha: 0.16),
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
                      style: TextStyle(
                        color: landlordTheme
                            ? Theme.of(context).colorScheme.onSurface
                            : const Color(0xFF17212B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: landlordTheme
                            ? Theme.of(context).colorScheme.onSurface
                                  .withValues(alpha: 0.68)
                            : const Color(0xFF788492),
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
    this.itemKey,
    required this.destination,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final RoleDestination destination;
  final Key? itemKey;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        key: itemKey,
        selected: selected,
        selectedTileColor: accentColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        leading: Icon(
          destination.icon,
          color: selected
              ? accentColor
              : dark
              ? scheme.onSurface.withValues(alpha: 0.7)
              : const Color(0xFF6D7986),
          size: 21,
        ),
        title: Text(
          destination.drawerLabel ?? destination.label,
          style: TextStyle(
            color: selected
                ? accentColor
                : dark
                ? scheme.onSurface
                : const Color(0xFF344252),
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
