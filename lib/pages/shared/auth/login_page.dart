import 'package:flutter/material.dart';

import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'landlord@tro.local');
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await LocalAuth.instance.signIn(_email.text, _password.text);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6F4EF), Color(0xFFF4F7FC), Color(0xFFE7EFFF)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFE4F4ED),
                          child: Icon(
                            Icons.apartment_rounded,
                            size: 34,
                            color: Color(0xFF16836F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Nhà trọ của bạn,\nquản lý thật dễ.',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B2935),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Đăng nhập để quản lý nhà trọ và theo dõi việc thuê phòng.',
                        style: TextStyle(color: Colors.blueGrey, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        enabled: !_busy,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _login,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Đăng nhập'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tài khoản mẫu trên thiết bị',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final role in AppRole.values)
                            ActionChip(
                              avatar: Icon(role.icon, size: 18),
                              label: Text(role.label),
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _email.text = LocalAuth.emailFor(role);
                                      _password.text = 'Tro@2026';
                                      _error = null;
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Mật khẩu ban đầu: Tro@2026. Dữ liệu được lưu riêng trên thiết bị này.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
