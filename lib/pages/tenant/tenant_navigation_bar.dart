import 'package:flutter/material.dart';

import 'tenant_ui.dart';
import 'tenant_notification_button.dart';
import '../shared/announcements/announcement_store.dart';

class TenantNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TenantNavigationBar({
    super.key,
    required this.title,
    required this.onBack,
    this.onNotifications,
    this.notifications,
    this.tenantId,
    this.showNotifications = true,
  });
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onNotifications;
  final AnnouncementStore? notifications;
  final String? tenantId;
  final bool showNotifications;
  @override
  Size get preferredSize => const Size.fromHeight(58);
  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    return AppBar(
      toolbarHeight: 58,
      backgroundColor: colors.header,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: tenantInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filledTonal(
          tooltip: 'Quay lại',
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: tenantInk,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
      actions: [
        if (showNotifications)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: TenantNotificationButton(
              onPressed: onNotifications,
              notifications: notifications,
              tenantId: tenantId,
            ),
          )
        else
          const SizedBox(width: 56),
      ],
    );
  }
}
