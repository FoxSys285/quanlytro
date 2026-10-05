import 'package:flutter/material.dart';

import '../../../shared/viewings/components/viewing_status_badge.dart';
import '../../../shared/viewings/models/room_viewing.dart';
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tenantGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: tenantGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewing.roomName,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      viewing.address,
                      style: const TextStyle(
                        color: tenantMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ViewingStatusBadge(status: viewing.status),
          const Divider(height: 28, color: tenantLine),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: tenantGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  viewingDateLabel(viewing.startsAt),
                  style: const TextStyle(
                    color: tenantInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: tenantGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                viewingTimeLabel(viewing.startsAt),
                style: const TextStyle(
                  color: tenantGreenDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
