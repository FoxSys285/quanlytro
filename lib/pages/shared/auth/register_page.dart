import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/auth_validation.dart';
import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';
import 'auth_flow_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.initialEmail = '', this.auth});
  final String initialEmail;
  final LocalAuth? auth;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  LocalAuth get _auth => widget.auth ?? LocalAuth.instance;
  bool _accepted = false;
  bool _busy = false;
  AppRole _requestedRole = AppRole.tenant;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (!_accepted) {
      setState(
        () => _error =
            'Vui lòng đồng ý với điều khoản sử dụng và chính sách bảo mật.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.register(
        _email.text,
        _password.text,
        displayName: _name.text,
        phoneNumber: _phone.text,
        requestedRole: _requestedRole,
      );
      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message.toString()
              : 'Chưa thể tạo tài khoản. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthFlowScaffold(
    title: 'Tạo tài khoản',
    subtitle: 'Bắt đầu hành trình tìm trọ và quản lý\nkhông gian sống của bạn.',
    icon: Icons.person_add_alt_1_rounded,
    child: AutofillGroup(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFlowField(
              controller: _name,
              label: 'Họ và tên',
              hint: 'Nhập họ tên của bạn',
              icon: Icons.person_outline_rounded,
              enabled: !_busy,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                final name = (value ?? '').trim();
                return name.isEmpty || name.length > 100
                    ? 'Nhập họ tên từ 1 đến 100 ký tự.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: authGreen,
              value: _requestedRole == AppRole.landlord,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _requestedRole = value == true
                          ? AppRole.landlord
                          : AppRole.tenant;
                    }),
              title: const Text(
                'Đăng ký với tài khoản chủ trọ',
                style: TextStyle(
                  color: authInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Bỏ chọn nếu bạn đăng ký làm người thuê trọ.',
                style: TextStyle(color: authMuted, fontSize: 12),
              ),
            ),
            const AuthNotice(
              'Tài khoản dùng được ngay sau khi đăng ký. Nhà trọ vẫn cần được xác minh trước khi công khai.',
            ),
            const SizedBox(height: 16),
            AuthFlowField(
              controller: _email,
              label: 'Email',
              hint: 'Nhập email của bạn',
              icon: Icons.mail_outline_rounded,
              validator: validateAccountEmail,
              enabled: !_busy,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            AuthFlowField(
              controller: _phone,
              label: 'Số điện thoại',
              hint: 'Ví dụ: 0912 345 678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: validateAccountPhone,
              enabled: !_busy,
              autofillHints: const [AutofillHints.telephoneNumberNational],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Sau khi đăng ký, vào Cài đặt → Liên kết số điện thoại để xác minh OTP và bật đăng nhập bằng số điện thoại.',
                style: TextStyle(color: authMuted, fontSize: 11, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            AuthFlowField(
              controller: _password,
              label: 'Mật khẩu',
              hint: 'Tạo mật khẩu của bạn',
              icon: Icons.lock_outline_rounded,
              password: true,
              validator: validateAccountPassword,
              enabled: !_busy,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
              child: Text(
                'Ít nhất 8 ký tự, bao gồm chữ và số.',
                style: TextStyle(color: authMuted, fontSize: 11, height: 1.5),
              ),
            ),
            AuthFlowField(
              controller: _confirmation,
              label: 'Xác nhận mật khẩu',
              hint: 'Nhập lại mật khẩu',
              icon: Icons.lock_reset_rounded,
              password: true,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _register(),
              validator: (value) => value == null || value.isEmpty
                  ? 'Vui lòng xác nhận mật khẩu.'
                  : value != _password.text
                  ? 'Mật khẩu xác nhận chưa khớp.'
                  : null,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: authGreen,
              value: _accepted,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _accepted = value ?? false;
                      _error = null;
                    }),
              title: const Text(
                'Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật.',
                style: TextStyle(color: authMuted, fontSize: 12, height: 1.5),
              ),
            ),
            if (!_auth.isCloudMode) ...[
              const SizedBox(height: 8),
              const AuthNotice(
                'Bạn đang dùng bản dùng thử. Đăng ký qua email chưa khả dụng; bạn có thể trải nghiệm bằng tài khoản mẫu trên trang đăng nhập.',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthNotice(_error!, error: true),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Đăng ký tài khoản',
              busy: _busy,
              onPressed: _register,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Đã có tài khoản?',
                  style: TextStyle(color: authMuted, fontSize: 12),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: authGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
