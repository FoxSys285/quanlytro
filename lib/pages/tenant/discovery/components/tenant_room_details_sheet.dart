import '../../../../data/admin_store.dart';

import 'package:flutter/material.dart';

import '../models/tenant_room_listing.dart';
import '../../tenant_ui.dart';
import '../../../shared/media/room_photo_gallery.dart';
import '../../../shared/widgets/google_maps_actions.dart';
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
    RentalPortfolio.instance.addListener(_refresh);
    AdminStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    RentalPortfolio.instance.removeListener(_refresh);
    AdminStore.instance.removeListener(_refresh);
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
                  child: RoomPhotoGallery(
                    photos: _room.gallery,
                    label: _room.name,
                    height: 225,
                    interactive: true,
                    topRight: IconButton.filledTonal(
                      tooltip: _isFavorite ? 'Bỏ yêu thích' : 'Lưu tin',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: tenantGreen,
                      ),
                      onPressed: () {
                        widget.onFavoriteToggle();
                        setState(() => _isFavorite = !_isFavorite);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ảnh theo loại phòng · ${_room.roomType}',
                  style: const TextStyle(color: tenantMuted, fontSize: 11),
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
                GoogleMapsActions(
                  address: [
                    _room.address,
                    _room.ward,
                    _room.city,
                  ].where((part) => part.trim().isNotEmpty).join(', '),
                ),
                const SizedBox(height: 15),
                TenantSurface(
                  child: Column(
                    children: [
                      TenantDataRow(label: 'Diện tích', value: _room.size),
                      if (_room.capacity != null)
                        TenantDataRow(
                          label: 'Sức chứa',
                          value: '${_room.capacity} người',
                        ),
                      const TenantThinDivider(),
                      if (_room.distance.isNotEmpty)
                        TenantDataRow(
                          label: 'Khoảng cách',
                          value: _room.distance,
                        ),
                      if (_room.rating != '—') const TenantThinDivider(),
                      if (_room.rating != '—')
                        TenantDataRow(
                          label: 'Đánh giá',
                          value: '★ ${_room.rating} / 5',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const TenantSectionHeading('Bảng giá & dịch vụ'),
                TenantSurface(
                  child: Column(
                    children: [
                      TenantDataRow(
                        label: 'Giá thuê phòng',
                        value: '${formatTenantMoney(_room.price)} / tháng',
                        emphasized: true,
                      ),
                      for (final service in _room.priceList) ...[
                        const TenantThinDivider(),
                        TenantDataRow(
                          label: service.name,
                          value:
                              '${formatTenantMoney(service.price)}'
                              '${service.unit.isEmpty ? '' : ' / ${service.unit}'}'
                              '${service.basis.isEmpty ? '' : ' · ${service.basis}'}',
                        ),
                      ],
                      if (_room.priceList.isEmpty) ...[
                        const TenantThinDivider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Chủ nhà chưa cập nhật dịch vụ cho phòng này.',
                              style: TextStyle(
                                color: tenantMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
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
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: tenantLine)),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: FilledButton.icon(
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
            ),
          ),
        ],
      ),
    );
  }
}
