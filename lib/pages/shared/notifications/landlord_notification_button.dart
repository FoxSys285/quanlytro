import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../landlord/landlord_demo_store.dart';
import '../announcements/announcement_store.dart';

class LandlordNotificationButton extends StatelessWidget {
  const LandlordNotificationButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      RentalPortfolio.instance,
      AdminStore.instance,
    ]),
    builder: (context, _) {
      final inboxes = [
        for (final rental in RentalPortfolio.instance.stores)
          AnnouncementStore.forRental(rental),
      ];
      return ListenableBuilder(
        listenable: Listenable.merge(inboxes),
        builder: (context, _) {
          final unread = inboxes.any(
            (inbox) => inbox.inbox.any(
              (item) =>
                  !item.isRead &&
                  (inbox.rental.property.id ==
                          LandlordDemoStore.activeInstance.property.id ||
                      item.id.startsWith('verification-review:')),
            ),
          );
          return IconButton(
            tooltip: 'Thông báo',
            onPressed: onPressed,
            icon: Badge(
              key: const ValueKey('landlord-notification-badge'),
              isLabelVisible: unread,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          );
        },
      );
    },
  );
}
