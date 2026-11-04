import 'package:flutter/material.dart';

import '../widgets/app_brand.dart';

const _green = Color(0xFF009B65);
const _ink = Color(0xFF25283F);

/// Decorative artwork stays separate from the authentication form.
class LoginHero extends StatelessWidget {
  const LoginHero({super.key, this.wide = false});

  final bool wide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final top = wide ? 0.0 : MediaQuery.paddingOf(context).top;
      final height = wide ? 540.0 : (width * 0.66).clamp(250.0, 330.0) + top;
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: _HeroClipper(),
                child: Image.asset(
                  'assets/images/login_hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0, 0.4, 0.7, 1],
                    colors: [
                      Color(0xFFF0F9F4),
                      Color(0xF2F0F9F4),
                      Color(0x38F0F9F4),
                      Color(0x00F0F9F4),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 38,
              child: IgnorePointer(
                child: CustomPaint(painter: _HeroWavesPainter()),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 8 : 22,
                top + (wide ? 28 : 45),
                12,
                14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 56),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            appName,
                            style: TextStyle(
                              color: _green,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: wide ? 62 : 27),
                  Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'Nhà trọ của bạn,\nquản lý '),
                        TextSpan(
                          text: 'thật dễ.',
                          style: TextStyle(color: _green),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: _ink,
                      fontSize: wide ? 35 : (width * 0.063).clamp(23.0, 33.0),
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: wide ? 154 : width * 0.268,
                      top: 3,
                    ),
                    child: CustomPaint(
                      size: Size(wide ? 105 : 67, 8),
                      painter: _UnderlinePainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng nhập để quản lý nhà trọ\nvà theo dõi việc thuê phòng.',
                    style: TextStyle(
                      color: const Color(0xFF454E67),
                      fontSize: wide ? 16 : 12,
                      height: 1.5,
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

class _HeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.55, 0)
    ..quadraticBezierTo(
      size.width * 0.16,
      size.height * 0.36,
      size.width * 0.38,
      size.height,
    )
    ..lineTo(size.width, size.height)
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(_HeroClipper oldClipper) => false;
}

class _UnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, -2, size.width, size.height * 0.55),
    Paint()
      ..color = const Color(0xFF40B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round,
  );

  @override
  bool shouldRepaint(_UnderlinePainter oldDelegate) => false;
}

class _HeroWavesPainter extends CustomPainter {
  const _HeroWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.23, h)
        ..quadraticBezierTo(w * 0.42, -h * 0.5, w * 0.72, h)
        ..close(),
      Paint()..color = const Color(0xFF7CDAB0).withValues(alpha: 0.42),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.8)
        ..cubicTo(w * 0.34, h * 1.2, w * 0.36, -h * 0.2, w * 0.68, h * 0.48)
        ..cubicTo(w * 0.84, h, w * 0.87, -h * 0.3, w, 0)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFFEAF8F0),
    );
  }

  @override
  bool shouldRepaint(_HeroWavesPainter oldDelegate) => false;
}

class GoogleMarkPainter extends CustomPainter {
  const GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    for (final arc in [
      (const Color(0xFF4285F4), -0.12, 0.87),
      (const Color(0xFF34A853), 0.75, 1.52),
      (const Color(0xFFFBBC05), 2.27, 0.91),
      (const Color(0xFFEA4335), 3.18, 2.25),
    ]) {
      canvas.drawArc(rect, arc.$2, arc.$3, false, paint..color = arc.$1);
    }
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.5),
      Offset(size.width - 1.5, size.height * 0.5),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = 3.8,
    );
  }

  @override
  bool shouldRepaint(GoogleMarkPainter oldDelegate) => false;
}

class LoginLandscapePainter extends CustomPainter {
  const LoginLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final buildings = Paint()..color = const Color(0xFFBCEED3);
    for (var i = 0; i < 12; i++) {
      final x = w * (0.53 + i * 0.045);
      final height = h * (0.24 + ((i * 7) % 9) * 0.045);
      final y = h * 0.78 - height;
      canvas.drawRect(Rect.fromLTWH(x, y, w * 0.034, height), buildings);
      canvas.drawRect(
        Rect.fromLTWH(x + w * 0.006, y - 3, w * 0.022, 3),
        buildings,
      );
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 2; col++) {
          canvas.drawRect(
            Rect.fromLTWH(x + 3 + col * w * 0.013, y + 6 + row * 9, 2, 3),
            Paint()..color = const Color(0xFFE2F8EC),
          );
        }
      }
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.1)
        ..cubicTo(w * 0.16, h * 0.18, w * 0.12, h * 0.48, w * 0.31, h * 0.45)
        ..cubicTo(w * 0.48, h * 0.44, w * 0.52, h * 0.83, w * 0.79, h * 0.72)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFFBAF0D0),
    );
    final trees = Paint()..color = const Color(0xFF7DD5A7);
    for (final tree in [
      (0.055, 0.72),
      (0.11, 0.61),
      (0.16, 0.70),
      (0.91, 0.54),
    ]) {
      final x = tree.$1 * w;
      final y = tree.$2 * h;
      canvas.drawRect(Rect.fromLTWH(x - 1.5, y, 3, 17), trees);
      canvas.drawCircle(Offset(x, y - 5), 9, trees);
      canvas.drawCircle(Offset(x - 5, y + 1), 7, trees);
      canvas.drawCircle(Offset(x + 5, y + 1), 7, trees);
    }
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.85)
        ..cubicTo(w * 0.23, h * 0.59, w * 0.49, h * 0.88, w * 0.72, h * 0.7)
        ..quadraticBezierTo(w * 0.9, h * 0.42, w, h * 0.52)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF9AE4BD), Color(0xFF58C68F)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.9)
        ..quadraticBezierTo(w * 0.53, h * 0.59, w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFFB4EFD2).withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(LoginLandscapePainter oldDelegate) => false;
}
