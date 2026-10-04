import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import 'conversations/tenant_conversation_page.dart';
import 'discovery/tenant_discovery_page.dart';
import 'incidents/tenant_incidents_page.dart';
import 'invoices/tenant_invoices_page.dart';
import 'leases/tenant_home_page.dart';
import 'tenant_ui.dart';

Widget buildTenantPage(BuildContext context, RoleDestination destination) {
  return switch (destination.id) {
    'discovery' => const TenantDiscoveryPage(),
    'my_lease' => const TenantHomePage(),
    'invoices' => const TenantInvoicesPage(),
    'conversations' => const TenantLandlordConversationPage(),
    'incidents' => const TenantIncidentsPage(),
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
        subtitle: 'Không gian người thuê tại An Cư.',
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
