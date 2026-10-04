import 'package:flutter/material.dart';

import 'components/landlord_viewing_card.dart';
import 'data/landlord_viewing_demo_data.dart';
import 'models/landlord_viewing.dart';

class LandlordViewingsPage extends StatefulWidget {
  const LandlordViewingsPage({super.key, this.viewings});

  // Supply database records here when the data source is connected.
  final List<LandlordViewing>? viewings;

  @override
  State<LandlordViewingsPage> createState() => _LandlordViewingsPageState();
}

class _LandlordViewingsPageState extends State<LandlordViewingsPage> {
  late final _demoViewings = LandlordViewingDemoData.create();
  String _query = '';
  ViewingStatus? _status;

  String _dateLabel(DateTime date) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ nhật',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final source = widget.viewings ?? _demoViewings;
    final ordered =
        source.where((viewing) {
          final text =
              '${viewing.customerName} ${viewing.phone} '
                      '${viewing.roomName} ${viewing.address} ${viewing.personalNeeds}'
                  .toLowerCase();
          return text.contains(query) &&
              (_status == null || viewing.status == _status);
        }).toList()..sort((a, b) {
          final timeOrder = a.startsAt.compareTo(b.startsAt);
          return timeOrder == 0 ? a.id.compareTo(b.id) : timeOrder;
        });
    final groups = <DateTime, List<LandlordViewing>>{};
    for (final viewing in ordered) {
      final date = viewing.startsAt;
      final day = DateTime(date.year, date.month, date.day);
      (groups[day] ??= []).add(viewing);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch xem phòng',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('Lịch hẹn được xếp từ sớm đến muộn theo ngày và giờ.'),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Tìm người đặt, số điện thoại, phòng hoặc nhu cầu',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
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
                  for (final status in ViewingStatus.values)
                    ChoiceChip(
                      label: Text(status.label),
                      selected: _status == status,
                      onSelected: (selected) =>
                          setState(() => _status = selected ? status : null),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${ordered.length} lịch hẹn',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (ordered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Không có lịch xem phòng phù hợp.'),
                  ),
                ),
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _dateLabel(entry.key),
                    style: const TextStyle(
                      color: Color(0xFF3769D6),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final viewing in entry.value)
                  LandlordViewingCard(
                    key: ValueKey(viewing.id),
                    viewing: viewing,
                  ),
              ],
              if (widget.viewings == null)
                const Text(
                  'Tên, số điện thoại và nhu cầu trên trang là dữ liệu mẫu.',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
