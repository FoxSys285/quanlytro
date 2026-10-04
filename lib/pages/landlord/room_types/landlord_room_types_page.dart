import 'package:flutter/material.dart';

import '../landlord_demo_store.dart';
import 'models/landlord_room_type.dart';

class LandlordRoomTypesPage extends StatelessWidget {
  const LandlordRoomTypesPage({super.key, this.store});
  final LandlordDemoStore? store;
  LandlordDemoStore get _store => store ?? LandlordDemoStore.instance;

  Future<void> _edit(BuildContext context, [LandlordRoomType? type]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RoomTypeEditor(store: _store, type: type),
    );
  }

  Future<void> _delete(BuildContext context, LandlordRoomType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa loại phòng'),
        content: Text('Xóa loại phòng “${type.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) _store.deleteRoomType(type.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loại phòng',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: const Text('Thêm loại phòng'),
              ),
              const SizedBox(height: 20),
              if (_store.roomTypes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Chưa có loại phòng.'),
                ),
              for (final type in _store.roomTypes)
                Card(
                  key: ValueKey(type.id),
                  color: Colors.white,
                  elevation: 0,
                  child: ListTile(
                    title: Text(type.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Sửa ${type.name}',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, type),
                        ),
                        IconButton(
                          tooltip: 'Xóa ${type.name}',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _delete(context, type),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RoomTypeEditor extends StatefulWidget {
  const _RoomTypeEditor({required this.store, this.type});
  final LandlordDemoStore store;
  final LandlordRoomType? type;

  @override
  State<_RoomTypeEditor> createState() => _RoomTypeEditorState();
}

class _RoomTypeEditorState extends State<_RoomTypeEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.type?.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.type == null ? 'Thêm loại phòng' : 'Sửa loại phòng'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _name,
        maxLength: 80,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Tên loại phòng'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Nhập tên loại phòng.';
          }
          return widget.store.nameExists(value, excludingId: widget.type?.id)
              ? 'Tên loại phòng đã tồn tại.'
              : null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          widget.store.saveRoomType(_name.text, id: widget.type?.id);
          Navigator.pop(context);
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}
