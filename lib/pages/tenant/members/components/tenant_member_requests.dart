import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../landlord/landlord_demo_store.dart';
import '../../../landlord/finance/landlord_finance_models.dart';
import '../../../shared/rental/lease_member.dart';
import '../../tenant_ui.dart';

class TenantMemberRequests extends StatelessWidget {
  const TenantMemberRequests({
    super.key,
    required this.store,
    required this.tenantId,
  });
  final LandlordDemoStore store;
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final lease = store.currentLeaseForTenant(tenantId);
    if (lease == null) return const SizedBox.shrink();
    final requests = store.members
        .where(
          (member) =>
              member.leaseId == lease.id &&
              member.status != LeaseMemberStatus.active,
        )
        .toList();
    final count =
        store.membersForLease(lease.id).length +
        requests
            .where((member) => member.status == LeaseMemberStatus.pending)
            .length;
    final full = count >= (store.roomByCode(lease.room)?.capacity ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: full
              ? null
              : () async {
                  final sent = await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        _MemberRequestEditor(store: store, tenantId: tenantId),
                  );
                  if (sent == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã gửi yêu cầu thêm thành viên cho chủ trọ.',
                        ),
                      ),
                    );
                  }
                },
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text('Thêm thành viên'),
        ),
        Text(
          full
              ? 'Phòng đã đủ chỗ, bao gồm yêu cầu chờ duyệt.'
              : 'Thành viên mới sẽ được thêm vào phòng sau khi chủ trọ duyệt.',
          style: const TextStyle(fontSize: 12, color: tenantMuted),
        ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: 16),
          const TenantSectionHeading('Yêu cầu thêm thành viên'),
          for (final member in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TenantSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TenantStatusPill(
                      member.status == LeaseMemberStatus.pending
                          ? 'Chờ chủ trọ duyệt'
                          : 'Đã từ chối',
                      color: member.status == LeaseMemberStatus.pending
                          ? const Color(0xFFAB7623)
                          : Colors.red,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${member.phone} · Dự kiến ${landlordDate(member.joinedAt)}',
                    ),
                    if (member.rejectionReason != null)
                      Text(
                        'Lý do: ${member.rejectionReason}',
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _MemberRequestEditor extends StatefulWidget {
  const _MemberRequestEditor({required this.store, required this.tenantId});
  final LandlordDemoStore store;
  final String tenantId;

  @override
  State<_MemberRequestEditor> createState() => _MemberRequestEditorState();
}

class _MemberRequestEditorState extends State<_MemberRequestEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final lease = widget.store.currentLeaseForTenant(widget.tenantId);
    if (lease == null) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final end = DateUtils.dateOnly(lease.endDate);
    if (end.isBefore(today)) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: end,
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    try {
      widget.store.requestMember(
        tenantId: widget.tenantId,
        name: _name.text,
        phone: _phone.text,
        joinedAt: _date,
      );
      Navigator.pop(context, true);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Thêm thành viên'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gửi thông tin người ở cùng để chủ trọ xem xét.'),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Họ tên thành viên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập họ tên thành viên.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => !RegExp(r'^0\d{9}$').hasMatch(value ?? '')
                    ? 'Nhập số điện thoại 10 chữ số, bắt đầu bằng 0.'
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Ngày dự kiến vào ở'),
                subtitle: Text(landlordDate(_date)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickDate,
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
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
      FilledButton(onPressed: _submit, child: const Text('Gửi yêu cầu')),
    ],
  );
}
