import 'package:flutter/material.dart';

import '../landlord_theme.dart';
import 'landlord_properties_page.dart';

class LandlordOnboardingPage extends StatelessWidget {
  const LandlordOnboardingPage({
    super.key,
    this.onLogout,
    this.loading = false,
    this.loadFailed = false,
    this.onRetry,
  });

  final VoidCallback? onLogout;
  final bool loading;
  final bool loadFailed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Thiết lập tài khoản chủ trọ'),
        actions: [
          if (onLogout != null)
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadFailed
          ? Center(
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử tải lại dữ liệu'),
              ),
            )
          : const LandlordPropertiesPage(),
    );
  }
}
