import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import '../profile/account_store.dart';
import '../../tenant/tenant_detail_ui.dart';
import '../../tenant/tenant_ui.dart';
import '../../tenant/tenant_feature_ui.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key, required this.role, this.store});
  final AppRole role;
  final AccountStore? store;
  @override
  Widget build(BuildContext context) {
    final accounts = store ?? AccountStore.instance;
    final color = role == AppRole.tenant
        ? const Color(0xFF16836F)
        : landlordBlue;
    return ListenableBuilder(
      listenable: accounts,
      builder: (context, _) {
        final enabled = accounts.notificationsEnabled(role);
        if (role == AppRole.tenant || role == AppRole.landlord) {
          final isLandlord = role == AppRole.landlord;
          return TenantFeatureFrame(
            artwork: isLandlord
                ? TenantFeatureArtwork.landlordSettings
                : TenantFeatureArtwork.settings,
            title: 'Thông báo ứng dụng',
            subtitle: isLandlord
                ? 'Chủ động theo dõi thông báo về nhà trọ và người thuê.'
                : 'Chủ động quản lý thông báo trong tài khoản của bạn.',
            children: [
              const TenantSectionHeading('Tùy chọn thông báo'),
              TenantSurface(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text(
                    'Cho phép nhận thông báo',
                    style: TextStyle(
                      color: tenantInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      enabled
                          ? 'Đang bật thông báo ứng dụng'
                          : 'Đã tắt thông báo ứng dụng',
                      style: const TextStyle(
                        color: tenantMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  activeThumbColor: isLandlord
                      ? TenantUiColors.landlord.primary
                      : TenantUiColors.tenant.primary,
                  value: enabled,
                  onChanged: (value) =>
                      accounts.setNotificationsEnabled(role, value),
                ),
              ),
              const SizedBox(height: 18),
              TenantSurface(
                child: Row(
                  children: [
                    TenantDetailIcon(
                      enabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        enabled
                            ? 'Thông báo ứng dụng đang được bật cho tài khoản của bạn.'
                            : 'Bạn có thể bật lại thông báo bất cứ lúc nào.',
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const TenantDetailNote(
                'Thay đổi tùy chọn không xóa các thông báo đã nhận.',
              ),
              const SizedBox(height: 20),
              TenantFeatureBanner(
                icon: Icons.notifications_active_outlined,
                title: isLandlord
                    ? 'Theo dõi hoạt động nhà trọ'
                    : 'Theo dõi thông tin chỗ ở',
                subtitle: isLandlord
                    ? 'Nhận cập nhật về hóa đơn, thanh toán và yêu cầu sửa chữa.'
                    : 'Nhận cập nhật về hóa đơn, lịch xem phòng và các yêu cầu hỗ trợ.',
              ),
            ],
          );
        }
        return LandlordPageFrame(
          children: [
            LandlordPageTitle(
              title: 'Thông báo ứng dụng',
              subtitle:
                  'Tùy chọn nhận thông báo của ${role.label.toLowerCase()}.',
            ),
            LandlordCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text('Cho phép nhận thông báo'),
                subtitle: Text(
                  enabled
                      ? 'Đang bật thông báo ứng dụng'
                      : 'Đã tắt thông báo ứng dụng',
                ),
                secondary: Icon(
                  enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: color,
                ),
                activeThumbColor: color,
                value: enabled,
                onChanged: (value) =>
                    accounts.setNotificationsEnabled(role, value),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Thay đổi tùy chọn không xóa các thông báo đã nhận.',
                style: TextStyle(color: landlordMuted, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
