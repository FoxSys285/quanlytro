import 'package:flutter/material.dart';

import '../../../data/auth_validation.dart';
import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';
import 'auth_flow_widgets.dart';

class ProviderRegistrationPage extends StatefulWidget {
  const ProviderRegistrationPage({super.key, required this.auth});
  final LocalAuth auth;

  @override
  State<ProviderRegistrationPage> createState() =>
      _ProviderRegistrationPageState();
}

class _ProviderRegistrationPageState extends State<ProviderRegistrationPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.auth.pendingIdentity?.displayName ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.auth.pendingIdentity?.phoneNumber ?? '',
  );
  AppRole _role = AppRole.tenant;
  bool _accepted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (!_accepted) {
      setState(
        () => _error =
            'Vui lòng đồng ý với điều khoản sử dụng và chính sách bảo mật.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.completeProviderRegistration(
        displayName: _name.text,
        phoneNumber: _phone.text,
        requestedRole: _role,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message.toString()
              : 'Chưa lưu được hồ sơ. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AuthFlowScaffold(
      title: 'Hoàn thiện tài khoản',
      subtitle: 'Bạn đã xác thực thành công. Hãy bổ sung thông tin để bắt đầu.',
      icon: Icons.person_add_alt_1_outlined,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFlowField(
              controller: _name,
              label: 'Họ và tên',
              hint: 'Nhập họ tên của bạn',
              icon: Icons.person_outline,
              enabled: !_busy,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value?.trim().isEmpty ?? true) || value!.trim().length > 100
                  ? 'Nhập họ tên từ 1 đến 100 ký tự.'
                  : null,
            ),
            const SizedBox(height: 16),
            AuthFlowField(
              controller: _phone,
              label: 'Số điện thoại',
              hint: 'Nhập số điện thoại của bạn',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              enabled:
                  !_busy &&
                  (widget.auth.pendingIdentity?.phoneNumber.isEmpty ?? true),
              validator: validateAccountPhone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đăng ký với tài khoản chủ trọ'),
              subtitle: const Text('Bỏ chọn nếu bạn là người thuê trọ.'),
              value: _role == AppRole.landlord,
              onChanged: _busy
                  ? null
                  : (value) => setState(
                      () => _role = value == true
                          ? AppRole.landlord
                          : AppRole.tenant,
                    ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật.',
              ),
              value: _accepted,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _accepted = value ?? false),
            ),
            if (_error != null) AuthNotice(_error!, error: true),
            const SizedBox(height: 16),
            AuthPrimaryButton(
              label: 'Hoàn tất đăng ký',
              busy: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );
}
