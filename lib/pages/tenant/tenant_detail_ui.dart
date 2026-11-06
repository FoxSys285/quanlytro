import 'package:flutter/material.dart';

import 'tenant_ui.dart';
import 'tenant_navigation_bar.dart';

/// Shared styling for the tenant's account and housing detail flows.
class TenantDetailTheme extends StatelessWidget {
  const TenantDetailTheme({
    super.key,
    required this.child,
    this.landlordStyle = false,
  });

  final Widget child;
  final bool landlordStyle;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final colors = landlordStyle
        ? TenantUiColors.landlord
        : TenantUiColors.tenant;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.line),
    );
    return TenantUiPalette(
      landlordStyle: landlordStyle,
      child: Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: colors.primary,
            secondary: colors.dark,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: tenantInk,
          ),
          scaffoldBackgroundColor: colors.canvas,
          appBarTheme: AppBarTheme(
            backgroundColor: colors.canvas,
            foregroundColor: tenantInk,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontFamily: base.textTheme.titleLarge?.fontFamily,
              color: tenantInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colors.inputFill,
            contentPadding: const EdgeInsets.all(16),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            labelStyle: const TextStyle(color: tenantMuted, fontSize: 13),
            prefixIconColor: colors.dark,
            suffixIconColor: tenantMuted,
            errorMaxLines: 3,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: TextStyle(
                fontFamily: base.textTheme.labelLarge?.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.dark,
              minimumSize: const Size(0, 46),
              side: BorderSide(color: colors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: colors.dark),
          ),
          dividerTheme: DividerThemeData(color: colors.line, thickness: 1),
          chipTheme: base.chipTheme.copyWith(
            backgroundColor: colors.chipFill,
            selectedColor: colors.chipSelected,
            side: BorderSide(color: colors.chipLine),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            labelStyle: TextStyle(
              fontFamily: base.textTheme.labelLarge?.fontFamily,
              color: colors.dark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            checkmarkColor: colors.dark,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titleTextStyle: TextStyle(
              fontFamily: base.textTheme.titleLarge?.fontFamily,
              color: tenantInk,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class TenantSubpageScaffold extends StatelessWidget {
  const TenantSubpageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.appBar,
    this.showNotifications = true,
    this.landlordStyle = false,
  });

  final String title;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool showNotifications;
  final bool landlordStyle;

  @override
  Widget build(BuildContext context) => TenantDetailTheme(
    landlordStyle: landlordStyle,
    child: Scaffold(
      appBar:
          appBar ??
          TenantNavigationBar(
            title: title,
            onBack: () => Navigator.of(context).maybePop(),
            showNotifications: showNotifications,
          ),
      body: child,
    ),
  );
}

class TenantDetailFrame extends StatelessWidget {
  const TenantDetailFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      TenantDetailTheme(child: TenantPageFrame(children: children));
}

class TenantDetailIntro extends StatelessWidget {
  const TenantDetailIntro({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 22),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE3F6E9), Color(0xFFF3FAF5)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFDCEEE2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TenantDetailIcon(icon, size: 46),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102B1B),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: tenantMuted, fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );
}

class TenantDetailIcon extends StatelessWidget {
  const TenantDetailIcon(this.icon, {super.key, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.noteFill,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: colors.dark, size: size * 0.52),
    );
  }
}

class TenantDetailRow extends StatelessWidget {
  const TenantDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: tenantMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: SelectableText(
            value.isEmpty ? 'Chưa cập nhật' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: emphasized ? tenantGreenDark : tenantInk,
              fontSize: 13,
              height: 1.5,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class TenantDetailNote extends StatelessWidget {
  const TenantDetailNote(
    this.message, {
    super.key,
    this.icon = Icons.info_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.dark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: tenantMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
