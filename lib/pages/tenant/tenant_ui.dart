import 'package:flutter/material.dart';

const tenantGreen = Color(0xFF08A94F);
const tenantGreenDark = Color(0xFF08783B);
const tenantInk = Color(0xFF202332);
const tenantMuted = Color(0xFF676B78);
const tenantLine = Color(0xFFE8ECEB);
const tenantCanvas = Color(0xFFFCFCFC);

class TenantUiColors {
  const TenantUiColors({
    required this.primary,
    required this.dark,
    required this.softText,
    required this.light,
    required this.lighter,
    required this.avatar,
    required this.formEnd,
    required this.formTitle,
    required this.bannerEnd,
    required this.bannerTitle,
    required this.noteFill,
    required this.header,
    required this.headerMid,
    required this.headerFade,
    required this.canvas,
    required this.line,
    required this.inputFill,
    required this.chipFill,
    required this.chipSelected,
    required this.chipLine,
  });

  final Color primary;
  final Color dark;
  final Color softText;
  final Color light;
  final Color lighter;
  final Color avatar;
  final Color formEnd;
  final Color formTitle;
  final Color bannerEnd;
  final Color bannerTitle;
  final Color noteFill;
  final Color header;
  final Color headerMid;
  final Color headerFade;
  final Color canvas;
  final Color line;
  final Color inputFill;
  final Color chipFill;
  final Color chipSelected;
  final Color chipLine;

  static const tenant = TenantUiColors(
    primary: tenantGreen,
    dark: tenantGreenDark,
    softText: Color(0xFF4C6558),
    light: Color(0xFFEAF7EF),
    lighter: Color(0xFFE6F6ED),
    avatar: Color(0xFFE0F3E7),
    formEnd: Color(0xFFF5FBF7),
    formTitle: Color(0xFF123F29),
    bannerEnd: Color(0xFFD5F0E2),
    bannerTitle: Color(0xFF0A482C),
    noteFill: Color(0xFFEFF7F2),
    header: Color(0xFFF1FAF5),
    headerMid: Color(0xE6F1FAF5),
    headerFade: Color(0x00F1FAF5),
    canvas: tenantCanvas,
    line: tenantLine,
    inputFill: Color(0xFFF7F9F8),
    chipFill: Color(0xFFF3F8F5),
    chipSelected: Color(0xFFDFF3E7),
    chipLine: Color(0xFFE2ECE6),
  );

  static const landlord = TenantUiColors(
    primary: Color(0xFF1679BC),
    dark: Color(0xFF0D5B91),
    softText: Color(0xFF53697D),
    light: Color(0xFFEAF4FC),
    lighter: Color(0xFFE5F1FB),
    avatar: Color(0xFFDFEFFB),
    formEnd: Color(0xFFF6FAFE),
    formTitle: Color(0xFF17344F),
    bannerEnd: Color(0xFFD6EAF8),
    bannerTitle: Color(0xFF143B5C),
    noteFill: Color(0xFFEFF6FC),
    header: Color(0xFFF1F7FF),
    headerMid: Color(0xE6F1F7FF),
    headerFade: Color(0x00F1F7FF),
    canvas: Color(0xFFFCFDFF),
    line: Color(0xFFE2EAF2),
    inputFill: Color(0xFFF7FAFD),
    chipFill: Color(0xFFF2F6FA),
    chipSelected: Color(0xFFDCECF8),
    chipLine: Color(0xFFE2EAF2),
  );
}

class TenantUiPalette extends InheritedWidget {
  const TenantUiPalette({
    super.key,
    required this.landlordStyle,
    required super.child,
  });

  final bool landlordStyle;

  TenantUiColors get colors =>
      landlordStyle ? TenantUiColors.landlord : TenantUiColors.tenant;

  static TenantUiColors of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TenantUiPalette>()?.colors ??
      TenantUiColors.tenant;

  @override
  bool updateShouldNotify(TenantUiPalette oldWidget) =>
      landlordStyle != oldWidget.landlordStyle;
}

/// Shared mint backdrop for tenant screens, with a blue tint for landlord-style
/// feature pages that reuse the tenant components.
class TenantPageBackdrop extends StatelessWidget {
  const TenantPageBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.canvas,
        gradient: RadialGradient(
          center: const Alignment(0.62, -1.05),
          radius: 1.2,
          colors: [colors.bannerEnd, colors.header, colors.canvas],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: CustomPaint(
        painter: _TenantPageBackdropPainter(colors.primary),
        child: child,
      ),
    );
  }
}

