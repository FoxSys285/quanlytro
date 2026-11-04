import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/auth_validation.dart';
import '../../../data/local_auth.dart';
import 'auth_flow_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = '', this.auth});
  final String initialEmail;
  final LocalAuth? auth;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  LocalAuth get _auth => widget.auth ?? LocalAuth.instance;
  bool _busy = false;
  bool _sent = false;
  int _seconds = 0;
  Timer? _cooldown;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _cooldown?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _seconds > 0 || (!_sent && !_form.currentState!.validate())) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.requestPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _seconds = 60;
      });
      _cooldown?.cancel();
      _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _seconds--);
        if (_seconds == 0) timer.cancel();
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message.toString()
              : 'Chưa gửi được email. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthFlowScaffold(
    title: _sent ? 'Kiểm tra email của bạn' : 'Quên mật khẩu?',
    subtitle: _sent
        ? 'Chỉ còn một bước để lấy lại quyền\ntruy cập tài khoản của bạn.'
        : 'Đừng lo, hãy nhập email đã đăng ký.\nChúng tôi sẽ giúp bạn đặt lại mật khẩu.',
    icon: _sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
    child: _sent
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nếu email này đã được đăng ký, bạn sẽ nhận được liên kết đặt lại mật khẩu tại:',
                textAlign: TextAlign.center,
                style: TextStyle(color: authMuted, fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 12),
              Text(
                _email.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: authGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const AuthNotice(
                'Mở liên kết trong email để tạo mật khẩu mới. Nếu chưa thấy thư, hãy kiểm tra mục Spam hoặc Thư rác.',
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AuthNotice(_error!, error: true),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Quay lại đăng nhập',
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(_email.text.trim()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy || _seconds > 0 ? null : _send,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _seconds > 0
                      ? 'Gửi lại liên kết (${_seconds}s)'
                      : 'Gửi lại liên kết',
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: authGreen,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        _cooldown?.cancel();
                        setState(() {
                          _sent = false;
                          _seconds = 0;
                          _error = null;
                        });
                      },
                child: const Text(
                  'Dùng email khác',
                  style: TextStyle(color: authMuted),
                ),
              ),
            ],
          )
        : Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthFlowField(
                  controller: _email,
                  label: 'Email đã đăng ký',
                  hint: 'Nhập email của bạn',
                  icon: Icons.mail_outline_rounded,
                  enabled: !_busy,
                  validator: validateAccountEmail,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _send(),
                ),
                const SizedBox(height: 18),
                AuthNotice(
                  _auth.isCloudMode
                      ? 'Liên kết khôi phục sẽ được gửi đến email đã đăng ký tài khoản của bạn.'
                      : 'Bản dùng thử không gửi email khôi phục. Tài khoản mẫu có mật khẩu ban đầu Tro@2026. Nếu đã đổi mật khẩu, vui lòng liên hệ quản trị viên.',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  AuthNotice(_error!, error: true),
                ],
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Gửi liên kết khôi phục',
                  icon: Icons.send_rounded,
                  busy: _busy,
                  onPressed: _send,
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 17),
                  label: const Text('Quay lại đăng nhập'),
                  style: TextButton.styleFrom(foregroundColor: authGreen),
                ),
              ],
            ),
          ),
  );
}
