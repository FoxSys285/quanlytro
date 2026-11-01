import 'package:flutter/material.dart';

import '../landlord_demo_store.dart';
import '../landlord_ui.dart';
import '../rooms/models/landlord_room.dart';
import 'components/landlord_property_editor.dart';
import 'components/landlord_property_image.dart';
import 'models/landlord_property.dart';

class PropertyPortfolioPage extends StatefulWidget {
  const PropertyPortfolioPage({super.key});
  @override
  State<PropertyPortfolioPage> createState() => _PropertyPortfolioPageState();
}

class _PropertyPortfolioPageState extends State<PropertyPortfolioPage> {
  String _query = '';
  RentalPortfolio get _portfolio => RentalPortfolio.instance;

  Future<void> _edit(LandlordDemoStore store) async {
    final property = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(property: store.property),
    );
    if (property == null) return;
    store.updateProperty(property);
    if (mounted) showLandlordMessage(context, 'Đã cập nhật ${property.name}.');
  }

  Future<void> _add() async {
    final property = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(
        creating: true,
        property: LandlordProperty(
          id: 'property-${DateTime.now().microsecondsSinceEpoch}',
          name: '',
          address: '',
          ownerName: _portfolio.active.property.ownerName,
          phone: _portfolio.active.property.phone,
          description: '',
        ),
      ),
    );
    if (!mounted || property == null) return;
    var floors = 3;
    var rooms = 6;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thiết lập tầng và phòng'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${property.name} · ${floors * rooms} phòng sẽ được tạo tự động',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: floors,
                  decoration: const InputDecoration(labelText: 'Số tầng'),
                  items: [
                    for (var i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text('$i tầng')),
                  ],
                  onChanged: (v) => setDialogState(() => floors = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: rooms,
                  decoration: const InputDecoration(
                    labelText: 'Phòng mỗi tầng',
                  ),
                  items: [
                    for (var i = 1; i <= 20; i++)
                      DropdownMenuItem(value: i, child: Text('$i phòng')),
                  ],
                  onChanged: (v) => setDialogState(() => rooms = v!),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Có thể sửa từng phòng và bảng giá sau khi tạo.',
                  style: TextStyle(color: landlordMuted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo nhà trọ'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    _portfolio.add(property, floors: floors, roomsPerFloor: rooms);
  }

  Future<void> _delete(LandlordDemoStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhà trọ'),
        content: Text(
          'Xóa ${store.property.name} và danh sách phòng chưa có hợp đồng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      _portfolio.remove(store.property.id);
    } on ArgumentError catch (e) {
      showLandlordMessage(context, e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _portfolio,
    builder: (context, _) {
      final stores = _portfolio.stores
          .where(
            (s) => '${s.property.name} ${s.property.address}'
                .toLowerCase()
                .contains(_query.toLowerCase()),
          )
          .toList();
      final roomCount = _portfolio.stores.fold<int>(
        0,
        (sum, s) => sum + s.catalog.length,
      );
      final occupied = _portfolio.stores.fold<int>(
        0,
        (sum, s) =>
            sum +
            s.roomDetails
                .where((r) => r.status == LandlordRoomStatus.occupied)
                .length,
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LandlordPageTitle(
                  title: 'Danh sách nhà trọ',
                  subtitle: 'Quản lý thông tin, quy mô và tình trạng cho thuê.',
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF173C76), Color(0xFF3769D6)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 18,
                    children: [
                      _metric('${_portfolio.stores.length}', 'Nhà trọ'),
                      _metric('$roomCount', 'Tổng số phòng'),
                      _metric('$occupied', 'Phòng đang thuê'),
                      _metric('${roomCount - occupied}', 'Phòng còn lại'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Tìm tên hoặc địa chỉ nhà trọ',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm nhà trọ'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (stores.isEmpty)
                  const LandlordEmptyState(
                    message: 'Không tìm thấy nhà trọ phù hợp.',
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 960
                        ? 3
                        : constraints.maxWidth >= 640
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 16) / columns;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        for (final store in stores)
                          SizedBox(width: width, child: _card(store)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _metric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(label, style: const TextStyle(color: Color(0xFFD6E5FF))),
    ],
  );

  Widget _card(LandlordDemoStore store) {
    final p = store.property;
    final floors = store.catalog.map((r) => r.floor).toSet().length;
    final vacant = store.roomDetails
        .where((r) => r.status == LandlordRoomStatus.vacant)
        .length;
    final selected = p.id == _portfolio.active.property.id;
    return LandlordCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LandlordPropertyImage(
            url: p.imageUrl,
            bytes: p.imageBytes,
            height: 130,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: landlordInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: landlordMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        '$floors tầng · ${store.catalog.length} phòng',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text('${store.roomTypes.length} loại'),
                      visualDensity: VisualDensity.compact,
                    ),
                    LandlordStatusPill(
                      '$vacant phòng trống',
                      color: const Color(0xFF16836F),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${p.ownerName}\n${p.phone}',
                  style: const TextStyle(height: 1.6),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _portfolio.select(p.id),
                        icon: Icon(
                          selected
                              ? Icons.check_circle_outline
                              : Icons.open_in_new,
                          size: 18,
                        ),
                        label: Text(selected ? 'Đang quản lý' : 'Quản lý'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sửa ${p.name}',
                      onPressed: () => _edit(store),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    if (store.leases.isEmpty)
                      IconButton(
                        tooltip: 'Xóa ${p.name}',
                        onPressed: () => _delete(store),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
