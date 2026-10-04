import 'package:flutter/material.dart';

import '../../../tenant/discovery/models/tenant_room_listing.dart';

const landlordPropertyBlue = Color(0xFF3769D6);

String _money(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} đ';

class LandlordPropertyCard extends StatelessWidget {
  const LandlordPropertyCard({super.key, required this.room});
  final TenantRoomListing room;

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(room.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(room.address),
              const SizedBox(height: 8),
              Text('${room.ward}, ${room.city}'),
              const Divider(height: 28),
              Text('Loại phòng: ${room.roomType}'),
              Text('Diện tích: ${room.size}'),
              Text('Giá thuê: ${_money(room.price)}/tháng'),
              Text('Điện: ${_money(room.electricityPrice)}/kWh'),
              Text(
                'Nước: ${_money(room.waterPrice)}/${room.waterType == 'Theo tháng' ? 'tháng' : 'm³'}',
              ),
              Text('Đánh giá: ${room.rating}/5'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final tag in room.tags) Chip(label: Text(tag))],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgrounds = [
      Color(0xFFDCE8FC),
      Color(0xFFF3E5D5),
      Color(0xFFDDEEE7),
    ];
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            color: backgrounds[room.variant % backgrounds.length],
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    room.roomType,
                    style: const TextStyle(
                      color: Color(0xFF344252),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.apartment_rounded,
                  size: 70,
                  color: landlordPropertyBlue.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Text(
                    room.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${_money(room.price)} / tháng',
                  style: const TextStyle(
                    color: landlordPropertyBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Text(room.size),
                    Text(
                      '★ ${room.rating}',
                      style: const TextStyle(color: Color(0xFFB9780C)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Điện: ${_money(room.electricityPrice)}/kWh',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Nước: ${_money(room.waterPrice)}/${room.waterType == 'Theo tháng' ? 'tháng' : 'm³'}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetails(context),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Xem chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: landlordPropertyBlue,
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
