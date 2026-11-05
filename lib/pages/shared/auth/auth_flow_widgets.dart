import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_brand.dart';
import 'login_artwork.dart';

const authGreen = Color(0xFF009B65);
const authInk = Color(0xFF25283F);
const authMuted = Color(0xFF667085);

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: authGreen),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: authGreen,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F9F4),
        body: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 100,
                    child: IgnorePointer(
                      child: CustomPaint(painter: LoginLandscapePainter()),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: authMuted,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                  ),
                                  label: const Text('Đăng nhập'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppLogo(size: 38),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      appName,
                                      style: TextStyle(
                                        color: authGreen,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: Colors.white),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x090D6948),
                                      blurRadius: 32,
                                      offset: Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFE8FAEE),
                                                Color(0xFFD3F4E4),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              23,
                                            ),
                                          ),
                                          child: Icon(
                                            icon,
                                            size: 33,
                                            color: authGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: authInk,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: authMuted,
                                          fontSize: 13,
                                          height: 1.6,
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      child,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthFlowField extends StatefulWidget {
  const AuthFlowField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.password = false,
    this.enabled = true,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool password;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  State<AuthFlowField> createState() => _AuthFlowFieldState();
}

class _AuthFlowFieldState extends State<AuthFlowField> {
  bool _obscure = true;
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (focused) => setState(() => _focused = focused),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _focused ? authGreen : const Color(0xFFE3EBE7),
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        validator: widget.validator,
        obscureText: widget.password && _obscure,
        keyboardType:
            widget.keyboardType ??
            (widget.password
                ? TextInputType.visiblePassword
                : TextInputType.emailAddress),
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        autocorrect: false,
        enableSuggestions: false,
        onFieldSubmitted: widget.onSubmitted,
        style: const TextStyle(color: authInk, fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: authMuted, fontSize: 15),
          hintStyle: const TextStyle(color: Color(0xFFA0AAB2), fontSize: 13),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorMaxLines: 3,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 14,
          ),
          prefixIcon: Icon(widget.icon, color: authGreen, size: 23),
          suffixIcon: widget.password
              ? IconButton(
                  tooltip:
                      '${_obscure ? 'Hiện' : 'Ẩn'} ${widget.label.toLowerCase()}',
                  onPressed: widget.enabled
                      ? () => setState(() => _obscure = !_obscure)
                      : null,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: authMuted,
                    size: 20,
                  ),
                )
              : null,
        ),
      ),
    ),
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00A86B), Color(0xFF00855F)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: const StadiumBorder(),
      ),
      child: busy
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
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Icon(icon, size: 20),
              ],
            ),
    ),
  );
}

class AuthNotice extends StatelessWidget {
  const AuthNotice(this.message, {super.key, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: error,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFFF1F0) : const Color(0xFFEDF9F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: error ? const Color(0xFFB73930) : authGreen,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: error
                    ? const Color(0xFFB73930)
                    : const Color(0xFF3F6C56),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
