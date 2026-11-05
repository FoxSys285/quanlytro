import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../data/app_persistence.dart';
import '../data/local_auth.dart';
import '../pages/landlord/landlord_demo_store.dart';
import '../pages/landlord/landlord_theme.dart';
import '../pages/landlord/announcements/landlord_announcements_page.dart';
import '../pages/landlord/properties/landlord_properties_page.dart';
import '../pages/landlord/rooms/landlord_rooms_page.dart';
import '../pages/landlord/dashboard/landlord_tongquan_page.dart';
import '../pages/landlord/billing/landlord_billing_page.dart';
import '../pages/landlord/conversations/landlord_danhsachtinnhan_page.dart';
import 'landlord_navigation.dart';
import '../pages/shared/profile/account_store.dart';
import '../pages/landlord/landlord_page_router.dart';
import 'role_layout.dart';

class LandlordLayout extends StatefulWidget {
  const LandlordLayout({
    super.key,
    this.displayName,
    this.contextLabel,
    this.onPreviewRoleSelected,
    this.pageBuilder,
    this.onLogout,
  });

  final String? displayName;
  final String? contextLabel;
  final ValueChanged<AppRole>? onPreviewRoleSelected;
  final RolePageBuilder? pageBuilder;
  final VoidCallback? onLogout;

  @override
  State<LandlordLayout> createState() => _LandlordLayoutState();
}

class _LandlordLayoutState extends State<LandlordLayout> {
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<File> _themeFile() async {
    final factory = Platform.isWindows || Platform.isLinux
        ? ffi.databaseFactoryFfi
        : databaseFactory;
    return File(
      paths.join(await factory.getDatabasesPath(), 'landlord_theme.txt'),
    );
  }

  Future<void> _loadTheme() async {
    try {
      final file = await _themeFile();
      if (await file.exists() && mounted) {
        final savedTheme = (await file.readAsString()).trim();
        if (mounted) setState(() => _dark = savedTheme == 'dark');
      }
    } catch (_) {
      // Theme preference is optional; keep the light theme if storage fails.
    }
  }

  Future<void> _toggleTheme() async {
    setState(() => _dark = !_dark);
    try {
      final file = await _themeFile();
      await file.writeAsString(_dark ? 'dark' : 'light');
    } catch (_) {
      // The switch still works for this session if storage is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: landlordTheme(dark: _dark),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          RentalPortfolio.instance,
          AccountStore.instance,
          if (AppPersistence.current != null)
            AppPersistence.current!.refreshing,
        ]),
        builder: (context, _) {
          final active = LandlordDemoStore.activeInstance;
          final displayName =
              widget.displayName ??
              (active.property.ownerName.trim().isNotEmpty
                  ? active.property.ownerName
                  : LocalAuth.instance.session?.displayName ?? 'Chủ trọ');
          return RoleLayoutShell(
            role: AppRole.landlord,
            hideAppBarOnDestinations: const {
              'dashboard',
              'properties',
              'billing',
              'conversations',
              'rooms',
              'announcements',
              'room_types',
            },
            hideTopBarOnDestinations: const {
              'room_types',
              'rooms',
              'announcements',
              'properties',
              'dashboard',
              'billing',
              'conversations',
            },
            notificationsEnabled: AccountStore.instance.notificationsEnabled(
              AppRole.landlord,
            ),
            displayName: displayName,
            contextLabel:
                widget.contextLabel ??
                (active.property.name.trim().isNotEmpty
                    ? active.property.name
                    : 'Quản lý nhà trọ'),
            accentColor: LandlordPalette.of(context).primary,
            themeAction: IconButton(
              tooltip: _dark
                  ? 'Chuyển sang giao diện sáng'
                  : 'Chuyển sang giao diện tối',
              onPressed: _toggleTheme,
              icon: Icon(
                _dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
            ),
            initialDestinationId: 'dashboard',
            showMoreTab: false,
            bottomNavigationBuilder: (context, selectedIndex, onSelected) =>
                LandlordBottomNavigation(
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                ),
            onPreviewRoleSelected: widget.onPreviewRoleSelected,
            onLogout: widget.onLogout,
            pageBuilder:
                widget.pageBuilder ??
                (context, destination) {
                  final persistence = AppPersistence.current;
                  if (RentalPortfolio.instance.stores.isEmpty &&
                      persistence != null &&
                      !persistence.initialSyncCompleted) {
                    return Center(
                      child: persistence.initialSyncFailed
                          ? FilledButton.icon(
                              onPressed: persistence.retryInitialSync,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử tải lại dữ liệu'),
                            )
                          : const CircularProgressIndicator(),
                    );
                  }
                  if (RentalPortfolio.instance.stores.isEmpty &&
                      destination.id != 'dashboard' &&
                      destination.id != 'properties') {
                    return const LandlordPropertiesPage();
                  }
                  if (destination.id == 'rooms') {
                    return LandlordRoomsPage(
                      showHeader: true,
                      dark: _dark,
                      onToggleTheme: _toggleTheme,
                    );
                  }
                  if (destination.id == 'properties') {
                    return LandlordPropertiesPage(profileName: displayName);
                  }
                  if (destination.id == 'dashboard') {
                    return LandlordTongQuanPage(profileName: displayName);
                  }
                  if (destination.id == 'billing') {
                    return LandlordBillingPage(profileName: displayName);
                  }
                  if (destination.id == 'conversations') {
                    return LandlordDanhSachTinNhanPage(
                      profileName: displayName,
                    );
                  }
                  if (destination.id == 'announcements') {
                    return LandlordAnnouncementsPage(
                      showHeader: true,
                      dark: _dark,
                      onToggleTheme: _toggleTheme,
                    );
                  }
                  return buildLandlordPage(context, destination);
                },
            tabs: landlordTabs,
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
                label: 'Thông báo',
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
        },
      ),
    );
  }
}
