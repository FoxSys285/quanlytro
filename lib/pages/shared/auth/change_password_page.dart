import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../../../data/local_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
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
  Widget build(BuildContext context) => ListView(
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
