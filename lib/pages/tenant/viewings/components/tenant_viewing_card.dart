import 'package:flutter/material.dart';

import '../../../shared/viewings/components/viewing_status_badge.dart';
import '../../../shared/viewings/models/room_viewing.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';

class TenantViewingCard extends StatelessWidget {
  const TenantViewingCard({super.key, required this.viewing});
  final RoomViewing viewing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TenantSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TenantDetailIcon(Icons.meeting_room_rounded, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewing.roomName,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: tenantGreenDark,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            viewing.address,
                            style: const TextStyle(
                              color: tenantMuted,
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ViewingStatusBadge(status: viewing.status),
              if (viewing.attendeeCount != null)
                TenantStatusPill(
                  '${viewing.attendeeCount} người xem',
                  color: tenantGreenDark,
                  icon: Icons.groups_outlined,
                ),
            ],
          ),
          const TenantThinDivider(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F9F5),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: tenantGreenDark,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewingDateLabel(viewing.startsAt),
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        viewingTimeLabel(viewing.startsAt),
                        style: const TextStyle(
                          color: tenantGreenDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (viewing.personalNeeds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 17, color: tenantMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewing.personalNeeds,
                    style: const TextStyle(
                      color: tenantMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
