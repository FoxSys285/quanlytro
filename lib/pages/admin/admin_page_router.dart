import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import '../shared/help/support_tickets_page.dart';
import '../shared/notifications/notification_settings_page.dart';
import '../shared/profile/account_profile_page.dart';
import '../shared/settings/account_settings_page.dart';
import '../../data/admin_store.dart';
import '../../data/local_auth.dart';
import 'admin_ui.dart';
import 'admin_users_page.dart';
import 'admin_commission_page.dart';
import 'admin_workspace_page.dart';

Widget buildAdminPage(BuildContext context, RoleDestination destination) =>
    switch (destination.id) {
      'users' => const AdminUsersPage(),
      'activity' => const AdminUsersPage(activity: true),
      'commissions' => const AdminCommissionPage(),
      'support' => const SupportTicketsPage(role: AppRole.admin),
      'profile' => const AccountProfilePage(role: AppRole.admin),
      'notifications' => const NotificationSettingsPage(role: AppRole.admin),
      'settings' => const _AdminSettings(),
      _ => AdminWorkspacePage(
        key: ValueKey(destination.id),
        destination: destination,
      ),
    };

class _AdminSettings extends StatelessWidget {
  const _AdminSettings();
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AdminStore.instance,
    builder: (context, _) => ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: AdminPanel(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tiếp nhận lịch xem phòng'),
              subtitle: const Text(
                'Cho phép người thuê gửi yêu cầu xem phòng mới.',
              ),
              value: AdminStore.instance.acceptingViewings,
              onChanged: LocalAuth.instance.role != AppRole.admin
                  ? null
                  : AdminStore.instance.setAcceptingViewings,
            ),
          ),
        ),
        const AccountSettingsPage(role: AppRole.admin),
      ],
    ),
  );
}