class _TenantPageBackdropPainter extends CustomPainter {
  const _TenantPageBackdropPainter(this.tint);

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = tint.withValues(alpha: 0.045);
    canvas.drawCircle(Offset(size.width * 0.98, size.height * 0.12), 112, glow);
    canvas.drawCircle(Offset(size.width * 0.02, size.height * 0.48), 76, glow);
    canvas.drawCircle(Offset(size.width * 0.91, size.height * 0.78), 92, glow);
  }

  @override
  bool shouldRepaint(covariant _TenantPageBackdropPainter oldDelegate) =>
      tint != oldDelegate.tint;
}

class TenantPageFrame extends StatelessWidget {
  const TenantPageFrame({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    return TenantPageBackdrop(
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding:
                padding ??
                EdgeInsets.fromLTRB(
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
      ),
    );
  }
}

class TenantProfileAvatar extends StatelessWidget {
  const TenantProfileAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    final words = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final parts = words.toList();
    final initials = parts.isEmpty
        ? 'U'
        : parts.length == 1
        ? parts.first[0].toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius - 2,
        backgroundColor: colors.avatar,
        child: Text(
          initials,
          style: TextStyle(
            color: colors.dark,
            fontSize: radius * 0.55,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class TenantSelectedLocation extends ChangeNotifier {
  TenantSelectedLocation._();

  static final instance = TenantSelectedLocation._();

  static const defaultCity = 'TP. Tuy Hòa';
  String city = defaultCity;
  String? ward;
  bool hasSelection = false;

  void select({required String city, String? ward}) {
    this.city = city;
    this.ward = ward;
    hasSelection = true;
    notifyListeners();
  }

  void reset() {
    city = defaultCity;
    ward = null;
    hasSelection = false;
    notifyListeners();
  }

  void restore({String? city, String? ward}) {
    this.city = city ?? defaultCity;
    this.ward = city == null ? null : ward;
    hasSelection = city != null;
  }
}

class TenantHeader extends StatelessWidget {
  const TenantHeader({
    super.key,
    required this.profileName,
    required this.onAvatarTap,
    required this.onFavoritesTap,
    required this.onSettingsTap,
    this.overlay = false,
  });

  final String profileName;
  final VoidCallback onAvatarTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onSettingsTap;
  final bool overlay;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 7),
      child: Row(
        children: [
          Tooltip(
            message: 'Mở danh mục chức năng',
            child: Material(
              color: Colors.white.withValues(alpha: overlay ? 0.9 : 1),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAvatarTap,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: TenantProfileAvatar(name: profileName, radius: 26),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              profileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: tenantInk,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _TenantHeaderAction(
            tooltip: 'Y\u00eau th\u00edch',
            onTap: onFavoritesTap,
            icon: Icons.favorite_rounded,
            color: const Color(0xFFE93E78),
            overlay: overlay,
          ),
          const SizedBox(width: 8),
          _TenantHeaderAction(
            tooltip: 'C\u00e0i \u0111\u1eb7t',
            onTap: onSettingsTap,
            icon: Icons.settings_rounded,
            color: tenantInk,
            overlay: overlay,
          ),
        ],
      ),
    ),
  );
}

class _TenantHeaderAction extends StatelessWidget {
  const _TenantHeaderAction({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    required this.color,
    required this.overlay,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final bool overlay;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.white.withValues(alpha: overlay ? 0.94 : 1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: color, size: 23),
        ),
      ),
    ),
  );
}

class TenantPageTitle extends StatelessWidget {
  const TenantPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

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
  const TenantSectionHeading(this.title, {super.key, this.trailing});

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
          ?trailing,
        ],
      ),
    );
  }
}

class TenantSurface extends StatelessWidget {
  const TenantSurface({
    super.key,
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
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class TenantStatusPill extends StatelessWidget {
  const TenantStatusPill(
    this.label, {
    super.key,
    required this.color,
    this.icon,
  });

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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TenantOutlineAction extends StatelessWidget {
  const TenantOutlineAction({
    super.key,
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
    super.key,
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
  const TenantThinDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 7),
    child: Divider(height: 1, color: tenantLine),
  );
}

class TenantFeatureTag extends StatelessWidget {
  const TenantFeatureTag(this.label, {super.key});
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
    super.key,
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
  const TenantBottomSheetSurface({super.key, required this.child});
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
  const TenantSheetHandle({super.key});

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

/// Tiện ích mở rộng tính tổng (sum) giống cú pháp LINQ trong C#
extension TenantIterableNumX on Iterable<int> {
  int get sum => fold(0, (a, b) => a + b);
}
