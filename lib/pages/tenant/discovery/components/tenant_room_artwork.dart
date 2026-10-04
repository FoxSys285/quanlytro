import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantRoomArtwork extends StatelessWidget {
  const TenantRoomArtwork({
    required this.variant,
    this.height = 170,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  final int variant;
  final double height;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFFD8ECE5), Color(0xFFAED1C4)],
      [Color(0xFFF1E5D4), Color(0xFFD8BFA5)],
      [Color(0xFFDCE8F2), Color(0xFFADC4D5)],
    ];
    final palette = palettes[variant % palettes.length];
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette,
              ),
            ),
          ),
          Positioned(
            top: -35,
            right: -10,
            child: _softCircle(105, Colors.white.withValues(alpha: 0.32)),
          ),
          Positioned(
            bottom: -62,
            left: 30,
            child: _softCircle(150, Colors.white.withValues(alpha: 0.22)),
          ),
          Positioned(
            right: 20,
            bottom: 1,
            child: Icon(
              Icons.apartment_rounded,
              size: height * 0.86,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 13, color: tenantGreen),
                  SizedBox(width: 4),
                  Text(
                    'Đã xác thực',
                    style: TextStyle(
                      color: tenantGreenDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 13,
            top: 13,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu tin',
                onPressed:
                    onFavoriteTap ?? () => showTenantPreviewNotice(context),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? const Color(0xFFD45B67) : tenantGreen,
                  size: 19,
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 37,
                  height: 37,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _softCircle(double size, Color color) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
);
