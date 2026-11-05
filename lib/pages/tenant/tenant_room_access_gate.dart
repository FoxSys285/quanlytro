import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../shared/profile/account_store.dart';
import 'discovery/tenant_favorites_page.dart';
import 'tenant_settings_page.dart';
import 'tenant_ui.dart';

/// Hides lease-specific tenant features until a non-draft lease links this
/// tenant account to a room. The portfolio listener opens the page as soon as
/// the landlord's change arrives from Firestore.
class TenantRoomAccessGate extends StatelessWidget {
  const TenantRoomAccessGate({
    super.key,
    required this.tenantId,
    required this.title,
    required this.child,
  });

  final String tenantId;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final portfolio = RentalPortfolio.instance;
    return ListenableBuilder(
      listenable: portfolio,
      builder: (context, _) {
        final hasRoomLink = portfolio.stores.any(
          (store) => store.leasesForTenant(tenantId).isNotEmpty,
        );
        if (hasRoomLink) return child;

        return TenantPageFrame(
          padding: EdgeInsets.zero,
          children: [
            TenantHeader(
              profileName: AccountStore.instance.profile(AppRole.tenant).name,
              onAvatarTap: () => Scaffold.maybeOf(context)?.openDrawer(),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TenantPageTitle(
                    title: title,
                    subtitle: 'Thông tin phòng trọ dành riêng cho bạn.',
                  ),
                  TenantEmptyState(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Bạn chưa được thêm vào phòng trọ',
                    subtitle:
                        'Hãy gửi mã người thuê $tenantId cho chủ trọ để họ tạo hợp đồng và liên kết bạn với phòng. Khi được thêm, mục “$title” sẽ hiển thị thông tin.',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
