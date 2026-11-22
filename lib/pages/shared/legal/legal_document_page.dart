import 'package:flutter/material.dart';

import '../auth/auth_flow_widgets.dart';

class LegalDocumentSection {
  const LegalDocumentSection({
    required this.title,
    required this.body,
    this.points = const [],
  });

  final String title;
  final String body;
  final List<String> points;
}

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
    required this.notice,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<LegalDocumentSection> sections;
  final String notice;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF2F8F5),
      foregroundColor: authInk,
      scrolledUnderElevation: 0,
      title: const Text(
        'Thông tin pháp lý',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      centerTitle: false,
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 14),
                _notice(),
                const SizedBox(height: 16),
                for (var index = 0; index < sections.length; index++) ...[
                  _section(index + 1, sections[index]),
                  if (index != sections.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
                _versionFooter(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF087A58), Color(0xFF00A36B)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1B087A58),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: Colors.white, size: 27),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TROPREMIUM',
                style: TextStyle(
                  color: Color(0xFFD5F8E8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFE8FFF3),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _notice() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5EF),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFD2EBDD)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: authGreen, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            notice,
            style: const TextStyle(
              color: Color(0xFF315B49),
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _section(int number, LegalDocumentSection section) => Container(
    padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5ECE8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x050B6045),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F6EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: authGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: authInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          section.body,
          style: const TextStyle(
            color: Color(0xFF535D68),
            fontSize: 13,
            height: 1.75,
          ),
        ),
        if (section.points.isNotEmpty) ...[
          const SizedBox(height: 7),
          for (final point in section.points) _bullet(point),
        ],
      ],
    ),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 9),
          child: Icon(Icons.circle, size: 5, color: authGreen),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF535D68),
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _versionFooter() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        Icon(Icons.verified_user_outlined, color: authGreen, size: 22),
        SizedBox(height: 7),
        Text(
          'Phiên bản 1.0 · Cập nhật ngày 21/11/2026',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: authMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Nếu cần hỗ trợ, hãy gửi yêu cầu trong mục Trợ giúp của ứng dụng.',
          textAlign: TextAlign.center,
          style: TextStyle(color: authMuted, fontSize: 11, height: 1.5),
        ),
      ],
    ),
  );
}
