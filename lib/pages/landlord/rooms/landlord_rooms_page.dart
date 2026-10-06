import 'package:flutter/material.dart';

import '../landlord_demo_store.dart';
import '../landlord_ui.dart';
import 'components/landlord_room_card.dart';
import 'models/landlord_room.dart';

class LandlordRoomsPage extends StatefulWidget {
  const LandlordRoomsPage({super.key, this.store});
  final LandlordDemoStore? store;
  @override
  State<LandlordRoomsPage> createState() => _LandlordRoomsPageState();
}

class _LandlordRoomsPageState extends State<LandlordRoomsPage> {
  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
  String _query = '';
  int? _floor;
  LandlordRoomStatus? _status;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final all = _store.roomDetails;
      final floors = all.map((item) => item.room.floor).toSet().toList()
        ..sort();
      final query = _query.trim().toLowerCase();
      final rooms = all
          .where(
            (item) =>
                '${item.room.code} ${item.typeName} ${item.lease?.tenantName ?? ''}'
                    .toLowerCase()
                    .contains(query) &&
                (_floor == null || item.room.floor == _floor) &&
                (_status == null || item.status == _status),
          )
          .toList();
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Danh sách phòng trọ',
            subtitle: '${_store.property.name} · ${_store.property.address}',
          ),
          LandlordCard(
            child: Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                Text(
                  '${all.length} phòng',
                  style: const TextStyle(
                    color: landlordInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${all.where((item) => item.status == LandlordRoomStatus.occupied).length} đang thuê',
                  style: const TextStyle(
                    color: landlordBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${all.where((item) => item.status == LandlordRoomStatus.vacant).length} phòng trống',
                  style: const TextStyle(
                    color: Color(0xFF16836F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (all.any(
                  (item) => item.status == LandlordRoomStatus.upcoming,
                ))
                  Text(
                    '${all.where((item) => item.status == LandlordRoomStatus.upcoming).length} sắp nhận phòng',
                    style: const TextStyle(
                      color: Color(0xFF946000),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Tìm mã phòng, loại phòng hoặc người thuê',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<int>(
              initialValue: _floor,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tầng',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int>(child: Text('Tất cả các tầng')),
                for (final floor in floors)
                  DropdownMenuItem(value: floor, child: Text('Tầng $floor')),
              ],
              onChanged: (value) => setState(() => _floor = value),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final status in LandlordRoomStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: _status == status,
                  onSelected: (value) =>
                      setState(() => _status = value ? status : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${rooms.length} phòng phù hợp',
            style: const TextStyle(
              color: landlordInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (rooms.isEmpty)
            const LandlordEmptyState(
              message: 'Không có phòng phù hợp với bộ lọc.',
            ),
          for (final room in rooms)
            LandlordRoomCard(key: ValueKey(room.room.code), details: room),
        ],
      );
    },
  );
}
