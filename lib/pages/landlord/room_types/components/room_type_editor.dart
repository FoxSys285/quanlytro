import 'package:flutter/material.dart';

import '../../landlord_theme.dart';

import 'package:flutter/services.dart';

import '../../landlord_demo_store.dart';
import '../../landlord_ui.dart';
import '../../../shared/media/room_photo.dart';
import '../../../shared/media/room_photo_gallery.dart';
import '../models/landlord_room_type.dart';
import '../services/room_type_photo_picker.dart';

class RoomTypeEditor extends StatefulWidget {
  const RoomTypeEditor({
    super.key,
    required this.store,
    this.type,
    this.pickPhotos = pickRoomTypePhotos,
  });
  final LandlordDemoStore store;
  final LandlordRoomType? type;
  final RoomTypePhotoPicker pickPhotos;
  @override
  State<RoomTypeEditor> createState() => _RoomTypeEditorState();
}

class _RoomTypeEditorState extends State<RoomTypeEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.type?.name);
  late final _price = TextEditingController(
    text: widget.type == null ? '' : _formatVnd(widget.type!.monthlyRent),
  );
  late final _photos = <RoomPhoto>[...?widget.type?.photos];
  bool _picking = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final selected = await widget.pickPhotos(12 - _photos.length);
      if (!mounted) return;
      if (_photos.length + selected.length > 12) {
        throw const FormatException('Mỗi loại phòng có tối đa 12 ảnh.');
      }
      setState(() => _photos.addAll(selected));
    } on PlatformException catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không mở được thư viện ảnh. Kiểm tra quyền truy cập ảnh rồi thử lại.',
        );
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không đọc được ảnh. Vui lòng chọn ảnh khác.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    try {
      widget.store.saveRoomType(
        _name.text,
        monthlyRent: int.parse(_price.text.replaceAll(RegExp(r'\D'), '')),
        id: widget.type?.id,
        photos: _photos,
      );
      Navigator.pop(context);
    } on ArgumentError catch (e) {
      setState(() => _error = e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: LandlordPalette.of(context).surface,
    surfaceTintColor: Colors.transparent,
    title: Text(widget.type == null ? 'Thêm loại phòng' : 'Sửa loại phòng'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
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
              const SizedBox(height: 18),
              TextFormField(
                controller: _price,
                maxLength: 16,
                keyboardType: TextInputType.number,
                inputFormatters: [_VietnameseMoneyFormatter()],
                decoration: InputDecoration(
                  labelText: 'Giá thuê',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'đ/tháng',
                  hintText: '3000000',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) =>
                    (int.tryParse(
                              (value ?? '').replaceAll(RegExp(r'\D'), ''),
                            ) ??
                            0) <=
                        0
                    ? 'Nhập giá thuê lớn hơn 0.'
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.collections_outlined,
                    color: landlordBlue,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Album loại phòng',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${_photos.length}/12',
                    style: TextStyle(
                      color: LandlordPalette.of(context).muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Các phòng thuộc loại này dùng chung album. Ảnh đầu tiên là ảnh bìa trên danh sách phòng.',
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              if (_photos.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 145,
                    width: double.infinity,
                    child: RoomPhotoImage(
                      photo: _photos.first,
                      label: 'Ảnh bìa loại phòng',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _photos.length; i++) _thumbnail(i),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _picking || _photos.length >= 12 ? null : _pick,
                  icon: _picking
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: Text(_picking ? 'Đang đọc ảnh...' : 'Chọn nhiều ảnh'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tối đa 12 ảnh · 10 MB/ảnh',
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 11,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Color(0xFFB94A50), fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
      FilledButton(onPressed: _picking ? null : _save, child: Text('Lưu')),
    ],
  );

  Widget _thumbnail(int index) => SizedBox(
    width: 92,
    child: Column(
      children: [
        Container(
          height: 78,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: index == 0
                  ? landlordBlue
                  : LandlordPalette.of(context).line,
              width: index == 0 ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RoomPhotoImage(photo: _photos[index], label: 'Ảnh ${index + 1}'),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton.filled(
                  tooltip: 'Xóa ảnh ${index + 1}',
                  onPressed: _picking
                      ? null
                      : () => setState(() => _photos.removeAt(index)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.close, size: 16),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: index == 0 || _picking
              ? null
              : () => setState(() {
                  final photo = _photos.removeAt(index);
                  _photos.insert(0, photo);
                }),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 36),
            textStyle: TextStyle(fontSize: 10),
          ),
          child: Text(index == 0 ? 'Ảnh bìa' : 'Đặt làm bìa'),
        ),
      ],
    ),
  );
}

String _formatVnd(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

class _VietnameseMoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    final formatted = _formatVnd(int.parse(digits));
    final cursorOffset = newValue.selection.end
        .clamp(0, newValue.text.length)
        .toInt();
    final digitCursor = newValue.text
        .substring(0, cursorOffset)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var seen = 0;
    var cursor = formatted.length;
    for (var index = 0; index < formatted.length; index++) {
      if (RegExp(r'\d').hasMatch(formatted[index])) seen++;
      if (seen == digitCursor) {
        cursor = index + 1;
        break;
      }
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }
}
