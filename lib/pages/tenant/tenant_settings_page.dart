import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import '../shared/settings/account_settings_page.dart';
import 'tenant_detail_ui.dart';

class TenantSettingsPage extends StatelessWidget {
  const TenantSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const TenantSubpageScaffold(
    title: 'Cài đặt',
    child: AccountSettingsPage(role: AppRole.tenant, showPageTitle: false),
  );
}
