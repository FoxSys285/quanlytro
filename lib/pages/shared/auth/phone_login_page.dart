import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/account_provider.dart';
import '../../../data/auth_validation.dart';
import '../../../data/local_auth.dart';
import 'auth_flow_widgets.dart';

enum PhoneLoginResult { signedIn, needsProfile, linked }

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({
    super.key,
    this.auth,
    this.initialPhone = '',
    this.linkToCurrentUser = false,
  });
  final LocalAuth? auth;
  final String initialPhone;
  final bool linkToCurrentUser;

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.initialPhone);
  final _code = TextEditingController();
  LocalAuth get _auth => widget.auth ?? LocalAuth.instance;
  PhoneCodeChallenge? _challenge;
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  bool _completed = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    if (_busy || _completed || _seconds > 0) return;
    final error = validateAccountPhone(_phone.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await _auth.requestPhoneCode(
        _phone.text,
        resendToken: _challenge?.resendToken,
        linkToCurrentUser: widget.linkToCurrentUser,
      );
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _code.clear();
        _startCooldown();
      });
      if (challenge.automaticallyVerified) await _confirm(automatic: true);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm({bool automatic = false}) async {
    if (_completed ||
        (!automatic && (_busy || !_form.currentState!.validate()))) {
      return;
    }
    final challenge = _challenge;
    if (challenge == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signedIn = await _auth.confirmPhoneCode(
        challenge,
        _code.text.trim(),
        linkToCurrentUser: widget.linkToCurrentUser,
      );
      _completed = true;
      if (!mounted) return;
      Navigator.of(context).pop(
        widget.linkToCurrentUser
            ? PhoneLoginResult.linked
            : signedIn
            ? PhoneLoginResult.signedIn
            : PhoneLoginResult.needsProfile,
      );
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) => error is ArgumentError
      ? error.message.toString()
      : 'Chưa thể xác thực số điện thoại. Vui lòng thử lại.';

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AuthFlowScaffold(
      title: widget.linkToCurrentUser
          ? 'Liên kết số điện thoại'
          : 'Đăng nhập bằng số điện thoại',
      subtitle: _challenge == null
          ? 'Nhận mã OTP qua SMS để xác minh số điện thoại của bạn.'
          : 'Nhập mã xác thực được gửi đến ${normalizeVietnamesePhone(_phone.text)}.',
      icon: Icons.sms_outlined,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFlowField(
              controller: _phone,
              label: 'Số điện thoại',
              hint: '0912 345 678 hoặc +84…',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              enabled: !_busy && _challenge == null,
              validator: validateAccountPhone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
            ),
            const SizedBox(height: 16),
            if (_challenge == null) ...[
              const AuthNotice(
                'Số điện thoại được gửi đến Google/Firebase để xác thực và chống lạm dụng. Khi tiếp tục, bạn đồng ý với việc này.',
              ),
              if (!widget.linkToCurrentUser) ...[
                const SizedBox(height: 12),
                const AuthNotice(
                  'Đã có tài khoản email? Hãy đăng nhập bằng email, vào Cài đặt → Liên kết số điện thoại trước để dùng chung tài khoản.',
                ),
              ],
            ] else ...[
              AuthFlowField(
                controller: _code,
                label: 'Mã OTP',
                hint: 'Nhập mã gồm 6 số',
                icon: Icons.password_rounded,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                onSubmitted: (_) => _confirm(),
                validator: (value) =>
                    RegExp(r'^[0-9]{6}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Nhập mã OTP gồm 6 chữ số.',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthNotice(_error!, error: true),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: _challenge == null
                  ? _seconds > 0
                        ? 'Gửi mã OTP (${_seconds}s)'
                        : 'Gửi mã OTP'
                  : 'Xác nhận mã OTP',
              busy: _busy,
              onPressed: _challenge == null
                  ? _seconds > 0
                        ? null
                        : _send
                  : () => _confirm(),
            ),
            if (_challenge != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy || _seconds > 0 ? null : _send,
                child: Text(
                  _seconds > 0 ? 'Gửi lại mã (${_seconds}s)' : 'Gửi lại mã',
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _challenge = null;
                        _code.clear();
                        _error = null;
                        // Preserve the cooldown when changing the number.
                      }),
                child: const Text('Dùng số điện thoại khác'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
