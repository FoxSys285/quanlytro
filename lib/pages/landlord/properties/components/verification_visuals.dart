import 'package:flutter/material.dart';

import '../../landlord_glass.dart';
import '../../landlord_theme.dart';

const verificationGreen = Color(0xFF15966F);
const verificationAmber = Color(0xFFBD7818);

class VerificationPageFrame extends StatelessWidget {
  const VerificationPageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return PropertyPortfolioBackdrop(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: palette.surface.withValues(alpha: .8),
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.surface),
                        ),
                        child: IconButton(
                          tooltip: 'Quay lại',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KHÔNG GIAN CHỦ TRỌ',
                              style: TextStyle(
                                color: palette.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
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

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class VerificationIcon extends StatelessWidget {
  const VerificationIcon({
    super.key,
    required this.icon,
    this.color = propertyBlue,
    this.size = 44,
  });
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: .18), color.withValues(alpha: .06)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .12)),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}
