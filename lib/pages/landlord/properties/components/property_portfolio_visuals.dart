import 'package:flutter/material.dart';

import '../../landlord_theme.dart';

const propertyBlue = Color(0xFF0866FF);
const propertyInk = Color(0xFF092951);
const propertyMuted = Color(0xFF7484A9);

/// The property screen owns its background so the glow continues behind cards.
class PropertyPortfolioBackdrop extends StatelessWidget {
  const PropertyPortfolioBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? LandlordPalette.dark.canvas : const Color(0xFFF3F5FF),
        gradient: dark
            ? null
            : const RadialGradient(
                center: Alignment(0.6, -1.1),
                radius: 1.15,
                colors: [
                  Color(0xFF9DD8FF),
                  Color(0xFFDDE9FF),
                  Color(0xFFF4F5FF),
                ],
                stops: [0, 0.47, 1],
              ),
      ),
      child: CustomPaint(
        painter: _BackdropPainter(dark: dark),
        child: child,
      ),
    );
  }
}

class PropertyProfileHeader extends StatelessWidget {
  const PropertyProfileHeader({
    super.key,
    required this.name,
    required this.onMenu,
    required this.onActiveProperty,
    required this.onSettings,
  });
  final String name;
  final VoidCallback onMenu;
  final VoidCallback onActiveProperty;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = name.trim().isEmpty
        ? 'CT'
        : '${words.first[0]}${words.length > 1 ? words.last[0] : ''}'
              .toUpperCase();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Tooltip(
          message: 'Mở danh mục chức năng',
          child: Semantics(
            button: true,
            label: 'Mở danh mục chức năng',
            child: GestureDetector(
              onTap: onMenu,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF70E4FF),
                          Color(0xFF1688FF),
                          Color(0xFF0643DE),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x30528AFF), blurRadius: 15),
                      ],
                    ),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF35C52C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dark ? Colors.white : propertyInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Chào mừng bạn trở lại!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark
                            ? LandlordPalette.dark.muted
                            : const Color(0xFF4F688F),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.waving_hand_rounded,
                    color: Color(0xFFFFC533),
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        _CircleAction(
          tooltip: 'Nhà trọ đang quản lý',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFF3267),
          onTap: onActiveProperty,
        ),
        const SizedBox(width: 10),
        _CircleAction(
          tooltip: 'Cài đặt',
          icon: Icons.settings_rounded,
          color: dark ? Colors.white : propertyInk,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: LandlordPalette.of(context).surface.withValues(alpha: 0.73),
      border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 23, color: color),
    ),
  );
}

class PropertyPortfolioIntro extends StatelessWidget {
  const PropertyPortfolioIntro({
    super.key,
    required this.onTap,
    this.title = 'Danh sách nhà trọ',
    this.subtitle = 'Quản lý thông tin, quy mô và tình trạng cho thuê.',
    this.kicker = 'QUẢN LÝ NHÀ TRỌ',
  });
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String kicker;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.15 : 0.85),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [LandlordPalette.dark.surface, LandlordPalette.dark.surfaceAlt]
              : [const Color(0xEFFFFFFF), const Color(0x80E1ECFF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x205A99E9),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 11, 7),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/landlord_property_house.png',
                      width: 84,
                      height: 64,
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                    ),
                    Container(
                      height: 49,
                      width: 1,
                      margin: const EdgeInsets.only(left: 10, right: 12),
                      color: const Color(0xFF93BFF7),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kicker,
                            style: const TextStyle(
                              color: propertyBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              color: dark ? Colors.white : propertyInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: dark
                                  ? LandlordPalette.dark.muted
                                  : const Color(0xFF4E668D),
                              fontSize: 9.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 16,
                  child: Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: dark ? 0.1 : 0.7),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF10459E),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PropertyPortfolioSummary extends StatelessWidget {
  const PropertyPortfolioSummary({
    super.key,
    required this.properties,
    required this.rooms,
    required this.occupied,
    required this.vacant,
  });
  final int properties;
  final int rooms;
  final int occupied;
  final int vacant;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xCCFFFFFF)),
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF159FE8),
          Color(0xFF2058B4),
          Color(0xFF1488EE),
          Color(0xFF74A7FF),
        ],
        stops: [0, 0.24, 0.71, 1],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x385B93ED),
          blurRadius: 23,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: CustomPaint(
        painter: const _SummaryPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19, 13, 12, 17),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tổng quan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Hiện tại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      value: properties,
                      label: 'Nhà trọ',
                      icon: Icons.home_rounded,
                    ),
                  ),
                  const _MetricDivider(),
                  Expanded(
                    child: _Metric(
                      value: rooms,
                      label: 'Tổng số phòng',
                      icon: Icons.people_alt_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      value: occupied,
                      label: 'Phòng đang thuê',
                      icon: Icons.meeting_room_rounded,
                    ),
                  ),
                  const _MetricDivider(),
                  Expanded(
                    child: _Metric(
                      value: vacant,
                      label: 'Phòng còn lại',
                      icon: Icons.bed_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 41,
        height: 41,
        decoration: BoxDecoration(
          color: const Color(0x4D9DBEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 27),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10.5),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 41,
    margin: const EdgeInsets.only(left: 10, right: 19),
    color: Colors.white.withValues(alpha: 0.25),
  );
}

