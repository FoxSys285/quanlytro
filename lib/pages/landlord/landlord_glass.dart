import 'package:flutter/material.dart';

import '../../data/local_auth.dart';
import '../../layouts/landlord_navigation.dart';
import '../../layouts/role_layout.dart';
import '../shared/settings/account_settings_page.dart';
import 'landlord_demo_store.dart';
import 'landlord_theme.dart';
import 'properties/components/property_portfolio_visuals.dart';
import 'properties/landlord_properties_page.dart';

export 'properties/components/property_portfolio_visuals.dart'
    show
        propertyBlue,
        propertyInk,
        propertyMuted,
        PropertyPortfolioBackdrop,
        PropertyPortfolioSummary;

void openLandlordDestination(
  BuildContext context,
  String destination,
  String title,
  Widget page,
) {
  if (RoleLayoutShell.tryNavigateTo(context, destination)) return;
  LandlordNavigation.push<void>(
    context,
    page: page,
    destinationId: destination,
    title: title,
  );
}

class LandlordGlassPage extends StatelessWidget {
  const LandlordGlassPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.kicker,
    required this.children,
    this.profileName,
    this.store,
  });
  final String title;
  final String subtitle;
  final String kicker;
  final String? profileName;
  final LandlordDemoStore? store;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rental = store ?? LandlordDemoStore.activeInstance;
    final owner =
        profileName ??
        LocalAuth.instance.session?.displayName ??
        rental.property.ownerName;
    return PropertyPortfolioBackdrop(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: PageStorageKey('landlord-glass-$kicker'),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PropertyProfileHeader(
                    name: owner.trim().isEmpty ? 'Chủ trọ' : owner,
                    onMenu: () => Scaffold.of(context).openDrawer(),
                    onActiveProperty: () => openLandlordDestination(
                      context,
                      'properties',
                      'Nhà trọ',
                      const LandlordPropertiesPage(),
                    ),
                    onSettings: () => openLandlordDestination(
                      context,
                      'settings',
                      'Cài đặt',
                      const AccountSettingsPage(role: AppRole.landlord),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PropertyPortfolioIntro(
                    title: title,
                    subtitle: subtitle,
                    kicker: kicker,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(height: 18),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared screen shell for landlord tools styled like the lease screens.
class LandlordFeaturePage extends StatelessWidget {
  const LandlordFeaturePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.kicker = 'QUẢN LÝ NHÀ TRỌ',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String kicker;
  final List<Widget> children;

  void _back(BuildContext context) {
    if (RoleLayoutShell.tryNavigateTo(context, 'properties')) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) => PropertyPortfolioBackdrop(
    child: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Quay lại',
                      onPressed: () => _back(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: LandlordPalette.of(context).ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Nhà trọ',
                      onPressed: () => _back(context),
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFFFF3267),
                        backgroundColor: Colors.white.withValues(alpha: .86),
                      ),
                      icon: const Icon(Icons.favorite_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .9),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        LandlordPalette.of(context).surface
                            .withValues(alpha: .98),
                        LandlordPalette.of(context).surfaceAlt
                            .withValues(alpha: .8),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x205A99E9),
                        blurRadius: 22,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF438EFF), propertyBlue],
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 31),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kicker,
                              style: const TextStyle(
                                color: propertyBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .7,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              title,
                              style: TextStyle(
                                color: LandlordPalette.of(context).ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: LandlordPalette.of(context).muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Rounded modal shell used by create and edit forms.
class LandlordFormDialog extends StatelessWidget {
  const LandlordFormDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.footer,
    this.maxWidth = 620,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40547AB4),
              blurRadius: 34,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: propertyBlue),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF102F67),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: LandlordPalette.of(context).muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
              child: footer,
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration landlordModernInputDecoration(
  String label, {
  String? hintText,
  String? helperText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool alignLabelWithHint = false,
}) => InputDecoration(
  labelText: label,
  hintText: hintText,
  helperText: helperText,
  prefixIcon: prefixIcon,
  suffixIcon: suffixIcon,
  alignLabelWithHint: alignLabelWithHint,
  labelStyle: const TextStyle(color: Color(0xFF526991)),
  floatingLabelStyle: const TextStyle(
    color: propertyBlue,
    fontWeight: FontWeight.w700,
  ),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Color(0xFFD4E3FF)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Color(0xFFD4E3FF)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: propertyBlue, width: 1.6),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Color(0xFFD64545)),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Color(0xFFD64545), width: 1.4),
  ),
);

class LandlordGlassCard extends StatelessWidget {
  const LandlordGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.tint,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surface.withValues(alpha: dark ? 0.98 : 0.92),
            tint?.withValues(alpha: dark ? 0.16 : 0.09) ??
                palette.surface.withValues(alpha: 0.7),
          ],
        ),
        border: Border.all(
          color: dark ? palette.line : Colors.white.withValues(alpha: 0.9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14577EBA),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class LandlordGlassSection extends StatelessWidget {
  const LandlordGlassSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: LandlordPalette.of(context).ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: LandlordPalette.of(context).muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}

class LandlordGlassSearch extends StatelessWidget {
  const LandlordGlassSearch({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: TextStyle(color: LandlordPalette.of(context).ink, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded, color: propertyMuted),
      fillColor: LandlordPalette.of(context).surface.withValues(alpha: 0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0x77FFFFFF)),
      ),
    ),
  );
}

class LandlordBluePanel extends StatelessWidget {
  const LandlordBluePanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF46B4FF), Color(0xFF126CEF), Color(0xFF204BB2)],
      ),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xAAFFFFFF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30577ECA),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: child,
    ),
  );
}
