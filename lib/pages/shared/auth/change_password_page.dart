import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';
import '../../tenant/tenant_detail_ui.dart';
import '../../tenant/tenant_ui.dart';
import '../../tenant/tenant_feature_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.role});
  final AppRole? role;
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  final _visible = [false, false, false];
  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Mật khẩu nhập lại không khớp.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await LocalAuth.instance.changePassword(_current.text, _password.text);
      await AppPersistence.current?.flush();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu.')));
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((widget.role ?? LocalAuth.instance.role) == AppRole.tenant) {
      return TenantFeatureFrame(
        artwork: TenantFeatureArtwork.settings,
        title: 'Bảo mật tài khoản',
        subtitle: 'Cập nhật mật khẩu để bảo vệ tài khoản của bạn.',
        children: [
          const TenantSectionHeading('Đổi mật khẩu'),
          TenantSurface(
            child: Column(
              children: [
                _passwordField(_current, 'Mật khẩu hiện tại', 0),
                const SizedBox(height: 16),
                _passwordField(_password, 'Mật khẩu mới', 1),
                const SizedBox(height: 16),
                _passwordField(_confirm, 'Nhập lại mật khẩu mới', 2),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const TenantDetailNote(
            'Mật khẩu cần ít nhất 8 ký tự, bao gồm chữ và số.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 19),
              label: Text(_busy ? 'Đang lưu…' : 'Lưu mật khẩu'),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Đổi mật khẩu',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text('Ít nhất 8 ký tự, bao gồm chữ và số.'),
        const SizedBox(height: 24),
        TextField(
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirm,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Đang lưu…' : 'Lưu mật khẩu'),
        ),
      ],
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    int index,
  ) => TextField(
    controller: controller,
    enabled: !_busy,
    obscureText: !_visible[index],
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: index == 2 ? TextInputAction.done : TextInputAction.next,
    onSubmitted: index == 2 ? (_) => _save() : null,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
      suffixIcon: IconButton(
        tooltip: _visible[index] ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
        onPressed: () => setState(() => _visible[index] = !_visible[index]),
        icon: Icon(
          _visible[index]
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20,
        ),
      ),
    ),
  );
}
