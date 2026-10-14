import 'package:flutter/material.dart';

import '../models/tenant_room_listing.dart';
import 'tenant_room_artwork.dart';
import '../../tenant_ui.dart';
import '../../../landlord/properties/components/landlord_property_image.dart';
import '../../../landlord/landlord_demo_store.dart';

class TenantRoomDetailsSheet extends StatefulWidget {
  const TenantRoomDetailsSheet({
    super.key,
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
  TenantRoomListing get _room {
    for (final room in TenantRoomDemoData.allListings) {
      if (room.id == widget.room.id) return room;
    }
    return widget.room;
  }

  bool get _available =>
      widget.room.roomCode == null ||
      TenantRoomDemoData.allListings.any((room) => room.id == widget.room.id);
  @override
  void initState() {
    super.initState();
    LandlordDemoStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LandlordDemoStore.instance.removeListener(_refresh);
    super.dispose();
  }

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
                  child: _room.imageBytes != null || _room.imageUrl.isNotEmpty
                      ? LandlordPropertyImage(
                          bytes: _room.imageBytes,
                          url: _room.imageUrl,
                          height: 175,
                        )
                      : TenantRoomArtwork(
                          variant: _room.variant,
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
                  _room.name,
                  style: const TextStyle(
                    color: tenantInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _room.address,
                  style: const TextStyle(color: tenantMuted, fontSize: 12),
                ),
                const SizedBox(height: 15),
                TenantSurface(
                  child: Column(
                    children: [
                      TenantDataRow(
                        label: 'Giá thuê',
                        value: '${formatTenantMoney(_room.price)} / tháng',
                        emphasized: true,
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(label: 'Diện tích', value: _room.size),
                      if (_room.capacity != null)
                        TenantDataRow(
                          label: 'Sức chứa',
                          value: '${_room.capacity} người',
                        ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Khoảng cách',
                        value: _room.distance,
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Tiền điện',
                        value:
                            '${formatTenantMoney(_room.electricityPrice)}/kWh',
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Tiền nước',
                        value: _room.waterType == 'Theo tháng'
                            ? '${formatTenantMoney(_room.waterPrice)}/tháng'
                            : '${formatTenantMoney(_room.waterPrice)}/m³',
                      ),
                      const TenantThinDivider(),
                      TenantDataRow(
                        label: 'Đánh giá',
                        value: '★ ${_room.rating} / 5',
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
                    for (final tag in _room.tags) TenantFeatureTag(tag),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _room.description.isEmpty
                      ? 'Liên hệ để xem phòng trực tiếp.'
                      : _room.description,
                  style: TextStyle(
                    color: tenantMuted,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: !_available
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onBook();
                        },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    _available ? 'Đặt lịch xem phòng' : 'Phòng không còn trống',
                  ),
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
