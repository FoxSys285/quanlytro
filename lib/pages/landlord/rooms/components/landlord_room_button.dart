import 'package:flutter/material.dart';

import '../../landlord_ui.dart';
import '../models/landlord_room.dart';

class LandlordRoomButton extends StatelessWidget {
  const LandlordRoomButton({
    super.key,
    required this.details,
    required this.onTap,
  });
  final LandlordRoomDetails details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (details.status) {
      LandlordRoomStatus.vacant => const Color(0xFF16836F),
      LandlordRoomStatus.occupied => landlordBlue,
      LandlordRoomStatus.upcoming => const Color(0xFF946000),
    };
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.06),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        children: [
          const Icon(Icons.meeting_room_outlined, size: 28),
          const SizedBox(height: 8),
          Text(
            'Phòng ${details.room.code}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            details.status.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
