import 'package:flutter/material.dart';

import '../../landlord_ui.dart';
import '../models/landlord_room.dart';

class LandlordRoomCard extends StatelessWidget {
  const LandlordRoomCard({super.key, required this.details});
  final LandlordRoomDetails details;

  @override
  Widget build(BuildContext context) {
    final room = details.room;
    final statusColor = switch (details.status) {
      LandlordRoomStatus.vacant => const Color(0xFF16836F),
      LandlordRoomStatus.occupied => landlordBlue,
      LandlordRoomStatus.upcoming => const Color(0xFF946000),
    };
    return LandlordCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: landlordBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: landlordBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${room.code}',
                      style: const TextStyle(
                        color: landlordInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tầng ${room.floor}',
                      style: const TextStyle(
                        color: landlordMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LandlordStatusPill(details.status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${details.typeName} · ${room.area} m² · Tối đa ${room.capacity} người',
            style: const TextStyle(color: landlordMuted, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            details.monthlyRent == null
                ? 'Chưa có giá thuê'
                : '${formatLandlordMoney(details.monthlyRent!)} / tháng',
            style: const TextStyle(
              color: landlordBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details.lease == null ? 'Giá theo loại phòng' : 'Giá theo hợp đồng',
            style: const TextStyle(color: landlordMuted, fontSize: 11),
          ),
          const Divider(height: 28, color: landlordLine),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline, size: 20, color: landlordMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  details.lease == null
                      ? 'Chưa có người thuê'
                      : '${details.lease!.tenantName} · ${details.lease!.occupantCount} người',
                  style: const TextStyle(
                    color: landlordInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
