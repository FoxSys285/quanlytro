import 'package:flutter/material.dart';

import '../conversations/tenant_conversation_page.dart';
import '../tenant_ui.dart';
import 'components/tenant_lease_member_row.dart';
import 'components/tenant_lease_metric.dart';
import 'components/tenant_lease_overview_card.dart';

class TenantHomePage extends StatelessWidget {
  const TenantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TenantPageFrame(
      children: [
        const TenantPageTitle(
          title: 'Chỗ ở của tôi',
          subtitle: 'Thông tin phòng và hợp đồng đang có hiệu lực.',
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tenantGreenDark, tenantGreen],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2516836F),
                blurRadius: 20,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'CHỖ Ở HIỆN TẠI',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.17),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đang thuê',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mây House',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Phòng A.302 · Tầng 3',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '25 Nguyễn Gia Trí, P. 25, Bình Thạnh',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 13),
              const Row(
                children: [
                  Expanded(
                    child: TenantLeaseMetric(
                      label: 'Ngày bắt đầu',
                      value: '01/06/2026',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TenantLeaseMetric(
                      label: 'Hết hạn hợp đồng',
                      value: '31/05/2027',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const TenantSectionHeading('Tổng quan tháng này'),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              const TenantLeaseOverviewCard(
                icon: Icons.payments_outlined,
                title: 'Tiền thuê',
                value: '3.800.000 đ',
                caption: 'Mỗi tháng',
                color: tenantGreen,
              ),
              const TenantLeaseOverviewCard(
                icon: Icons.event_available_outlined,
                title: 'Ngày thanh toán',
                value: 'Ngày 10',
                caption: 'Hạn kỳ tiếp theo',
                color: Color(0xFF4784C7),
              ),
              const TenantLeaseOverviewCard(
                icon: Icons.people_outline_rounded,
                title: 'Thành viên',
                value: '2 người',
                caption: 'Trong phòng',
                color: Color(0xFFB17939),
              ),
            ];
            if (constraints.maxWidth > 560) {
              return Row(
                children: [
                  for (var index = 0; index < cards.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == cards.length - 1 ? 0 : 11,
                        ),
                        child: cards[index],
                      ),
                    ),
                ],
              );
            }
            return Column(
              children: [
                for (final card in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 11),
        TenantSectionHeading(
          'Hợp đồng thuê',
          trailing: const TenantStatusPill('Còn hiệu lực', color: tenantGreen),
        ),
        TenantSurface(
          child: Column(
            children: [
              const TenantDataRow(label: 'Mã hợp đồng', value: 'HD-2026-0148'),
              const TenantThinDivider(),
              const TenantDataRow(label: 'Tiền đặt cọc', value: '7.600.000 đ'),
              const TenantThinDivider(),
              const TenantDataRow(
                label: 'Chu kỳ thanh toán',
                value: 'Hàng tháng · ngày 10',
              ),
              const TenantThinDivider(),
              const TenantDataRow(label: 'Giá điện', value: '2.600 đ/kWh'),
              const TenantThinDivider(),
              const TenantDataRow(label: 'Giá nước', value: '14.000 đ/m³'),
              const TenantThinDivider(),
              const TenantDataRow(
                label: 'Dịch vụ · Internet',
                value: '80.000 đ/tháng',
              ),
              const TenantThinDivider(),
              const TenantDataRow(
                label: 'Dịch vụ · Vệ sinh',
                value: '60.000 đ/tháng',
              ),
              const TenantThinDivider(),
              const TenantDataRow(
                label: 'Xe máy · BS 59-X1 234.56',
                value: '150.000 đ/tháng',
              ),
              const TenantThinDivider(),
              TenantDataRow(
                label: 'Bản hợp đồng',
                value: 'Xem chi tiết',
                valueColor: tenantGreenDark,
                onTap: () => showTenantPreviewNotice(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 21),
        const TenantSectionHeading(
          'Người ở cùng',
          trailing: Text(
            '2 / 4 người',
            style: TextStyle(color: tenantMuted, fontSize: 11),
          ),
        ),
        TenantSurface(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: const Column(
            children: [
              TenantLeaseMemberRow(
                initials: 'MA',
                name: 'Nguyễn Minh Anh',
                detail: 'Bạn · Người đại diện',
                color: tenantGreen,
              ),
              Divider(height: 1, color: tenantLine),
              TenantLeaseMemberRow(
                initials: 'TL',
                name: 'Trần Thảo Linh',
                detail: 'Thành viên',
                color: Color(0xFF7181C1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: TenantOutlineAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Nhắn tin',
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const TenantLandlordConversationPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TenantOutlineAction(
                icon: Icons.build_outlined,
                label: 'Báo sự cố',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
