import 'package:flutter/material.dart';

import '../../landlord_ui.dart';
import '../models/landlord_room.dart';
import '../../../shared/media/room_photo_gallery.dart';
import '../../room_types/models/landlord_room_type.dart';

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
        padding: EdgeInsets.zero,
        foregroundColor: color,
        backgroundColor: Colors.white,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: SizedBox(
              height: 104,
              width: double.infinity,
              child: details.type?.photos.firstOrNull == null
                  ? const RoomPhotoPlaceholder()
                  : RoomPhotoImage(
                      photo: details.type!.photos.first,
                      label: 'Ảnh ${details.typeName}',
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng ${details.room.code}',
                  style: const TextStyle(
                    color: landlordInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${details.room.area} m² · ${details.room.capacity} người',
                  style: const TextStyle(color: landlordMuted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                if (details.monthlyRent != null)
                  Text(
                    formatRoomTypePrice(details.monthlyRent!),
                    style: const TextStyle(
                      color: landlordInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        details.status.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
