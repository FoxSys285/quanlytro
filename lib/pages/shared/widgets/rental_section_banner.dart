import 'package:flutter/material.dart';

class RentalSectionBanner extends StatelessWidget {
  const RentalSectionBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
    this.footer,
    this.color = const Color(0xFF244C87),
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? footer;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, const Color(0xFF102C38), .55)!],
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _RentalPattern())),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.home_work_outlined,
                    size: 16,
                    color: Color(0xFFC1D9E8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eyebrow,
                      style: const TextStyle(
                        color: Color(0xFFC1D9E8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFD1E0E9),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (footer != null) ...[const SizedBox(height: 20), footer!],
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ],
    ),
  );
}

class _RentalPattern extends CustomPainter {
  const _RentalPattern();
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width + 5, size.height * .22);
    for (final radius in [70.0, 110.0, 150.0, 190.0]) {
      canvas.drawCircle(center, radius, stroke);
    }
    final dot = Paint()..color = Colors.white.withValues(alpha: .13);
    for (var x = size.width - 92; x < size.width - 20; x += 12) {
      for (var y = size.height - 60; y < size.height - 12; y += 12) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RentalPattern oldDelegate) => false;
}
