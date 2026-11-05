import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../layouts/role_layout.dart';
import '../shared/profile/account_store.dart';
import 'discovery/tenant_favorites_page.dart';
import 'tenant_detail_ui.dart';
import 'tenant_settings_page.dart';
import 'tenant_ui.dart';

/// Full-width artwork and account header, matching the discovery page.
class TenantInboxPageFrame extends StatelessWidget {
  const TenantInboxPageFrame({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showHeader = false,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showHeader;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    child: TenantDetailTheme(
      child: Material(
        color: tenantCanvas,
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 600
                  ? 18.0
                  : 32.0;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(context),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _hero(BuildContext context) {
    final topInset = showHeader ? MediaQuery.paddingOf(context).top : 0.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = (constraints.maxWidth * 0.58).clamp(180.0, 560.0);
        return SizedBox(
          height: (showHeader ? 244 : 184) + topInset,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFFEAF2E9)),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: math.min(constraints.maxWidth, 760),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  excludeFromSemantics: true,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0, 0.46, 1],
                    colors: [
                      Color(0xF2F3FAF4),
                      Color(0xD9F3FAF4),
                      Color(0x00F3FAF4),
                    ],
                  ),
                ),
              ),
              if (showHeader)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ListenableBuilder(
                    listenable: AccountStore.instance,
                    builder: (context, _) => TenantHeader(
                      profileName: AccountStore.instance
                          .profile(AppRole.tenant)
                          .name,
                      onAvatarTap: () =>
                          Scaffold.maybeOf(context)?.openDrawer(),
                      onFavoritesTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const TenantFavoritesPage(),
                        ),
                      ),
                      onSettingsTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const TenantSettingsPage(),
                        ),
                      ),
                      overlay: true,
                    ),
                  ),
                ),
              Positioned(
                top: topInset + (showHeader ? 91 : 30),
                left: constraints.maxWidth < 600 ? 20 : 32,
                width: textWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF073B25),
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.65,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF294B36),
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: 34,
                      height: 3,
                      decoration: BoxDecoration(
                        color: tenantGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
