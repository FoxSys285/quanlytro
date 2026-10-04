import 'package:flutter/material.dart';

import '../../tenant/discovery/models/tenant_room_listing.dart';
import 'components/landlord_property_card.dart';

class LandlordPropertiesPage extends StatefulWidget {
  const LandlordPropertiesPage({super.key});

  @override
  State<LandlordPropertiesPage> createState() => _LandlordPropertiesPageState();
}

class _LandlordPropertiesPageState extends State<LandlordPropertiesPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _roomType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the same source as tenant discovery, including generated listings.
    final listings = TenantRoomDemoData.allListings;
    final types = listings.map((room) => room.roomType).toSet().toList();
    final query = _query.trim().toLowerCase();
    final visible = listings.where((room) {
      final text =
          '${room.name} ${room.address} ${room.city} ${room.ward} '
                  '${room.tags.join(' ')}'
              .toLowerCase();
      return text.contains(query) &&
          (_roomType == null || room.roomType == _roomType);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.all(constraints.maxWidth < 600 ? 18 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh sách nhà trọ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Theo dõi thông tin nhà trọ, giá thuê và tiện ích.',
                  style: TextStyle(color: Color(0xFF74818C)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Summary(
                      label: 'Tin nhà trọ',
                      value: '${listings.length}',
                      icon: Icons.home_work_outlined,
                    ),
                    _Summary(
                      label: 'Loại phòng',
                      value: '${types.length}',
                      icon: Icons.meeting_room_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, địa chỉ hoặc tiện ích',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE7ECEF)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _roomType == null,
                      onSelected: (_) => setState(() => _roomType = null),
                    ),
                    for (final type in types)
                      ChoiceChip(
                        label: Text(type),
                        selected: _roomType == type,
                        onSelected: (selected) =>
                            setState(() => _roomType = selected ? type : null),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '${visible.length} kết quả',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Không tìm thấy nhà trọ phù hợp.'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, listConstraints) {
                      final columns = listConstraints.maxWidth >= 900
                          ? 3
                          : listConstraints.maxWidth >= 600
                          ? 2
                          : 1;
                      final width =
                          (listConstraints.maxWidth - (columns - 1) * 16) /
                          columns;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final room in visible)
                            SizedBox(
                              width: width,
                              child: LandlordPropertyCard(room: room),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Dữ liệu mẫu dùng chung với Khám phá nhà trọ của người thuê.',
                  style: TextStyle(color: Color(0xFF74818C), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 155,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: landlordPropertyBlue),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: Color(0xFF74818C))),
      ],
    ),
  );
}
