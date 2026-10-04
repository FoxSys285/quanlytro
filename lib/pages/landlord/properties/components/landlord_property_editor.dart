import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/landlord_property.dart';
import '../services/property_image_picker.dart';
import 'landlord_property_image.dart';

class LandlordPropertyEditor extends StatefulWidget {
  const LandlordPropertyEditor({
    super.key,
    required this.property,
    this.pickImage,
  });
  final LandlordProperty property;
  final Future<SelectedPropertyImage?> Function()? pickImage;

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
  late Uint8List? _imageBytes = widget.property.imageBytes;
  late String _imageUrl = widget.property.imageUrl;
  late String? _imageName = widget.property.imageName;
  bool _picking = false;
  String? _imageError;

  @override
  void dispose() {
    for (final controller in [_name, _address, _owner, _phone, _description]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseImage() async {
    setState(() {
      _picking = true;
      _imageError = null;
    });
    try {
      final selected = await (widget.pickImage ?? pickPropertyImage)();
      if (!mounted || selected == null) return;
      setState(() {
        _imageBytes = selected.bytes;
        _imageName = selected.name;
        _imageUrl = '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _imageError = error is FormatException
            ? error.message
            : 'Không chọn được ảnh. Hãy thử một ảnh JPG, PNG hoặc WebP.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Vui lòng nhập thông tin.' : null;

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    counterText: '',
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDFE5EE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDFE5EE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3769D6), width: 1.5),
    ),
  );

  void _save() {
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
        imageUrl: _imageUrl,
        imageBytes: _imageBytes,
        imageName: _imageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 740,
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF3769D6),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chỉnh sửa nhà trọ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cập nhật hình ảnh và thông tin liên hệ.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hình ảnh nhà trọ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    LandlordPropertyImage(
                      url: _imageUrl,
                      bytes: _imageBytes,
                      height: 180,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _picking ? null : _chooseImage,
                          icon: _picking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 20,
                                ),
                          label: Text(
                            _imageBytes != null || _imageUrl.isNotEmpty
                                ? 'Đổi ảnh'
                                : 'Chọn ảnh',
                          ),
                        ),
                        if (_imageBytes != null || _imageUrl.isNotEmpty)
                          TextButton.icon(
                            onPressed: _picking
                                ? null
                                : () => setState(() {
                                    _imageBytes = null;
                                    _imageName = null;
                                    _imageUrl = '';
                                    _imageError = null;
                                  }),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Bỏ ảnh'),
                          ),
                      ],
                    ),
                    if (_imageName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _imageName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    if (_imageError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _imageError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Thông tin nhà trọ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _name,
                      maxLength: 100,
                      decoration: _decoration(
                        'Tên nhà trọ',
                        Icons.home_work_outlined,
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _address,
                      minLines: 1,
                      maxLines: 2,
                      maxLength: 250,
                      decoration: _decoration(
                        'Địa chỉ / vị trí',
                        Icons.location_on_outlined,
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Liên hệ chủ trọ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final owner = TextFormField(
                          controller: _owner,
                          maxLength: 100,
                          decoration: _decoration(
                            'Tên chủ trọ',
                            Icons.person_outline,
                          ),
                          validator: _required,
                        );
                        final phone = TextFormField(
                          controller: _phone,
                          maxLength: 25,
                          keyboardType: TextInputType.phone,
                          decoration: _decoration(
                            'Số điện thoại',
                            Icons.phone_outlined,
                          ),
                          validator: (value) {
                            final number = (value ?? '').replaceAll(
                              RegExp(r'[\s()+-]'),
                              '',
                            );
                            return RegExp(r'^\d{9,15}$').hasMatch(number)
                                ? null
                                : 'Số điện thoại không hợp lệ.';
                          },
                        );
                        if (constraints.maxWidth >= 520) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: owner),
                              const SizedBox(width: 14),
                              Expanded(child: phone),
                            ],
                          );
                        }
                        return Column(
                          children: [owner, const SizedBox(height: 14), phone],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: _decoration(
                        'Giới thiệu nhà trọ',
                        Icons.notes_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _picking ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3769D6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Lưu thay đổi'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
