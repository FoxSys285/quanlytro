import 'package:flutter/material.dart';

const tenantGreen = Color(0xFF16836F);
const tenantGreenDark = Color(0xFF106B5A);
const tenantInk = Color(0xFF1B2935);
const tenantMuted = Color(0xFF74818C);
const tenantLine = Color(0xFFE7ECEF);
const tenantCanvas = Color(0xFFF5F7F8);

class TenantPageFrame extends StatelessWidget {
  const TenantPageFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth < 600 ? 18 : 32,
            22,
            constraints.maxWidth < 600 ? 18 : 32,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TenantPageTitle extends StatelessWidget {
  const TenantPageTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: tenantInk,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: tenantMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class TenantSectionHeading extends StatelessWidget {
  const TenantSectionHeading(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: tenantInk,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class TenantSurface extends StatelessWidget {
  const TenantSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tenantLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x071B2935),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class TenantStatusPill extends StatelessWidget {
  const TenantStatusPill(this.label, {required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TenantOutlineAction extends StatelessWidget {
  const TenantOutlineAction({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () => showTenantPreviewNotice(context),
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: tenantGreenDark,
        side: const BorderSide(color: Color(0xFFD5E7E2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      ),
    );
  }
}

void showTenantPreviewNotice(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'Bản xem trước giao diện · Chức năng chưa kết nối hệ thống',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

String formatTenantMoney(int amount) {
  final digits = amount.toString();
  final result = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    result.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) result.write('.');
  }
  return '${result.toString()} đ';
}

class TenantDataRow extends StatelessWidget {
  const TenantDataRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
    this.onTap,
  });
  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? tenantInk : tenantMuted,
              fontSize: 11,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: InkWell(
            onTap: onTap,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    valueColor ??
                    (emphasized ? tenantInk : const Color(0xFF43515D)),
                fontSize: 11,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class TenantThinDivider extends StatelessWidget {
  const TenantThinDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 7),
    child: Divider(height: 1, color: tenantLine),
  );
}

class TenantFeatureTag extends StatelessWidget {
  const TenantFeatureTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6F4),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: tenantGreenDark,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class TenantEmptyState extends StatelessWidget {
  const TenantEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => TenantSurface(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF9AA6AE)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: tenantInk,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: tenantMuted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class TenantBottomSheetSurface extends StatelessWidget {
  const TenantBottomSheetSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        4,
        18,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: tenantCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(child: child),
    ),
  );
}

class TenantSheetHandle extends StatelessWidget {
  const TenantSheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 37,
      height: 4,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFD5DDE1),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
