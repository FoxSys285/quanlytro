import 'package:flutter/material.dart';

const landlordBlue = Color(0xFF3769D6);
const landlordInk = Color(0xFF1B2935);
const landlordMuted = Color(0xFF74818C);
const landlordLine = Color(0xFFE7ECEF);
const landlordCanvas = Color(0xFFF5F7FA);

class LandlordPageFrame extends StatelessWidget {
  const LandlordPageFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class LandlordPageTitle extends StatelessWidget {
  const LandlordPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: landlordInk,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: landlordMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class LandlordCard extends StatelessWidget {
  const LandlordCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: landlordLine),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class LandlordStatusPill extends StatelessWidget {
  const LandlordStatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LandlordEmptyState extends StatelessWidget {
  const LandlordEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return LandlordCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: landlordMuted),
        ),
      ),
    );
  }
}

void showLandlordMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

String formatLandlordMoney(int amount) {
  final digits = amount.toString();
  final result = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    result.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) result.write('.');
  }
  return '${result.toString()} đ';
}
