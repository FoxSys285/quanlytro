import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import 'components/tenant_invoice_card.dart';
import 'tenant_invoice_detail_page.dart';

class TenantInvoicesPage extends StatelessWidget {
  const TenantInvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TenantPageFrame(
      children: [
        const TenantPageTitle(
          title: 'Lịch sử hóa đơn',
          subtitle: 'Hóa đơn được sắp xếp theo ngày, mới nhất ở trên.',
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E8),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFF2E4BF)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EAC7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFB17A23),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Còn cần thanh toán',
                      style: TextStyle(color: Color(0xFF866A3D), fontSize: 11),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '4.670.000 đ',
                      style: TextStyle(
                        color: tenantInk,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const TenantStatusPill('1 hóa đơn', color: Color(0xFFB17A23)),
            ],
          ),
        ),
        const SizedBox(height: 19),
        TenantSectionHeading(
          'Danh sách hóa đơn',
          trailing: Text(
            'Mới nhất trước',
            style: TextStyle(color: tenantMuted, fontSize: 11),
          ),
        ),
        for (final invoice in const [
          ('Tháng 10, 2026', 'HD-2026-10-0148', 4670000, '10/10/2026', false),
          ('Tháng 9, 2026', 'HD-2026-09-0148', 4590000, '10/09/2026', true),
          ('Tháng 8, 2026', 'HD-2026-08-0148', 4510000, '10/08/2026', true),
          ('Tháng 7, 2026', 'HD-2026-07-0148', 4380000, '10/07/2026', true),
        ]) ...[
          TenantInvoiceCard(
            month: invoice.$1,
            invoiceId: invoice.$2,
            amount: invoice.$3,
            date: invoice.$4,
            paid: invoice.$5,
            onTap: () => _showInvoiceDetails(
              context,
              paid: invoice.$5,
              amount: invoice.$3,
              month: invoice.$1,
              invoiceId: invoice.$2,
              date: invoice.$4,
            ),
          ),
          const SizedBox(height: 11),
        ],
      ],
    );
  }

  void _showInvoiceDetails(
    BuildContext context, {
    required bool paid,
    required int amount,
    required String month,
    required String invoiceId,
    required String date,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TenantInvoiceDetailPage(
          paid: paid,
          amount: amount,
          month: month,
          invoiceId: invoiceId,
          date: date,
        ),
      ),
    );
  }
}
