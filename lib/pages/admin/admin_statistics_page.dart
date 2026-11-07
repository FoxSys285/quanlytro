import 'package:flutter/material.dart';

import '../../data/landlord_plans.dart';
import 'admin_ui.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) => AdminFrame(
    title: 'Thống kê doanh thu gói',
    subtitle: 'Theo dõi doanh thu đăng ký, xu hướng theo tháng và gói được chọn nhiều nhất.',
    children: [
      const AdminSyncBar(),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B192C), Color(0xFF164E8A), Color(0xFF5B3CB5)],
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.insights_rounded, color: Color(0xFFD6CBFF), size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doanh thu đăng ký gói',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Số liệu sẽ tự cập nhật khi ứng dụng ghi nhận thanh toán gói.',
                    style: TextStyle(
                      color: Color(0xFFD7E7FF),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      AdminSection(
        'Danh mục gói đang áp dụng',
        caption: '${LandlordPlan.all.length} gói dành cho chủ trọ',
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: LandlordPlan.all.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 154,
            ),
            itemBuilder: (context, index) =>
                _PlanSummaryCard(plan: LandlordPlan.all[index]),
          );
        },
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 3 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryCard(
                width: width,
                title: 'Tổng doanh thu',
                value: 'Chưa có dữ liệu',
                icon: Icons.payments_rounded,
                color: adminBlue,
              ),
              _SummaryCard(
                width: width,
                title: 'Giao dịch gói',
                value: 'Chưa có dữ liệu',
                icon: Icons.receipt_long_rounded,
                color: adminPurple,
              ),
              _SummaryCard(
                width: width,
                title: 'Gói mua nhiều nhất',
                value: 'Chưa xác định',
                icon: Icons.workspace_premium_rounded,
                color: adminTeal,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      AdminSection(
        'Doanh thu theo tháng',
        caption: 'Tổng tiền chủ trọ thanh toán khi đăng ký hoặc gia hạn gói',
      ),
      AdminPanel(
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Biểu đồ doanh thu',
                    style: TextStyle(
                      color: adminInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Năm trước',
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                    color: adminInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Năm sau',
                  onPressed: _year >= DateTime.now().year
                      ? null
                      : () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _EmptyRevenueChart(year: _year),
          ],
        ),
      ),
      const SizedBox(height: 18),
      AdminSection(
        'Phân bố gói đã mua',
        caption: 'Xếp hạng theo số giao dịch thành công',
      ),
      const AdminPanel(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart_rounded, color: adminPurple, size: 34),
                SizedBox(height: 10),
                Text(
                  'Chưa có giao dịch đăng ký gói',
                  style: TextStyle(
                    color: adminInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Khi có dữ liệu thanh toán, các gói sẽ được xếp hạng tại đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: adminMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Hiện hệ thống chưa có sổ giao dịch mua gói. Trang này không dùng tiền thuê phòng hoặc hoa hồng để thay thế doanh thu gói.',
        style: TextStyle(color: adminMuted, fontSize: 12, height: 1.45),
      ),
    ],
  );
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.plan});

  final LandlordPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = plan.id == 'plus' ? adminPurple : adminBlue;
    return AdminPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: adminInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            plan.monthlyPriceLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.propertyLimitLabel} · ${plan.roomLimitLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: adminMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AdminPanel(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: adminMuted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: adminInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyRevenueChart extends StatelessWidget {
  const _EmptyRevenueChart({required this.year});
  final int year;

  @override
  Widget build(BuildContext context) {
    const months = [
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12',
    ];
    return SizedBox(
      height: 205,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < months.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: index == 0 ? 3 : 2,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? adminPurple.withValues(alpha: .35)
                                  : adminLine,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            months[index],
                            style: const TextStyle(
                              color: adminMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có giao dịch trong năm $year',
            style: const TextStyle(color: adminMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
