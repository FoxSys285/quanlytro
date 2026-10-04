import 'package:flutter/material.dart';

import '../models/landlord_announcement.dart';

enum _Audience { all, floor, room }

class LandlordAnnouncementComposer extends StatefulWidget {
  const LandlordAnnouncementComposer({super.key, required this.properties});
  final List<AnnouncementProperty> properties;

  @override
  State<LandlordAnnouncementComposer> createState() =>
      _LandlordAnnouncementComposerState();
}

class _LandlordAnnouncementComposerState
    extends State<LandlordAnnouncementComposer> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  late final String _propertyId = widget.properties.first.id;
  _Audience _audience = _Audience.all;
  String? _target;
  AnnouncementCategory _category = AnnouncementCategory.operations;
  AnnouncementPriority _priority = AnnouncementPriority.normal;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  AnnouncementProperty get _property =>
      widget.properties.firstWhere((property) => property.id == _propertyId);

  List<String> get _recipients => _property.rooms.entries
      .where(
        (entry) =>
            _audience == _Audience.all ||
            (_audience == _Audience.floor && '${entry.value}' == _target) ||
            (_audience == _Audience.room && entry.key == _target),
      )
      .map((entry) => entry.key)
      .toList();

  @override
  Widget build(BuildContext context) {
    final floors = _property.rooms.values.toSet().toList()..sort();
    final rooms = _recipients;
    return AlertDialog(
      title: const Text('Tạo thông báo'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhà trọ: ${_property.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<_Audience>(
                  initialValue: _audience,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Đối tượng nhận',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _Audience.all,
                      child: Text('Tất cả các phòng trong nhà trọ'),
                    ),
                    DropdownMenuItem(
                      value: _Audience.floor,
                      child: Text('Theo tầng'),
                    ),
                    DropdownMenuItem(
                      value: _Audience.room,
                      child: Text('Phòng cụ thể'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _audience = value!;
                    _target = null;
                  }),
                ),
                if (_audience != _Audience.all) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey('$_propertyId:${_audience.name}'),
                    initialValue: _target,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: _audience == _Audience.floor
                          ? 'Chọn tầng'
                          : 'Chọn phòng',
                    ),
                    items: _audience == _Audience.floor
                        ? [
                            for (final floor in floors)
                              DropdownMenuItem(
                                value: '$floor',
                                child: Text('Tầng $floor'),
                              ),
                          ]
                        : [
                            for (final room in _property.rooms.keys)
                              DropdownMenuItem(
                                value: room,
                                child: Text('Phòng $room'),
                              ),
                          ],
                    validator: (value) =>
                        value == null ? 'Chọn đối tượng nhận.' : null,
                    onChanged: (value) => setState(() => _target = value),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFEAF0FC),
                  child: Text(
                    'Nhận thông báo: ${rooms.length} phòng'
                    '${rooms.isEmpty ? '' : '\nPhòng ${rooms.join(', ')}'}',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AnnouncementCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Phân loại'),
                  items: [
                    for (final category in AnnouncementCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AnnouncementPriority>(
                  initialValue: _priority,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mức độ ưu tiên',
                  ),
                  items: [
                    for (final priority in AnnouncementPriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(priority.label),
                      ),
                  ],
                  onChanged: (value) => setState(() => _priority = value!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _title,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    hintText: 'Ví dụ: Tầng 2 - Thông báo cúp điện',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập tiêu đề thông báo.'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _content,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: const InputDecoration(labelText: 'Nội dung'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập nội dung thông báo.'
                      : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Gửi thử chỉ lưu trong phiên hiện tại, chưa gửi đến người thuê.',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12),
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
          icon: const Icon(Icons.send_outlined),
          label: const Text('Gửi thử'),
          onPressed: () {
            if (!_form.currentState!.validate() || rooms.isEmpty) return;
            final now = DateTime.now();
            final label = switch (_audience) {
              _Audience.all => 'Tất cả các phòng',
              _Audience.floor => 'Tầng $_target',
              _Audience.room => 'Phòng $_target',
            };
            Navigator.pop(
              context,
              LandlordAnnouncement(
                id: 'sent-${now.microsecondsSinceEpoch}',
                title: _title.text.trim(),
                content: _content.text.trim(),
                category: _category,
                priority: _priority,
                createdAt: now,
                propertyId: _propertyId,
                isRead: true,
                recipients: List.unmodifiable(rooms),
                audienceLabel: label,
              ),
            );
          },
        ),
      ],
    );
  }
}
