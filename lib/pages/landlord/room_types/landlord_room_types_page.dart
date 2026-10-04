import 'package:flutter/material.dart';

import 'models/landlord_room_type.dart';

const _blue = Color(0xFF3769D6);

class LandlordRoomTypesPage extends StatefulWidget {
  const LandlordRoomTypesPage({super.key});

  @override
  State<LandlordRoomTypesPage> createState() => _LandlordRoomTypesPageState();
}

class _LandlordRoomTypesPageState extends State<LandlordRoomTypesPage> {
  final _types = LandlordRoomType.initialTypes();
  String _query = '';

  Future<void> _edit([LandlordRoomType? type]) async {
    final result = await showDialog<LandlordRoomType>(
      context: context,
      builder: (_) => _RoomTypeEditor(type: type),
    );
    if (!mounted || result == null) return;
    if (_types.any(
      (item) =>
          !identical(item, type) &&
          item.name.trim().toLowerCase() == result.name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên loại phòng đã tồn tại.')),
      );
      return;
    }
    setState(() {
      if (type == null) {
        _types.add(result);
      } else {
        _types[_types.indexOf(type)] = result;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu loại phòng trong phiên hiện tại.')),
    );
  }

  void _details(LandlordRoomType type) {
    final rooms = type.rooms;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type.name),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.description),
                const SizedBox(height: 16),
                if (rooms.isEmpty)
                  const Text('Chưa có phòng được gán cho loại này.')
                else ...[
                  Text(
                    '${rooms.length} phòng phù hợp',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  for (final room in rooms)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.meeting_room_outlined,
                        color: _blue,
                      ),
                      title: Text(room.name),
                      subtitle: Text('${room.address}\n${room.size}'),
                      isThreeLine: true,
                    ),
                ],
              ],
            ),
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
    final visible = _types
        .where(
          (type) => '${type.name} ${type.description}'.toLowerCase().contains(
            _query.trim().toLowerCase(),
          ),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản lý loại phòng',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('Phân loại theo kiểu phòng, tiện ích và số người ở.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm loại phòng'),
                style: FilledButton.styleFrom(backgroundColor: _blue),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Tìm loại phòng',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${visible.length} loại phòng',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Không tìm thấy loại phòng phù hợp.'),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 600
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 16) / columns;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final type in visible)
                        SizedBox(
                          width: width,
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.category_outlined,
                                    color: _blue,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    type.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(type.description),
                                  const SizedBox(height: 14),
                                  Text(
                                    '${type.rooms.length} phòng phù hợp',
                                    style: const TextStyle(
                                      color: _blue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    type.maxOccupants == null
                                        ? 'Số người ở: chưa thiết lập'
                                        : 'Tối đa ${type.maxOccupants} người',
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _details(type),
                                        child: const Text('Xem phòng'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _edit(type),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Chỉnh sửa'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Dữ liệu mẫu từ Khám phá nhà trọ. Một phòng có thể thuộc '
                'nhiều nhóm tiện ích. Thêm và chỉnh sửa chỉ lưu trong phiên hiện tại.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomTypeEditor extends StatefulWidget {
  const _RoomTypeEditor({this.type});
  final LandlordRoomType? type;

  @override
  State<_RoomTypeEditor> createState() => _RoomTypeEditorState();
}

class _RoomTypeEditorState extends State<_RoomTypeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.type?.name);
  late final _description = TextEditingController(
    text: widget.type?.description,
  );
  late final _capacity = TextEditingController(
    text: widget.type?.maxOccupants?.toString() ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.type == null ? 'Thêm loại phòng' : 'Chỉnh sửa loại phòng',
    ),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên loại phòng'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên loại phòng.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số người tối đa (tùy chọn)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final number = int.tryParse(value.trim());
                  return number == null || number < 1
                      ? 'Nhập số nguyên lớn hơn 0.'
                      : null;
                },
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
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          final base =
              widget.type ?? const LandlordRoomType(name: '', description: '');
          Navigator.pop(
            context,
            base.edited(
              _name.text.trim(),
              _description.text.trim(),
              int.tryParse(_capacity.text.trim()),
            ),
          );
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}
