import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../landlord_theme.dart';
import '../../landlord_demo_store.dart';
import '../models/landlord_room.dart';
import '../../../shared/media/room_photo_gallery.dart';

class LandlordRoomEditor extends StatefulWidget {
  const LandlordRoomEditor({super.key, required this.store, this.room});
  final LandlordDemoStore store;
  final LandlordRoom? room;
  @override
  State<LandlordRoomEditor> createState() => _LandlordRoomEditorState();
}

class _LandlordRoomEditorState extends State<LandlordRoomEditor> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.room?.code ?? '');
  late final _floor = TextEditingController(text: '${widget.room?.floor ?? 1}');
  late final _area = TextEditingController(text: '${widget.room?.area ?? 25}');
  late final _capacity = TextEditingController(
    text: '${widget.room?.capacity ?? 2}',
  );
  late String? _type =
      widget.room?.roomTypeId ?? widget.store.roomTypes.firstOrNull?.id;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _floor.dispose();
    _area.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    try {
      widget.store.saveRoom(
        LandlordRoom(
          code: _code.text.trim().toUpperCase(),
          floor: int.parse(_floor.text),
          area: int.parse(_area.text),
          capacity: int.parse(_capacity.text),
          roomTypeId: _type!,
          leaseRoomCode: widget.room?.leaseRoomCode,
        ),
        existingCode: widget.room?.code,
      );
      Navigator.pop(context);
    } on ArgumentError catch (e) {
      setState(() => _error = e.message.toString());
    }
  }

  Widget _number(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (v) {
      final n = int.tryParse(v ?? '');
      return n == null || n < min || n > max
          ? 'Nhập giá trị từ $min đến $max.'
          : null;
    },
  );

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return AlertDialog(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.meeting_room_outlined, color: palette.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              widget.room == null
                  ? 'Thêm phòng mới'
                  : 'Chỉnh sửa phòng ${widget.room!.code}',
              style: TextStyle(
                color: palette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.store.property.name,
                  style: TextStyle(
                    color: palette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _code,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Tên / mã phòng',
                    prefixIcon: Icon(Icons.tag_outlined),
                    helperText: 'Tên hiển thị duy nhất, ví dụ: 101 hoặc A.101',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Nhập mã phòng.' : null,
                ),
                const SizedBox(height: 16),
                _number(_floor, 'Tầng', 1, 30),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: widget.store.roomTypes.any((t) => t.id == _type)
                      ? _type
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Loại phòng'),
                  items: [
                    for (final t in widget.store.roomTypes)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _type = v),
                  validator: (v) => v == null ? 'Chọn loại phòng.' : null,
                ),
                const SizedBox(height: 16),
                _number(_area, 'Diện tích (m²)', 6, 500),
                const SizedBox(height: 16),
                _number(_capacity, 'Số người tối đa', 1, 20),
                const SizedBox(height: 16),
                if (widget.store.roomTypes.any((type) => type.id == _type)) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RoomPhotoGallery(
                      photos: widget.store.roomTypes
                          .firstWhere((type) => type.id == _type)
                          .photos,
                      label: 'Ảnh của loại phòng đã chọn',
                      height: 130,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ảnh phòng lấy từ album của loại phòng đã chọn.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Giá niêm yết lấy từ loại phòng. Phòng đã có hợp đồng giữ giá đã thỏa thuận.',
                  style: TextStyle(fontSize: 12, height: 1.45),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 17),
          label: const Text('Lưu phòng'),
        ),
      ],
    );
  }
}
