import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import 'models/landlord_incident.dart';

class LandlordIncidentsPage extends StatefulWidget {
  const LandlordIncidentsPage({super.key, this.store});
  final LandlordDemoStore? store;

  @override
  State<LandlordIncidentsPage> createState() => _LandlordIncidentsPageState();
}

class _LandlordIncidentsPageState extends State<LandlordIncidentsPage> {
  IncidentStatus? _filter;

  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
  List<LandlordIncident> get _incidents => _store.incidents;
  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filter == null
        ? _incidents
        : _incidents.where((i) => i.status == _filter).toList();

    return LandlordPageFrame(
      children: [
        const LandlordPageTitle(
          title: 'Yêu cầu sửa chữa',
          subtitle: 'Tiếp nhận và cập nhật tiến độ sự cố của người thuê.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Tất cả', null),
              for (final status in IncidentStatus.values)
                _filterChip(status.label, status),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const LandlordEmptyState(message: 'Không có yêu cầu nào.'),
        for (final incident in list)
          LandlordCard(
            onTap: () => _openDetail(incident),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        incident.title,
                        style: const TextStyle(
                          color: landlordInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    LandlordStatusPill(
                      incident.status.label,
                      color: incident.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng ${incident.room} · ${incident.reporter} · ${incident.date}',
                  style: const TextStyle(color: landlordMuted, fontSize: 12),
                ),
                if (incident.urgent) ...[
                  const SizedBox(height: 6),
                  const LandlordStatusPill('Khẩn cấp', color: Colors.red),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, IncidentStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == status,
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }

  void _openDetail(LandlordIncident incident) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incident.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('Phòng ${incident.room} · ${incident.category}'),
            Text('Người báo: ${incident.reporter} · ${incident.date}'),
            const SizedBox(height: 10),
            Text(incident.description),
            const SizedBox(height: 16),
            const Text(
              'Cập nhật trạng thái',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final status in IncidentStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: incident.status == status,
                    onSelected: (_) {
                      _store.updateIncident(incident, status);
                      Navigator.pop(sheetContext);
                      showLandlordMessage(
                        context,
                        'Đã chuyển "${incident.title}" sang ${status.label}.',
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
