import 'package:flutter/material.dart';

import 'tenant_detail_ui.dart';
import 'tenant_ui.dart';

enum TenantFeatureArtwork {
  favorites(
    'tenant_favorites_hero.png',
    'Chỗ ở yêu thích',
    Icons.favorite_rounded,
  ),
  settings(
    'tenant_settings_hero.png',
    'Tài khoản của bạn',
    Icons.settings_rounded,
  ),
  landlordSettings(
    'landlord_settings_hero.png',
    'Quản lý nhà trọ',
    Icons.settings_rounded,
    landlordStyle: true,
  ),
  incidents(
    'tenant_incidents_hero.png',
    'Hỗ trợ chỗ ở',
    Icons.handyman_rounded,
  ),
  viewings(
    'tenant_viewings_hero.png',
    'Lịch hẹn của bạn',
    Icons.calendar_month_rounded,
  ),
  members('tenant_members_hero.png', 'Người ở cùng', Icons.groups_rounded),
  help('tenant_help_hero.png', 'Trung tâm hỗ trợ', Icons.support_agent_rounded),
  landlordHelp(
    'landlord_help_hero.png',
    'Hỗ trợ Chủ trọ',
    Icons.support_agent_rounded,
    landlordStyle: true,
  );

  const TenantFeatureArtwork(
    this.fileName,
    this.label,
    this.icon, {
    this.landlordStyle = false,
  });
  final String fileName;
  final String label;
  final IconData icon;
  final bool landlordStyle;
  String get asset => 'assets/images/$fileName';
}

/// Common illustrated header and white content sheet for tenant utility pages.
class TenantFeatureFrame extends StatelessWidget {
  const TenantFeatureFrame({
    super.key,
    required this.artwork,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final TenantFeatureArtwork artwork;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => TenantDetailTheme(
    landlordStyle: artwork.landlordStyle,
    child: Builder(
      builder: (context) {
        final colors = TenantUiPalette.of(context);
        return TenantPageFrame(
          padding: EdgeInsets.zero,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      artwork.asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.header,
                            colors.headerMid,
                            colors.headerFade,
                          ],
                          stops: [0, 0.44, 1],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 196),
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth < 600 ? 20 : 32,
                      23,
                      16,
                      25,
                    ),
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints.maxWidth < 600
                          ? constraints.maxWidth * 0.59
                          : 450,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TenantStatusPill(
                            artwork.label,
                            color: colors.dark,
                            icon: artwork.icon,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              color: artwork.landlordStyle
                                  ? Color(0xFF17344F)
                                  : Color(0xFF073D26),
                              fontSize: 25,
                              height: 1.12,
                              letterSpacing: -0.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: artwork.landlordStyle
                                  ? Color(0xFF53697D)
                                  : Color(0xFF465B50),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        );
      },
    ),
  );
}

class TenantFormHeading extends StatelessWidget {
  const TenantFormHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.lighter, colors.formEnd]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(icon, color: colors.dark, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.formTitle,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: tenantMuted,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TenantFeatureBanner extends StatelessWidget {
  const TenantFeatureBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final colors = TenantUiPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.lighter, colors.bannerEnd]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.dark, size: 31),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.bannerTitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.softText,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
