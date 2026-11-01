import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import '../shared/help/help_page.dart';
import '../shared/settings/account_settings_page.dart';
import '../shared/profile/account_profile_page.dart';
import '../shared/notifications/notification_settings_page.dart';
import 'announcements/tenant_announcements_page.dart';
import 'conversations/tenant_danhsachtinnhan_page.dart';
import 'discovery/tenant_discovery_page.dart';
import 'incidents/tenant_baosuco_page.dart';
import 'invoices/tenant_invoices_page.dart';
import 'leases/tenant_home_page.dart';
import 'members/tenant_members_page.dart';
import 'tenant_ui.dart';
import '../shared/rental/tenant_session.dart';
import 'viewings/tenant_viewings_page.dart';

Widget buildTenantPage(BuildContext context, RoleDestination destination) {
  return switch (destination.id) {
    'support' => const HelpPage(role: AppRole.tenant),
    'settings' => const AccountSettingsPage(role: AppRole.tenant),
    'profile' => const AccountProfilePage(role: AppRole.tenant),
    'notifications' => const NotificationSettingsPage(role: AppRole.tenant),
    'discovery' => TenantDiscoveryPage(tenantId: TenantSession.currentTenantId),
    'viewings' => TenantViewingsPage(tenantId: TenantSession.currentTenantId),
    'my_lease' => TenantHomePage(tenantId: TenantSession.currentTenantId),
    'members' => TenantMembersPage(tenantId: TenantSession.currentTenantId),
    'announcements' => TenantAnnouncementsPage(
      tenantId: TenantSession.currentTenantId,
    ),
    'invoices' => TenantInvoicesPage(tenantId: TenantSession.currentTenantId),
    'conversations' => const TenantDanhSachTinNhanPage(),
    'incidents' => TenantBaoSuCoPage(tenantId: TenantSession.currentTenantId),
    _ => _TenantSecondaryPage(destination: destination),
  };
}

class _TenantSecondaryPage extends StatelessWidget {
  const _TenantSecondaryPage({required this.destination});
  final RoleDestination destination;

  @override
  Widget build(BuildContext context) => TenantPageFrame(
    children: [
      TenantPageTitle(
        title: destination.label,
        subtitle: 'Không gian người thuê trên Ứng dụng thuê trọ.',
      ),
      TenantSurface(
        padding: const EdgeInsets.fromLTRB(23, 28, 23, 28),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: tenantGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(destination.icon, color: tenantGreen, size: 27),
              ),
              const SizedBox(height: 14),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Màn hình này sẽ được thiết kế ở bước tiếp theo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: tenantMuted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
