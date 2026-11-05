import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/local_auth.dart';
import '../../../data/account_provider.dart';
import '../../../data/auth_validation.dart';
import '../../../layouts/role_layout.dart';
import 'forgot_password_page.dart';
import 'login_artwork.dart';
import 'register_page.dart';
import 'phone_login_page.dart';
import 'provider_registration_page.dart';

const _green = Color(0xFF009B65);
const _ink = Color(0xFF25283F);
const _muted = Color(0xFF596078);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.auth});
  final LocalAuth? auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  LocalAuth get _auth => widget.auth ?? LocalAuth.instance;
  bool get _usingPhone =>
      _email.text.trim().isNotEmpty && !_email.text.contains('@');

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_refreshFocus);
    _passwordFocus.addListener(_refreshFocus);
  }

  void _refreshFocus() => setState(() {});

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    if (_usingPhone) {
      final error = validateAccountPhone(_email.text);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      await _phoneLogin(initialPhone: _email.text);
      return;
    }
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập email hoặc số điện thoại.');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.signIn(_email.text, _password.text);
      if (mounted) TextInput.finishAutofillContext();
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } catch (e) {
      if (mounted) setState(() => _error = 'Đăng nhập không thành công: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeProviderProfile() async {
    if (!mounted) return;
    final complete = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProviderRegistrationPage(auth: _auth)),
    );
    if (complete != true && _auth.role == null) await _auth.signOut();
  }

  Future<void> _googleLogin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signedIn = await _auth.signInWithGoogle();
      if (!signedIn && mounted) await _completeProviderProfile();
    } on AccountSignInCancelled {
      // Closing the account chooser leaves the login page ready to retry.
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message.toString()
              : 'Chưa thể đăng nhập Google. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _phoneLogin({String initialPhone = ''}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await Navigator.of(context).push<PhoneLoginResult>(
        MaterialPageRoute(
          builder: (_) =>
              PhoneLoginPage(auth: _auth, initialPhone: initialPhone),
        ),
      );
      if (result == PhoneLoginResult.needsProfile && mounted) {
        await _completeProviderProfile();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ArgumentError
              ? error.message.toString()
              : 'Chưa thể đăng nhập bằng số điện thoại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showInfo(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAuthPage(Widget page) async {
    final email = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => page));
    if (!mounted || email == null) return;
    setState(() {
      _email.text = email;
      _password.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFB8EFD6),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: _green),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F9F5),
        body: LayoutBuilder(
          builder: (context, viewport) {
            final wide = viewport.maxWidth >= 860;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE9F7F0), Color(0xFFF6FAF9)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 120,
                        child: IgnorePointer(
                          child: CustomPaint(painter: LoginLandscapePainter()),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: wide ? 1180 : 600,
                            ),
                            child: Column(
                              children: [
                                if (wide)
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      32,
                                      MediaQuery.paddingOf(context).top + 64,
                                      32,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: LoginHero(wide: true),
                                        ),
                                        const SizedBox(width: 36),
                                        SizedBox(width: 450, child: _form()),
                                      ],
                                    ),
                                  )
                                else ...[
                                  const LoginHero(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: _form(),
                                  ),
                                ],
                                _footer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _form() => Container(
    padding: const EdgeInsets.fromLTRB(17, 18, 17, 18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060A694B),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            label: 'Email hoặc số điện thoại',
            hint: 'Email hoặc số điện thoại',
            icon: Icons.mail_outline_rounded,
            controller: _email,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 8),
            child: Text(
              'Email dùng mật khẩu. Số điện thoại dùng mã OTP qua SMS.',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          _field(
            label: 'Mật khẩu',
            hint: 'Nhập mật khẩu',
            icon: Icons.lock_outline_rounded,
            controller: _password,
            password: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => _openAuthPage(
                      ForgotPasswordPage(
                        initialEmail: _usingPhone ? '' : _email.text.trim(),
                        auth: widget.auth,
                      ),
                    ),
              style: TextButton.styleFrom(
                foregroundColor: _green,
                padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                minimumSize: const Size(48, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: _green,
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFBC3030),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 2),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF00A56B), Color(0xFF00855F)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16009B65),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _busy ? null : _login,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _usingPhone ? 'Nhận mã OTP' : 'Đăng nhập',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 21),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Chưa có tài khoản?',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _openAuthPage(
                        RegisterPage(
                          initialEmail: _usingPhone ? '' : _email.text.trim(),
                          auth: widget.auth,
                        ),
                      ),
                style: TextButton.styleFrom(foregroundColor: _green),
                child: const Text(
                  'Đăng ký ngay',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Stack(
            key: ValueKey('login-alternative-divider'),
            alignment: Alignment.center,
            children: [
              Divider(color: Color(0xFFE6E8EF)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Hoặc đăng nhập bằng',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _provider(
                'Google',
                const CustomPaint(
                  size: Size(21, 21),
                  painter: GoogleMarkPainter(),
                ),
                _googleLogin,
              ),
              const SizedBox(width: 10),
              _provider(
                'Số điện thoại',
                const Icon(
                  Icons.phone_iphone_rounded,
                  size: 22,
                  color: Color(0xFF1A5949),
                ),
                () => _phoneLogin(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 6,
            children: [
              const Text(
                'Điền nhanh tài khoản',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _auth.isCloudMode ? 'Firebase Cloud' : 'Bản nội bộ',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCloud = _auth.isCloudMode;
              final accounts = isCloud
                  ? [
                      (
                        role: AppRole.admin,
                        email: 'admin@ex.com',
                        label: 'Quản trị viên',
                      ),
                      (
                        role: AppRole.landlord,
                        email: 'landlord@ex.com',
                        label: 'Chủ trọ',
                      ),
                      (
                        role: AppRole.tenant,
                        email: 'tentant@ex.com',
                        label: 'Người thuê',
                      ),
                    ]
                  : [
                      for (final role in AppRole.values)
                        (
                          role: role,
                          email: LocalAuth.emailFor(role),
                          label: role.label,
                        ),
                    ];
              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final acc in accounts)
                    ActionChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: Icon(acc.role.icon, size: 16, color: _green),
                      label: Text(acc.label),
                      labelStyle: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: const Color(0xFFEAF9F0),
                      side: const BorderSide(color: Color(0xFFBFEDD4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _email.text = acc.email;
                              _password.text = isCloud
                                  ? 'Test123456'
                                  : 'Tro@2026';
                              _error = null;
                            }),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool password = false,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFC),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: (password ? _passwordFocus : _emailFocus).hasFocus
            ? _green
            : const Color(0xFFE7E8F0),
      ),
    ),
    child: TextField(
      controller: controller,
      focusNode: password ? _passwordFocus : _emailFocus,
      enabled: !_busy,
      obscureText: password && _obscure,
      keyboardType: password
          ? TextInputType.visiblePassword
          : TextInputType.text,
      onChanged: password ? null : (_) => setState(() {}),
      textInputAction: password ? TextInputAction.done : TextInputAction.next,
      autofillHints: [
        password ? AutofillHints.password : AutofillHints.username,
      ],
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) {
        if (password) {
          _login();
        } else {
          _passwordFocus.requestFocus();
        }
      },
      style: const TextStyle(color: _ink, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(color: _muted, fontSize: 15),
        hintStyle: const TextStyle(color: Color(0xFFA4A8B9), fontSize: 14),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _green, size: 23),
          ),
        ),
        suffixIcon: password
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Dán mật khẩu',
                    onPressed: _busy
                        ? null
                        : () async {
                            final data = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            if (data?.text != null && data!.text!.isNotEmpty) {
                              setState(() {
                                controller.text = data.text!;
                                _error = null;
                              });
                            }
                          },
                    icon: const Icon(
                      Icons.content_paste_rounded,
                      color: Color(0xFF73788E),
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: _busy
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF73788E),
                      size: 21,
                    ),
                  ),
                ],
              )
            : IconButton(
                tooltip: 'Dán email hoặc số điện thoại',
                onPressed: _busy
                    ? null
                    : () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (data?.text != null &&
                            data!.text!.trim().isNotEmpty) {
                          setState(() {
                            controller.text = data.text!.trim();
                            _error = null;
                          });
                        }
                      },
                icon: const Icon(
                  Icons.content_paste_rounded,
                  color: Color(0xFF73788E),
                  size: 20,
                ),
              ),
      ),
    ),
  );

  Widget _provider(
    String label,
    Widget icon,
    VoidCallback onPressed,
  ) => Expanded(
    child: OutlinedButton(
      onPressed: _busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        backgroundColor: const Color(0xFFFCFCFE),
        side: const BorderSide(color: Color(0xFFE5E7EF)),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );

  Widget _footer() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 92),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5, right: 8),
          child: Icon(Icons.verified_user_rounded, color: _green, size: 20),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bằng việc đăng nhập, bạn đồng ý với',
                style: TextStyle(color: _muted, fontSize: 10, height: 1.6),
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _legalLink(
                    'Điều khoản sử dụng',
                    'Bạn có trách nhiệm bảo mật thông tin đăng nhập và chỉ sử dụng dữ liệu đúng quyền tài khoản được cấp.',
                  ),
                  const Text(
                    ' và ',
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                  _legalLink(
                    'Chính sách bảo mật',
                    LocalAuth.instance.isCloudMode
                        ? 'Dữ liệu và quyền truy cập được tải từ Firebase sau khi đăng nhập. Tài khoản chưa được admin cấp quyền sẽ không vào được dữ liệu nghiệp vụ.'
                        : 'Bản dùng thử lưu dữ liệu trên thiết bị. Không dùng thông tin cá nhân thật khi trải nghiệm.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _legalLink(String title, String content) => InkWell(
    onTap: () => _showInfo(title, content),
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        title,
        style: const TextStyle(
          color: _green,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: _green,
        ),
      ),
    ),
  );
}
