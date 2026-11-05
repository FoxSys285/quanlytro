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
