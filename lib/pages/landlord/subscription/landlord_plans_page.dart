import 'package:flutter/material.dart';

import '../../../data/landlord_plans.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';

class LandlordPlansPage extends StatelessWidget {
  const LandlordPlansPage({super.key});

  @override
  Widget build(BuildContext context) => LandlordGlassPage(
    title: 'Gói quản lý nhà trọ',
    subtitle: 'Chọn quy mô phù hợp với số nhà trọ và phòng bạn đang vận hành.',
    kicker: 'GÓI DỊCH VỤ CHỦ TRỌ',
    children: [
      LandlordGlassCard(
        tint: const Color(0xFF7046D3),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7046D3).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF7046D3),
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gói mặc định: Free',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '0 đ/tháng · 1 nhà trọ · 10 phòng mỗi nhà',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      LandlordGlassSection(
        title: 'Bảng giá',
        subtitle: 'Giới hạn phòng được áp dụng riêng cho từng nhà trọ.',
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 880
              ? 2
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final plan in LandlordPlan.all)
                SizedBox(
                  width: width,
                  child: _PlanCard(plan: plan),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      LandlordGlassCard(
        tint: const Color(0xFF168FC2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF168FC2)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bảng giá và giới hạn đã được thiết lập. Thanh toán và kích hoạt gói trả phí chưa được kết nối, nên trang này hiện chỉ hiển thị thông tin gói.',
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final LandlordPlan plan;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final accent = plan.id == 'plus'
        ? const Color(0xFF7046D3)
        : const Color(0xFF087FC1);
    return LandlordGlassCard(
      tint: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.monthlyPriceLabel,
            style: TextStyle(
              color: accent,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.description,
            style: TextStyle(color: palette.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          _PlanFeature(
            icon: Icons.home_work_outlined,
            label: plan.propertyLimitLabel,
            accent: accent,
          ),
          const SizedBox(height: 10),
          _PlanFeature(
            icon: Icons.door_front_door_outlined,
            label: plan.roomLimitLabel,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: accent),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      const Icon(
        Icons.check_circle_rounded,
        size: 17,
        color: Color(0xFF0D9488),
      ),
    ],
  );
}
