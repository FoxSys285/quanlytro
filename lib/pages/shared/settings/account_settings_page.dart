import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import '../notifications/notification_settings_page.dart';
import '../profile/account_profile_page.dart';
import '../auth/change_password_page.dart';
import '../../../data/local_auth.dart';
import '../../../data/app_persistence.dart';
import '../auth/phone_login_page.dart';
import '../profile/contact_details.dart';
import '../../tenant/tenant_detail_ui.dart';
import '../../tenant/tenant_ui.dart';
import '../../tenant/tenant_feature_ui.dart';
import '../profile/account_store.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({
    super.key,
    required this.role,
    this.showPageTitle = true,
  });

  final AppRole role;
  final bool showPageTitle;

  Future<void> _linkPhone(BuildContext context) async {
    final auth = LocalAuth.instance;
    final session = auth.session;
    final result = await Navigator.of(context).push<PhoneLoginResult>(
      MaterialPageRoute(
        builder: (_) => PhoneLoginPage(
          linkToCurrentUser: true,
          initialPhone: session?.phoneIsSynthetic == true
              ? ''
              : session?.phoneNumber ?? '',
        ),
      ),
    );
    if (result != PhoneLoginResult.linked || !context.mounted) return;
    final updated = auth.session;
    if (updated == null) return;
    try {
      final contact = AccountStore.instance.profile(role);
      AccountStore.instance.saveProfile(
        role,
        ContactDetails(
          name: contact.name,
          phone: updated.phoneNumber,
          email: contact.email,
          address: contact.address,
        ),
      );
      await AppPersistence.current?.saveChanges();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã liên kết. Bạn có thể đăng nhập bằng số điện thoại và OTP.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã liên kết số đăng nhập. Thông tin liên hệ đang chờ đồng bộ.',
            ),
          ),
        );
      }
    }
  }

  Widget _phoneOption(BuildContext context) => ListTile(
    leading: const Icon(
      Icons.phonelink_lock_outlined,
      color: Color(0xFF009B65),
    ),
    title: const Text('Liên kết số điện thoại'),
    subtitle: const Text('Xác minh OTP để đăng nhập vào cùng tài khoản'),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => _linkPhone(context),
  );

  void _open(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => role == AppRole.tenant
            ? TenantSubpageScaffold(title: title, child: page)
            : Scaffold(
                appBar: AppBar(title: Text(title)),
                body: SafeArea(child: page),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (role == AppRole.tenant) return _tenantSettings(context);
    final color = role == AppRole.tenant
        ? const Color(0xFF08A94F)
        : landlordBlue;
    return LandlordPageFrame(
      children: [
        if (showPageTitle)
          LandlordPageTitle(
            title: 'Cài đặt',
            subtitle: 'Quản lý hồ sơ và thông báo ứng dụng của bạn.',
          ),
        LandlordCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (LocalAuth.instance.isCloudMode &&
                  LocalAuth.instance.session != null) ...[
                _phoneOption(context),
                const Divider(height: 1),
              ],
              if (LocalAuth.instance.role != null) ...[
                ListTile(
                  leading: Icon(Icons.lock_outline, color: color),
                  title: const Text('Đổi mật khẩu'),
                  subtitle: const Text(
                    'Cập nhật mật khẩu đăng nhập trên thiết bị',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(
                    context,
                    'Đổi mật khẩu',
                    ChangePasswordPage(role: role),
                  ),
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: Icon(Icons.person_outline_rounded, color: color),
                title: const Text('Hồ sơ cá nhân'),
                subtitle: const Text('Xem và chỉnh sửa thông tin tài khoản'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(
                  context,
                  'Hồ sơ cá nhân',
                  AccountProfilePage(role: role),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.notifications_none_rounded, color: color),
                title: const Text('Thông báo ứng dụng'),
                subtitle: const Text('Tùy chọn nhận thông báo'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(
                  context,
                  'Thông báo ứng dụng',
                  NotificationSettingsPage(role: role),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tenantSettings(BuildContext context) => TenantFeatureFrame(
    artwork: TenantFeatureArtwork.settings,
    title: 'Cài đặt tài khoản',
    subtitle: 'Thông tin cá nhân, bảo mật và thông báo của bạn.',
    children: [
      ListenableBuilder(
        listenable: AccountStore.instance,
        builder: (context, _) {
          final profile = AccountStore.instance.profile(role);
          return TenantSurface(
            child: Row(
              children: [
                TenantProfileAvatar(name: profile.name, radius: 27),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Tài khoản người thuê',
                        style: TextStyle(color: tenantMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 24),
      const TenantSectionHeading('Tài khoản & bảo mật'),
      TenantSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            if (LocalAuth.instance.isCloudMode &&
                LocalAuth.instance.session != null) ...[
              _phoneOption(context),
              const Divider(height: 1, indent: 70, endIndent: 16),
            ],
            _tenantOption(
              context,
              Icons.person_outline_rounded,
              'Hồ sơ cá nhân',
              'Xem và chỉnh sửa thông tin tài khoản',
              AccountProfilePage(role: role),
            ),
            const Divider(height: 1, indent: 70, endIndent: 16),
            _tenantOption(
              context,
              Icons.lock_outline_rounded,
              'Đổi mật khẩu',
              'Cập nhật mật khẩu đăng nhập của bạn',
              const ChangePasswordPage(role: AppRole.tenant),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const TenantSectionHeading('Tùy chọn ứng dụng'),
      TenantSurface(
        padding: EdgeInsets.zero,
        child: _tenantOption(
          context,
          Icons.notifications_none_rounded,
          'Thông báo ứng dụng',
          'Quản lý tùy chọn nhận thông báo',
          NotificationSettingsPage(role: role),
        ),
      ),
      const SizedBox(height: 22),
      const TenantFeatureBanner(
        icon: Icons.manage_accounts_rounded,
        title: 'Không gian cá nhân của bạn',
        subtitle: 'Cập nhật thông tin để giữ kết nối với chủ trọ và quản lý chỗ ở thuận tiện hơn.',
      ),
    ],
  );

  Widget _tenantOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget page,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    leading: TenantDetailIcon(icon),
    title: Text(
      title,
      style: const TextStyle(
        color: tenantInk,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle,
        style: const TextStyle(color: tenantMuted, fontSize: 11, height: 1.4),
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: tenantMuted,
      size: 21,
    ),
    onTap: () => _open(context, title, page),
  );
}
