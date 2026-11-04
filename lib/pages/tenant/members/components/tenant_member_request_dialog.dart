import 'package:flutter/material.dart';

import '../../../landlord/landlord_demo_store.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_feature_ui.dart';

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
  Widget build(BuildContext context) => TenantDetailTheme(
    child: AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      title: const TenantFormHeading(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Đề nghị thêm thành viên',
        subtitle: 'Chủ trọ sẽ kiểm tra trước khi thêm người ở cùng vào phòng.',
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
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
    ),
  );
}
