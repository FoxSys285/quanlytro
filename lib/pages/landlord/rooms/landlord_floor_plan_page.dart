import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/app_persistence.dart';
import '../../../layouts/landlord_navigation.dart';
import '../finance/landlord_finance_models.dart';
import '../incidents/models/landlord_suco.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import '../room_types/landlord_room_types_page.dart';
import 'components/landlord_room_editor.dart';
import 'models/landlord_room.dart';

class LandlordFloorPlanSetupPage extends StatefulWidget {
  const LandlordFloorPlanSetupPage({super.key, this.store});

  final LandlordDemoStore? store;

  @override
  State<LandlordFloorPlanSetupPage> createState() =>
      _LandlordFloorPlanSetupPageState();
}

class _LandlordFloorPlanSetupPageState
    extends State<LandlordFloorPlanSetupPage> {
  LandlordDemoStore get _store =>
      widget.store ?? LandlordDemoStore.activeInstance;

  final _form = GlobalKey<FormState>();
  final _floorCount = TextEditingController(text: '1');
  final _roomCounts = <TextEditingController>[TextEditingController()];
  String? _roomTypeId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _floorCount.dispose();
    for (final controller in _roomCounts) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resizeFloorRows(String value) {
    final count = int.tryParse(value);
    if (count == null || count < 1 || count > 30) return;
    setState(() {
      while (_roomCounts.length < count) {
        _roomCounts.add(TextEditingController());
      }
      while (_roomCounts.length > count) {
        _roomCounts.removeLast().dispose();
      }
    });
  }

  String? _validateCount(String? value) {
    final count = int.tryParse((value ?? '').trim());
    return count == null || count < 1 || count > 50
        ? 'Nhập số phòng từ 1 đến 50.'
        : null;
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    final floors = int.tryParse(_floorCount.text) ?? 0;
    if (floors != _roomCounts.length || _roomTypeId == null) {
      setState(() => _error = 'Chọn loại phòng mặc định và kiểm tra số tầng.');
      return;
    }
    final roomCounts = {
      for (var index = 0; index < floors; index++)
        index + 1: int.parse(_roomCounts[index].text),
    };
    final total = roomCounts.values.fold<int>(0, (sum, count) => sum + count);
    if (total > 350) {
      setState(() => _error = 'Mỗi nhà trọ có thể tạo tối đa 350 phòng.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      _store.createRoomsForFloorPlan(roomCounts, roomTypeId: _roomTypeId!);
      await AppPersistence.current?.flush();
      if (!mounted) return;
      final saveError = AppPersistence.current?.error.value;
      if (saveError != null) {
        showLandlordMessage(context, saveError);
      } else {
        showLandlordMessage(
          context,
          'Đã tạo sơ đồ $floors tầng với $total phòng.',
        );
      }
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _error = error.message.toString());
    } catch (error) {
      if (mounted) setState(() => _error = 'Chưa lưu được sơ đồ tầng: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final palette = LandlordPalette.of(context);
      if (_store.roomTypes.isNotEmpty &&
          !_store.roomTypes.any((type) => type.id == _roomTypeId)) {
        _roomTypeId = _store.roomTypes.first.id;
      }
      if (_store.roomTypes.isEmpty) {
        return LandlordGlassPage(
          title: 'Thiết lập tầng và phòng',
          subtitle: _store.property.name,
          kicker: 'QUẢN LÝ KHÔNG GIAN',
          store: _store,
          children: [
            LandlordGlassSection(
              title: 'Bắt đầu thiết lập',
              subtitle: 'Tạo loại phòng trước, sau đó khai báo mặt bằng.',
            ),
            LandlordGlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 38,
                    color: palette.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thêm loại phòng trước',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo loại phòng và giá thuê rồi quay lại để khai báo số phòng theo từng tầng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.muted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => LandlordNavigation.push<void>(
                      context,
                      title: 'Loại phòng',
                      destinationId: 'room_types',
                      page: LandlordRoomTypesPage(store: _store),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm loại phòng'),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      if (_store.catalog.isNotEmpty) {
        return LandlordFloorPlanPage(store: _store);
      }
      return LandlordGlassPage(
        title: 'Thiết lập tầng và phòng',
        subtitle: _store.property.name,
        kicker: 'QUẢN LÝ KHÔNG GIAN',
        store: _store,
        children: [
          LandlordGlassSection(
            title: 'Khai báo mặt bằng',
            subtitle: 'Nhập số tầng, số phòng và loại phòng mặc định.',
          ),
          Form(
            key: _form,
            child: Column(
              children: [
                LandlordGlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Số tầng cho thuê',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mỗi tầng sẽ có số phòng riêng; tầng nào nhiều hoặc ít phòng đều khai báo được.',
                        style: TextStyle(color: palette.muted, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _floorCount,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: _resizeFloorRows,
                        decoration: const InputDecoration(
                          labelText: 'Số tầng',
                          prefixIcon: Icon(Icons.stairs_rounded),
                        ),
                        validator: (value) {
                          final count = int.tryParse(value ?? '');
                          return count == null || count < 1 || count > 30
                              ? 'Nhập số tầng từ 1 đến 30.'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
                for (var index = 0; index < _roomCounts.length; index++)
                  LandlordGlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.primarySoft,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: palette.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tầng ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        SizedBox(
                          width: 132,
                          child: TextFormField(
                            controller: _roomCounts[index],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Số phòng',
                              isDense: true,
                            ),
                            validator: _validateCount,
                          ),
                        ),
                      ],
                    ),
                  ),
                LandlordGlassCard(
                  padding: const EdgeInsets.all(18),
                  child: DropdownButtonFormField<String>(
                    initialValue: _roomTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Loại phòng gợi ý ban đầu',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      for (final type in _store.roomTypes)
                        DropdownMenuItem(
                          value: type.id,
                          child: Text(
                            type.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _roomTypeId = value),
                    validator: (value) =>
                        value == null ? 'Chọn một loại phòng.' : null,
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _create,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.grid_view_rounded),
                    label: Text(
                      _saving ? 'Đang tạo sơ đồ…' : 'Tạo các ô phòng',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class LandlordFloorPlanPage extends StatelessWidget {
  const LandlordFloorPlanPage({super.key, this.store});

  final LandlordDemoStore? store;
  LandlordDemoStore get _store => store ?? LandlordDemoStore.activeInstance;

  Future<void> _edit(BuildContext context, LandlordRoom room) =>
      showDialog<void>(
        context: context,
        builder: (_) => LandlordRoomEditor(store: _store, room: room),
      );

  (String, Color, Color) _roomStyle(LandlordRoomDetails details) {
    final lease = details.lease;
    if (details.status == LandlordRoomStatus.vacant) {
      return ('Còn trống', const Color(0xFF16836F), Colors.white);
    }
    final invoices =
        lease == null
              ? const <LandlordInvoice>[]
              : _store.invoices
                    .where(
                      (invoice) =>
                          invoice.leaseId == lease.id &&
                          !invoice.cancelled &&
                          invoice.remaining > 0,
                    )
                    .toList()
          ..sort((a, b) => b.period.compareTo(a.period));
    if (invoices.any(
      (invoice) => invoice.status == LandlordInvoiceStatus.overdue,
    )) {
      return (
        'Chưa đóng tiền',
        const Color(0xFFD64545),
        const Color(0xFFD64545),
      );
    }
    final hasIncident = _store.incidents.any(
      (incident) =>
          _store.canonicalRoom(incident.room) ==
              _store.canonicalRoom(details.room.code) &&
          (incident.status == IncidentStatus.newly ||
              incident.status == IncidentStatus.inProgress),
    );
    if (hasIncident) {
      return (
        'Đang sửa chữa',
        const Color(0xFF8054B8),
        const Color(0xFF8054B8),
      );
    }
    if (lease != null && lease.isCurrent) {
      final days = lease.endDate.difference(DateTime.now()).inDays;
      if (days >= 0 && days <= 30) {
        return (
          'Sắp hết hạn',
          const Color(0xFFD99412),
          const Color(0xFFF2C14E),
        );
      }
      if (invoices.isNotEmpty) {
        return (
          'Chưa đóng tiền',
          const Color(0xFFD64545),
          const Color(0xFFD64545),
        );
      }
      return ('Đang thuê', const Color(0xFF198754), const Color(0xFF2E9B62));
    }
    if (invoices.isNotEmpty) {
      return (
        'Chưa đóng tiền',
        const Color(0xFFD64545),
        const Color(0xFFD64545),
      );
    }
    return ('Sắp nhận phòng', const Color(0xFF63738B), const Color(0xFF63738B));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final palette = LandlordPalette.of(context);
      final floors = _store.catalog.map((room) => room.floor).toSet().toList()
        ..sort();
      return LandlordGlassPage(
        title: 'Sơ đồ tầng',
        subtitle: '${_store.property.name} · ${_store.catalog.length} phòng',
        kicker: 'QUẢN LÝ KHÔNG GIAN',
        store: _store,
        children: [
          LandlordGlassSection(
            title: 'Mặt bằng theo tầng',
            subtitle: 'Màu sắc giúp nhận biết nhanh trạng thái của từng phòng.',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FloorLegend(
                color: Colors.white,
                label: 'Còn trống',
                border: palette.line,
              ),
              const _FloorLegend(color: Color(0xFF2E9B62), label: 'Đang thuê'),
              const _FloorLegend(
                color: Color(0xFFF2C14E),
                label: 'Sắp hết hạn',
              ),
              const _FloorLegend(
                color: Color(0xFFD64545),
                label: 'Chưa đóng tiền',
              ),
              const _FloorLegend(
                color: Color(0xFF8054B8),
                label: 'Đang sửa chữa',
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final floor in floors) ...[
            LandlordGlassSection(
              title: 'Tầng $floor',
              subtitle:
                  '${_store.catalog.where((room) => room.floor == floor).length} phòng',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760
                    ? 5
                    : constraints.maxWidth >= 560
                    ? 4
                    : constraints.maxWidth >= 390
                    ? 3
                    : 2;
                const spacing = 10.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final rooms =
                    _store.catalog.where((room) => room.floor == floor).toList()
                      ..sort((a, b) => a.code.compareTo(b.code));
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final room in rooms)
                      Builder(
                        builder: (context) {
                          final details = _store.roomDetails.firstWhere(
                            (item) => item.room.code == room.code,
                          );
                          final (label, color, background) = _roomStyle(
                            details,
                          );
                          return SizedBox(
                            width: width,
                            child: _FloorRoomTile(
                              room: room,
                              typeName: details.typeName,
                              label: label,
                              color: color,
                              background: background,
                              onEdit: () => _edit(context, room),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          const LandlordGlassCard(
            child: Text(
              'Chọn “Chỉnh sửa phòng” để cập nhật tên, tầng, loại phòng, diện tích hoặc sức chứa.',
            ),
          ),
        ],
      );
    },
  );
}

class _FloorLegend extends StatelessWidget {
  const _FloorLegend({required this.color, required this.label, this.border});
  final Color color;
  final String label;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: LandlordPalette.of(context).surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: LandlordPalette.of(context).line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: border ?? color),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _FloorRoomTile extends StatelessWidget {
  const _FloorRoomTile({
    required this.room,
    required this.typeName,
    required this.label,
    required this.color,
    required this.background,
    required this.onEdit,
  });
  final LandlordRoom room;
  final String typeName;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final isVacant = label == 'Còn trống';
    final isLight = isVacant || label == 'Sắp hết hạn';
    return Container(
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVacant ? palette.line : color.withValues(alpha: .55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phòng ${room.code}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLight ? const Color(0xFF1B2935) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            typeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF68778A)
                  : Colors.white.withValues(alpha: .88),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLight ? color : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                foregroundColor: isLight ? palette.primary : Colors.white,
                backgroundColor: isLight
                    ? palette.primarySoft
                    : Colors.white.withValues(alpha: .2),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text(
                'Chỉnh sửa phòng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
