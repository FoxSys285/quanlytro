import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import '../profile/account_store.dart';

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
