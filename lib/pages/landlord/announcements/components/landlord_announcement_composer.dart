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
  final _selectedRooms = <String>{};
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
            (_audience == _Audience.room && _selectedRooms.contains(entry.key)),
      )
      .map((entry) => entry.key)
      .toList();

  @override
  Widget build(BuildContext context) {
    final floors = _property.rooms.values.toSet().toList()..sort();
    final rooms = _recipients;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
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
                      child: Text('Chọn nhiều phòng'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _audience = value!;
                    _target = null;
                    _selectedRooms.clear();
                  }),
                ),
                if (_audience == _Audience.floor) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey('$_propertyId:${_audience.name}'),
                    initialValue: _target,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Chọn tầng'),
                    items: [
                      for (final floor in floors)
                        DropdownMenuItem(
                          value: '$floor',
                          child: Text('Tầng $floor'),
                        ),
                    ],
                    validator: (value) =>
                        value == null ? 'Chọn đối tượng nhận.' : null,
                    onChanged: (value) => setState(() => _target = value),
                  ),
                ],
                if (_audience == _Audience.room) ...[
                  const SizedBox(height: 16),
                  FormField<Set<String>>(
                    initialValue: Set.unmodifiable(_selectedRooms),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Chọn ít nhất một phòng nhận thông báo.'
                        : null,
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn phòng',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bấm vào phòng để chọn hoặc bỏ chọn.',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final floor in floors) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6),
                            child: Text(
                              'Tầng $floor',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final room in _property.rooms.entries.where(
                                (item) => item.value == floor,
                              ))
                                FilterChip(
                                  label: Text('Phòng ${room.key}'),
                                  selected: _selectedRooms.contains(room.key),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedRooms.add(room.key);
                                      } else {
                                        _selectedRooms.remove(room.key);
                                      }
                                    });
                                    field.didChange(
                                      Set.unmodifiable(_selectedRooms),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
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
              _Audience.room =>
                rooms.length == 1
                    ? 'Phòng ${rooms.single}'
                    : 'Các phòng được chọn (${rooms.length})',
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
