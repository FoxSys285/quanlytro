import 'package:flutter/material.dart';

import '../models/tenant_room_listing.dart';
import 'tenant_room_artwork.dart';
import '../../tenant_ui.dart';

class TenantRoomDetailsSheet extends StatefulWidget {
  const TenantRoomDetailsSheet({
    required this.room,
    required this.onBook,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final TenantRoomListing room;
  final VoidCallback onBook;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  State<TenantRoomDetailsSheet> createState() => TenantRoomDetailsSheetState();
}

class TenantRoomDetailsSheetState extends State<TenantRoomDetailsSheet> {
  late bool _isFavorite = widget.isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: tenantCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const TenantSheetHandle(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: TenantRoomArtwork(
                    variant: widget.room.variant,
                    height: 175,
                    isFavorite: _isFavorite,
                    onFavoriteTap: () {
                      widget.onFavoriteToggle();
                      setState(() => _isFavorite = !_isFavorite);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.room.name,
                  style: const TextStyle(
                    color: tenantInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.room.address,
                  style: const TextStyle(color: tenantMuted, fontSize: 12),
                ),
                const SizedBox(height: 15),
                TenantSurface(
                  child: Column(
                    children: [
                      TenantDataRow(
                        label: 'Giá thuê',
                        value:
                            '${formatTenantMoney(widget.room.price)} / tháng',
                        emphasized: true,
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Diện tích',
                        value: widget.room.size,
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Khoảng cách',
                        value: widget.room.distance,
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Tiền điện',
                        value:
                            '${formatTenantMoney(widget.room.electricityPrice)}/kWh',
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Tiền nước',
                        value: widget.room.waterType == 'Theo tháng'
                            ? '${formatTenantMoney(widget.room.waterPrice)}/tháng'
                            : '${formatTenantMoney(widget.room.waterPrice)}/m³',
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Đánh giá',
                        value: '★ ${widget.room.rating} / 5',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const TenantSectionHeading('Tiện nghi nổi bật'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in widget.room.tags) TenantFeatureTag(tag),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Không gian sáng thoáng, khu vực an ninh và thuận tiện di chuyển. Liên hệ để xem phòng trực tiếp.',
                  style: TextStyle(
                    color: tenantMuted,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onBook();
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Đặt lịch xem phòng'),
                  style: FilledButton.styleFrom(
                    backgroundColor: tenantGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
