import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/app_persistence.dart';
import '../landlord_demo_store.dart';
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
        return LandlordPageFrame(
          children: [
            LandlordPageTitle(
              title: 'Thiết lập tầng và phòng',
              subtitle: _store.property.name,
            ),
            LandlordCard(
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
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const Scaffold(body: LandlordRoomTypesPage()),
                      ),
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
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Thiết lập tầng và phòng',
            subtitle: _store.property.name,
          ),
          Form(
            key: _form,
            child: Column(
              children: [
                LandlordCard(
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
                  LandlordCard(
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
                LandlordCard(
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final palette = LandlordPalette.of(context);
      final floors = _store.catalog.map((room) => room.floor).toSet().toList()
        ..sort();
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Sơ đồ tầng',
            subtitle:
                '${_store.property.name} · ${_store.catalog.length} phòng',
            trailing: IconButton.filledTonal(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          for (final floor in floors) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.stairs_rounded, color: palette.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tầng $floor',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${_store.catalog.where((room) => room.floor == floor).length} phòng',
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ],
              ),
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
                      SizedBox(
                        width: width,
                        child: _FloorRoomTile(
                          room: room,
                          typeName:
                              _store.roomTypes
                                  .where((type) => type.id == room.roomTypeId)
                                  .firstOrNull
                                  ?.name ??
                              'Chưa gắn loại',
                          occupied:
                              _store.roomDetails
                                  .where(
                                    (details) => details.room.code == room.code,
                                  )
                                  .firstOrNull
                                  ?.lease !=
                              null,
                          onTap: () => _edit(context, room),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 8),
          Text(
            'Chạm vào ô phòng để đổi tên, gắn loại phòng và cập nhật diện tích hoặc sức chứa.',
            style: TextStyle(color: palette.muted, fontSize: 12, height: 1.45),
          ),
        ],
      );
    },
  );
}

class _FloorRoomTile extends StatelessWidget {
  const _FloorRoomTile({
    required this.room,
    required this.typeName,
    required this.occupied,
    required this.onTap,
  });

  final LandlordRoom room;
  final String typeName;
  final bool occupied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final stateColor = occupied
        ? const Color(0xFF3274D9)
        : const Color(0xFF16836F);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.line),
            boxShadow: [
              BoxShadow(
                color: palette.ink.withValues(alpha: .035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.circle, color: stateColor, size: 8),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                typeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                occupied ? 'Đang thuê' : 'Còn trống',
                style: TextStyle(
                  color: stateColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
