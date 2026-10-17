import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../landlord_demo_store.dart';
import 'models/landlord_room_type.dart';
import '../properties/services/property_image_picker.dart';
import '../../shared/rental/room_image_gallery.dart';

class LandlordRoomTypesPage extends StatelessWidget {
  const LandlordRoomTypesPage({super.key, this.store, this.imagePicker});
  final Future<SelectedPropertyImage?> Function()? imagePicker;
  final LandlordDemoStore? store;
  LandlordDemoStore get _store => store ?? LandlordDemoStore.instance;

  Future<void> _edit(BuildContext context, [LandlordRoomType? type]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RoomTypeEditor(
        store: _store,
        type: type,
        imagePicker: imagePicker ?? pickPropertyImage,
      ),
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
                  child: Column(
                    children: [
                      ListTile(
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${type.images.length} ảnh · Dùng chung cho các phòng thuộc loại này',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RoomImageGallery(images: type.images, height: 150),
                          ],
                        ),
                      ),
                    ],
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
  const _RoomTypeEditor({
    required this.store,
    this.type,
    required this.imagePicker,
  });
  final Future<SelectedPropertyImage?> Function() imagePicker;
  final LandlordDemoStore store;
  final LandlordRoomType? type;

  @override
  State<_RoomTypeEditor> createState() => _RoomTypeEditorState();
}

class _RoomTypeEditorState extends State<_RoomTypeEditor> {
  final _form = GlobalKey<FormState>();
  late final _images = [...?widget.type?.images];
  bool _picking = false;
  String? _imageError;

  Future<void> _addImage() async {
    setState(() {
      _picking = true;
      _imageError = null;
    });
    try {
      final image = await widget.imagePicker();
      if (!mounted || image == null) return;
      setState(
        () => _images.add(RoomTypeImage(name: image.name, bytes: image.bytes)),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _imageError = 'Không thể đọc ảnh. Chọn ảnh hợp lệ, tối đa 10 MB.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

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
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hình ảnh loại phòng',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ảnh đầu tiên là ảnh bìa. Các phòng thuộc loại này sẽ dùng bộ ảnh này.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _images.length; i++)
                    SizedBox(
                      width: 112,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _images[i].bytes,
                                  width: 112,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox(
                                    height: 84,
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton.filledTonal(
                                  tooltip: 'Xóa ảnh ${i + 1}',
                                  onPressed: _picking
                                      ? null
                                      : () =>
                                            setState(() => _images.removeAt(i)),
                                  icon: const Icon(Icons.close, size: 16),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: i == 0 || _picking
                                ? null
                                : () => setState(
                                    () =>
                                        _images.insert(0, _images.removeAt(i)),
                                  ),
                            child: Text(i == 0 ? 'Ảnh bìa' : 'Đặt làm bìa'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _picking ? null : _addImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_picking ? 'Đang đọc ảnh…' : 'Thêm ảnh'),
              ),
              if (_imageError != null)
                Text(_imageError!, style: const TextStyle(color: Colors.red)),
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
        onPressed: _picking
            ? null
            : () {
                if (!_form.currentState!.validate()) return;
                widget.store.saveRoomType(
                  _name.text,
                  monthlyRent: int.parse(_price.text),
                  id: widget.type?.id,
                  images: _images,
                );
                Navigator.pop(context);
              },
        child: const Text('Lưu'),
      ),
    ],
  );
}