class PropertyAddButton extends StatelessWidget {
  const PropertyAddButton({super.key, required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF58DAF9),
          Color(0xFF1183FF),
          Color(0xFF064BE4),
          Color(0xFF7DA3FF),
        ],
        stops: [0, 0.35, 0.8, 1],
      ),
      border: Border.all(color: const Color(0xFF8ED7FF), width: 0.7),
      boxShadow: const [
        BoxShadow(
          color: Color(0x405376DD),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  onTap == null ? 'Đang lưu...' : 'Thêm nhà trọ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: dark ? 0.025 : 0.23);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.55, -120, size.width * 0.8, 330),
      paint,
    );
    final house = Path()
      ..moveTo(size.width * 0.59, 138)
      ..lineTo(size.width * 0.79, 76)
      ..lineTo(size.width * 0.94, 123)
      ..lineTo(size.width * 0.94, 160)
      ..lineTo(size.width * 0.59, 160)
      ..close();
    canvas.drawPath(
      house,
      Paint()
        ..color = const Color(0xFF4EA7F0).withValues(alpha: dark ? 0.08 : 0.17),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => oldDelegate.dark != dark;
}

class _SummaryPainter extends CustomPainter {
  const _SummaryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final facet = Path()
      ..moveTo(size.width * 0.58, 0)
      ..lineTo(size.width * 0.73, 0)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height * 0.8)
      ..close();
    canvas.drawPath(
      facet,
      Paint()..color = Colors.white.withValues(alpha: 0.035),
    );
    final skyline = Paint()
      ..color = const Color(0xFF0252AE).withValues(alpha: 0.28);
    for (var i = 0; i < 5; i++) {
      final x = size.width - 17 - i * 20;
      final h = [110.0, 62.0, 48.0, 72.0, 35.0][i];
      final rect = Rect.fromLTWH(x, size.height - h - 29, 25, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        skyline,
      );
      for (var y = rect.top + 7; y < rect.bottom - 5; y += 9) {
        for (var wx = x + 4; wx < x + 22; wx += 7) {
          canvas.drawRect(
            Rect.fromLTWH(wx, y, 2, 3),
            Paint()..color = Colors.white.withValues(alpha: 0.11),
          );
        }
      }
    }
    final wave = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * 0.25,
        size.height + 8,
        size.width * 0.35,
        size.height - 30,
        size.width * 0.52,
        size.height - 5,
      )
      ..cubicTo(
        size.width * 0.73,
        size.height + 18,
        size.width * 0.81,
        size.height - 44,
        size.width,
        size.height - 45,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x284D79FF), Color(0x995BD8FF)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SummaryPainter oldDelegate) => false;
}
