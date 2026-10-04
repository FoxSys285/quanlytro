import 'package:flutter/material.dart';

import '../models/landlord_property.dart';

class LandlordPropertyEditor extends StatefulWidget {
  const LandlordPropertyEditor({super.key, required this.property});
  final LandlordProperty property;

  @override
  State<LandlordPropertyEditor> createState() => _LandlordPropertyEditorState();
}

class _LandlordPropertyEditorState extends State<LandlordPropertyEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.property.name);
  late final _address = TextEditingController(text: widget.property.address);
  late final _owner = TextEditingController(text: widget.property.ownerName);
  late final _phone = TextEditingController(text: widget.property.phone);
  late final _description = TextEditingController(
    text: widget.property.description,
  );
  late final _image = TextEditingController(text: widget.property.imageUrl);

  @override
  void dispose() {
    for (final controller in [
      _name,
      _address,
      _owner,
      _phone,
      _description,
      _image,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập thông tin.' : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Chỉnh sửa thông tin nhà trọ'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Tên nhà trọ'),
                validator: _required,
              ),
              TextFormField(
                controller: _address,
                maxLines: 2,
                maxLength: 250,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ / vị trí',
                ),
                validator: _required,
              ),
              TextFormField(
                controller: _owner,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Tên chủ trọ'),
                validator: _required,
              ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 25,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                validator: (value) {
                  final phone = (value ?? '').replaceAll(
                    RegExp(r'[\s()+-]'),
                    '',
                  );
                  return RegExp(r'^\d{9,15}$').hasMatch(phone)
                      ? null
                      : 'Số điện thoại không hợp lệ.';
                },
              ),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Giới thiệu nhà trọ',
                ),
              ),
              TextFormField(
                controller: _image,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Đường dẫn ảnh',
                  hintText: 'https://...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final uri = Uri.tryParse(value.trim());
                  return uri != null &&
                          ['https', 'http'].contains(uri.scheme) &&
                          uri.host.isNotEmpty
                      ? null
                      : 'Nhập đường dẫn ảnh http hoặc https hợp lệ.';
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
          Navigator.pop(
            context,
            LandlordProperty(
              id: widget.property.id,
              name: _name.text.trim(),
              address: _address.text.trim(),
              ownerName: _owner.text.trim(),
              phone: _phone.text.trim(),
              description: _description.text.trim(),
              imageUrl: _image.text.trim(),
            ),
          );
        },
        child: const Text('Lưu thay đổi'),
      ),
    ],
  );
}
