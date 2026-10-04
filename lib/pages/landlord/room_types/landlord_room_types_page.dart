import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      type.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        formatRoomTypePrice(type.monthlyRent),
                        style: const TextStyle(
                          color: Color(0xFF3769D6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
  late final _price = TextEditingController(
    text: widget.type?.monthlyRent.toString() ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    title: Text(widget.type == null ? 'Thêm loại phòng' : 'Sửa loại phòng'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 80,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tên loại phòng',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập tên loại phòng.';
                  }
                  return widget.store.nameExists(
                        value,
                        excludingId: widget.type?.id,
                      )
                      ? 'Tên loại phòng đã tồn tại.'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _price,
                maxLength: 12,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Giá thuê',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'đ/tháng',
                  hintText: '3000000',
                  helperText: 'Nhập số tiền, ví dụ: 3000000.',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  final price = int.tryParse(value ?? '');
                  return price == null || price <= 0
                      ? 'Nhập giá thuê lớn hơn 0.'
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
          if (!_form.currentState!.validate()) return;
          widget.store.saveRoomType(
            _name.text,
            monthlyRent: int.parse(_price.text),
            id: widget.type?.id,
          );
          Navigator.pop(context);
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}
