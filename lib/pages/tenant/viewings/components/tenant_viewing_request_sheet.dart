import 'package:flutter/material.dart';

import '../../discovery/models/tenant_room_listing.dart';
import '../../tenant_ui.dart';
import '../models/tenant_viewing_request.dart';

class TenantViewingRequestSheet extends StatefulWidget {
  const TenantViewingRequestSheet({
    required this.room,
    this.initialName = '',
    this.initialPhone = '',
  });

  final TenantRoomListing room;
  final String initialName;
  final String initialPhone;

  @override
  State<TenantViewingRequestSheet> createState() =>
      _TenantViewingRequestSheetState();
}

class _TenantViewingRequestSheetState extends State<TenantViewingRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _phone = TextEditingController(text: widget.initialPhone);
  final _needs = TextEditingController();
  late DateTime _viewingDate = _dateOnly(
    DateTime.now().add(const Duration(days: 1)),
  );
  String _time = '10:00';
  int _attendeeCount = 1;
  String? _dateError;

  List<String> get _timeSlots => [
    for (var hour = 8; hour <= 19; hour++) ...[
      '${hour.toString().padLeft(2, '0')}:00',
      if (hour < 19) '${hour.toString().padLeft(2, '0')}:30',
    ],
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _needs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TenantBottomSheetSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TenantSheetHandle(),
        const Text(
          'Đặt lịch xem phòng',
          style: TextStyle(
            color: tenantInk,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Chọn thời gian mong muốn. Chủ trọ sẽ xác nhận lịch với bạn.',
          style: TextStyle(color: tenantMuted, fontSize: 12, height: 1.45),
        ),
        const SizedBox(height: 14),
        TenantSurface(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tenantGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: tenantGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.name,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.room.address} · ${formatTenantMoney(widget.room.price)}/tháng',
                      style: const TextStyle(color: tenantMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  hintText: 'Tên người liên hệ chính',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập họ tên để chủ trọ liên hệ.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'Số chủ trọ có thể gọi lại',
                ),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  if (digits.length < 9 || digits.length > 12) {
                    return 'Nhập số điện thoại hợp lệ.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _datePicker()),
                  const SizedBox(width: 10),
                  Expanded(child: _timePicker()),
                ],
              ),
              if (_dateError != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dateError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _attendeeCount,
                decoration: const InputDecoration(
                  labelText: 'Số người cùng đến xem',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: [
                  for (var count = 1; count <= 6; count++)
                    DropdownMenuItem(value: count, child: Text('$count người')),
                ],
                onChanged: (value) =>
                    setState(() => _attendeeCount = value ?? 1),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _needs,
                minLines: 2,
                maxLines: 3,
                maxLength: 240,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nhu cầu hoặc câu hỏi cho chủ trọ',
                  hintText:
                      'Ví dụ: cần chỗ để xe, xem nội thất, hỏi tiền cọc...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Gửi yêu cầu đặt lịch'),
            style: FilledButton.styleFrom(
              backgroundColor: tenantGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Center(
          child: Text(
            'Lịch ở trạng thái chờ cho đến khi chủ trọ xác nhận.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tenantMuted, fontSize: 10),
          ),
        ),
      ],
    ),
  );

  Widget _datePicker() => InkWell(
    onTap: _selectViewingDate,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Ngày muốn xem',
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 19),
        errorText: null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tenantLine),
        ),
      ),
      child: Text(
        '${_viewingDate.day.toString().padLeft(2, '0')}/${_viewingDate.month.toString().padLeft(2, '0')}/${_viewingDate.year}',
        style: const TextStyle(color: tenantInk, fontSize: 12),
      ),
    ),
  );

  Widget _timePicker() => DropdownButtonFormField<String>(
    initialValue: _time,
    decoration: const InputDecoration(
      labelText: 'Giờ mong muốn',
      prefixIcon: Icon(Icons.access_time_rounded, size: 19),
    ),
    items: [
      for (final time in _timeSlots)
        DropdownMenuItem(value: time, child: Text(time)),
    ],
    onChanged: (value) => setState(() => _time = value ?? _time),
  );

  Future<void> _selectViewingDate() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewingDate.isBefore(today) ? today : _viewingDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Chọn ngày muốn đến xem phòng',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _viewingDate = picked;
      _dateError = null;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final parts = _time.split(':');
    final startsAt = DateTime(
      _viewingDate.year,
      _viewingDate.month,
      _viewingDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    if (!startsAt.isAfter(DateTime.now())) {
      setState(() => _dateError = 'Chọn một khung giờ trong tương lai.');
      return;
    }
    Navigator.of(context).pop(
      TenantViewingRequest(
        customerName: _name.text.trim(),
        phone: _phone.text.trim(),
        startsAt: startsAt,
        attendeeCount: _attendeeCount,
        personalNeeds: _needs.text.trim(),
      ),
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
