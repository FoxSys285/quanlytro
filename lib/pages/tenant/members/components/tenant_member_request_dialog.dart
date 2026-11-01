import 'package:flutter/material.dart';

import '../../../landlord/landlord_demo_store.dart';

class TenantMemberRequestDialog extends StatefulWidget {
  const TenantMemberRequestDialog({
    super.key,
    required this.store,
    required this.tenantId,
  });
  final LandlordDemoStore store;
  final String tenantId;
  @override
  State<TenantMemberRequestDialog> createState() =>
      _TenantMemberRequestDialogState();
}

class _TenantMemberRequestDialogState extends State<TenantMemberRequestDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đề nghị thêm thành viên'),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chủ trọ sẽ kiểm tra và duyệt trước khi thành viên được thêm vào phòng.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 20,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
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
          try {
            widget.store.requestMember(
              tenantId: widget.tenantId,
              name: _name.text,
              phone: _phone.text,
            );
            Navigator.pop(context);
          } on ArgumentError catch (e) {
            setState(() => _error = e.message.toString());
          }
        },
        child: const Text('Gửi đề nghị'),
      ),
    ],
  );
}
