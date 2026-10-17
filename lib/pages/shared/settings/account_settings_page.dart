import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import '../notifications/notification_settings_page.dart';
import '../profile/account_profile_page.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key, required this.role});

  final AppRole role;

  void _open(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(child: page),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = role == AppRole.tenant
        ? const Color(0xFF16836F)
        : landlordBlue;
    return LandlordPageFrame(
      children: [
        LandlordPageTitle(
          title: 'Cài đặt',
          subtitle: 'Quản lý hồ sơ và thông báo ứng dụng của bạn.',
        ),
        LandlordCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
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
}
