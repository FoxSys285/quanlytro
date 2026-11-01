import 'package:flutter/material.dart';

import '../models/tenant_room_listing.dart';
import '../../tenant_ui.dart';
import '../../../shared/media/room_photo_gallery.dart';

class TenantRoomCard extends StatelessWidget {
  const TenantRoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final TenantRoomListing room;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B123B30),
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: tenantLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoomPhotoGallery(
                  photos: room.gallery,
                  label: 'Ảnh ${room.roomType} · ${room.name}',
                  height: 205,
                  topLeft: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: tenantGreen, size: 6),
                        SizedBox(width: 5),
                        Text(
                          'Còn phòng',
                          style: TextStyle(
                            color: tenantGreenDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  topRight: IconButton.filledTonal(
                    tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu tin',
                    onPressed: onFavoriteToggle,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .95),
                    ),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFD45B67)
                          : tenantGreenDark,
                      size: 21,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF5F1),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.meeting_room_outlined,
                                    size: 14,
                                    color: tenantGreenDark,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      room.roomType,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: tenantGreenDark,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            size: 18,
                            color: tenantGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        room.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: tenantMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              room.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: tenantMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            room.distance,
                            style: const TextStyle(
                              color: tenantMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _tinyFeature(
                            Icons.bolt_rounded,
                            '${formatTenantMoney(room.electricityPrice)}/kWh',
                            color: const Color(0xFFD18A22),
                          ),
                          _tinyFeature(
                            Icons.water_drop_outlined,
                            room.waterType == 'Theo tháng'
                                ? '${formatTenantMoney(room.waterPrice)}/tháng'
                                : '${formatTenantMoney(room.waterPrice)}/m³',
                            color: const Color(0xFF4784C7),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: tenantLine),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: formatTenantMoney(room.price),
                                    style: const TextStyle(
                                      color: tenantGreenDark,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' / tháng',
                                    style: TextStyle(
                                      color: tenantMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _tinyFeature(Icons.square_foot_rounded, room.size),
                          const SizedBox(width: 11),
                          if (room.rating != '—')
                            _tinyFeature(
                              Icons.star_rounded,
                              room.rating,
                              color: const Color(0xFFE6A426),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _tinyFeature(IconData icon, String label, {Color color = tenantMuted}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
