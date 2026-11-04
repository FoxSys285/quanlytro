import 'package:flutter/material.dart';

import '../shared/announcements/announcement_store.dart';
import '../shared/rental/tenant_session.dart';
import 'announcements/tenant_announcements_page.dart';
import 'tenant_detail_ui.dart';
import 'tenant_ui.dart';

class TenantNotificationButton extends StatelessWidget {
  const TenantNotificationButton({
    super.key,
    this.onPressed,
    this.notifications,
    this.tenantId,
  });
  final VoidCallback? onPressed;
  final AnnouncementStore? notifications;
  final String? tenantId;

  @override
  Widget build(BuildContext context) {
    final inbox = notifications ?? AnnouncementStore.instance;
    final recipient = tenantId ?? TenantSession.currentTenantId;
    return ListenableBuilder(
      listenable: inbox,
      builder: (context, _) {
        final unread = inbox
            .forTenant(recipient)
            .any((item) => !inbox.isRead(item.id, recipient));
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              key: const ValueKey('tenant-appbar-notifications'),
              tooltip: 'Thông báo',
              onPressed:
                  onPressed ??
                  () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => TenantSubpageScaffold(
                        title: 'Thông báo',
                        showNotifications: false,
                        child: TenantAnnouncementsPage(
                          store: inbox,
                          tenantId: recipient,
                        ),
                      ),
                    ),
                  ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: tenantInk,
              ),
              icon: const Icon(Icons.notifications_none_rounded, size: 25),
            ),
            if (unread)
              Positioned(
                right: 3,
                top: 2,
                child: Container(
                  key: const ValueKey('tenant-appbar-notification-dot'),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6373E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
