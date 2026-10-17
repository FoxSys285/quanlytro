import 'package:flutter/material.dart';

import '../landlord_demo_store.dart';
import '../landlord_ui.dart';
import 'components/landlord_room_card.dart';
import 'models/landlord_room.dart';
import 'components/landlord_room_button.dart';
import '../../shared/rental/room_image_gallery.dart';
import '../finance/landlord_finance_models.dart';

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

  void _showRoom(String code) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final details = _store.roomDetails.firstWhere(
            (item) => item.room.code == code,
          );
          final lease = details.lease;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chi tiết phòng',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng chi tiết',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  RoomImageGallery(images: details.type?.images ?? const []),
                  const SizedBox(height: 12),
                  LandlordRoomCard(details: details),
                  Text(
                    _store.property.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(_store.property.address),
                  const SizedBox(height: 12),
                  Text(_store.property.description),
                  const SizedBox(height: 16),
                  if (lease != null) ...[
                    const Text(
                      'Hợp đồng & người thuê',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('Mã hợp đồng: ${lease.id}'),
                    Text('Liên hệ: ${lease.phone}'),
                    Text(
                      'Thời hạn: ${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
                    ),
                    Text('Đặt cọc: ${formatLandlordMoney(lease.deposit)}'),
                    Text('Thanh toán: ngày ${lease.dueDay} hằng tháng'),
                    Text(
                      'Điện: ${formatLandlordMoney(lease.electricityPrice)}/kWh',
                    ),
                    Text(
                      'Nước: ${formatLandlordMoney(lease.waterPrice)} · ${lease.waterType}',
                    ),
                    Text(
                      'Phí xe: ${formatLandlordMoney(lease.vehicleFee)}/tháng',
                    ),
                    Text(
                      'Dịch vụ: ${formatLandlordMoney(lease.serviceFee)}/tháng',
                    ),
                    const SizedBox(height: 12),
                    for (final member in _store.membersForLease(lease.id))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(member.name),
                        subtitle: Text(
                          '${member.phone} · ${member.isRepresentative ? 'Đại diện' : 'Thành viên'}',
                        ),
                      ),
                    if (lease.note.isNotEmpty) Text('Ghi chú: ${lease.note}'),
                  ] else ...[
                    const Text(
                      'Dịch vụ hiện tại',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    for (final service in _store.services.where(
                      (item) => item.active,
                    ))
                      Text(
                        '${service.name}: ${formatLandlordMoney(service.price)}/${service.unit}',
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
          for (final floor in floors)
            if (rooms.any((item) => item.room.floor == floor))
              LandlordCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined, color: landlordBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Tầng $floor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${rooms.where((item) => item.room.floor == floor).length} phòng',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth < 480
                            ? 2
                            : constraints.maxWidth < 720
                            ? 3
                            : 4;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final room in rooms.where(
                              (item) => item.room.floor == floor,
                            ))
                              SizedBox(
                                width: width,
                                child: LandlordRoomButton(
                                  key: ValueKey(room.room.code),
                                  details: room,
                                  onTap: () => _showRoom(room.room.code),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
        ],
      );
    },
  );
}
