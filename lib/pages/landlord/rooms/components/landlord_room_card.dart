import 'package:flutter/material.dart';

import '../../landlord_ui.dart';
import '../../landlord_theme.dart';
import '../models/landlord_room.dart';
import '../../../shared/media/room_photo_gallery.dart';

class LandlordRoomCard extends StatelessWidget {
  const LandlordRoomCard({
    super.key,
    required this.details,
    this.onEdit,
    this.onDelete,
  });
  final LandlordRoomDetails details;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final room = details.room;
    final statusColor = switch (details.status) {
      LandlordRoomStatus.vacant => const Color(0xFF16836F),
      LandlordRoomStatus.occupied => landlordBlue,
      LandlordRoomStatus.upcoming => const Color(0xFF946000),
    };
    final photos = details.type?.photos ?? const [];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07172B42),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoomPhotoGallery(
            photos: photos,
            label: 'Ảnh ${details.typeName} · Phòng ${room.code}',
            height: 185,
            onTap: () => showRoomPhotoViewer(
              context,
              photos: photos,
              title: 'Phòng ${room.code} · ${details.typeName}',
            ),
            topLeft: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    details.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.meeting_room_outlined,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phòng ${room.code}',
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tầng ${room.floor}',
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${details.typeName} · ${room.area} m² · Tối đa ${room.capacity} người',
                  style: TextStyle(color: palette.muted, height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  details.monthlyRent == null
                      ? 'Chưa có giá thuê'
                      : '${formatLandlordMoney(details.monthlyRent!)} / tháng',
                  style: const TextStyle(
                    color: landlordBlue,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details.lease == null
                      ? 'Giá theo loại phòng'
                      : 'Giá theo hợp đồng',
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
                Divider(height: 28, color: palette.line),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_outline, size: 20, color: palette.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        details.lease == null
                            ? 'Chưa có người thuê'
                            : '${details.lease!.tenantName} · ${details.lease!.occupantCount} người',
                        style: TextStyle(
                          color: palette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (onEdit != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Chỉnh sửa phòng'),
                      ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          tooltip: 'Xóa phòng ${room.code}',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
