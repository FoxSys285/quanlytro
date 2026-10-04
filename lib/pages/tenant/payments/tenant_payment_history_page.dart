import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import 'components/tenant_history_summary.dart';
import 'components/tenant_payment_details_sheet.dart';
import 'components/tenant_payment_history_card.dart';
import 'models/tenant_payment_record.dart';

class TenantPaymentHistoryPage extends StatefulWidget {
  const TenantPaymentHistoryPage({super.key});

  @override
  State<TenantPaymentHistoryPage> createState() =>
      _TenantPaymentHistoryPageState();
}

class _TenantPaymentHistoryPageState extends State<TenantPaymentHistoryPage> {
  String _filter = 'Tất cả';

  static const _payments = [
    TenantPaymentRecord(
      month: 'Tháng 9, 2026',
      date: '10/09/2026 · 09:42',
      amount: 4590000,
      method: 'Chuyển khoản ngân hàng',
      reference: 'VCB2809102408',
      status: 'Thành công',
    ),
    TenantPaymentRecord(
      month: 'Tháng 8, 2026',
      date: '09/08/2026 · 18:16',
      amount: 4510000,
      method: 'Chuyển khoản ngân hàng',
      reference: 'VCB2808091672',
      status: 'Thành công',
    ),
    TenantPaymentRecord(
      month: 'Tháng 7, 2026',
      date: '11/07/2026 · 11:03',
      amount: 4380000,
      method: 'Tiền mặt',
      reference: 'TM-2026-0711',
      status: 'Thành công',
    ),
    TenantPaymentRecord(
      month: 'Tiền cọc · HD-2026-0148',
      date: '28/05/2026 · 14:25',
      amount: 7600000,
      method: 'Chuyển khoản ngân hàng',
      reference: 'VCB2805281425',
      status: 'Đang xác nhận',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final payments = _payments
        .where((payment) => _filter == 'Tất cả' || payment.status == _filter)
        .toList();
    return TenantPageFrame(
      children: [
        const TenantPageTitle(
          title: 'Lịch sử thanh toán',
          subtitle: 'Các khoản thanh toán và trạng thái xác nhận.',
        ),
        Row(
          children: [
            Expanded(
              child: TenantHistorySummary(
                icon: Icons.check_circle_outline_rounded,
                title: 'Đã xác nhận',
                value: '3 khoản',
                color: tenantGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TenantHistorySummary(
                icon: Icons.hourglass_top_rounded,
                title: 'Đang xử lý',
                value: '1 khoản',
                color: const Color(0xFFCE8A25),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TenantSectionHeading(
          'Giao dịch gần đây',
          trailing: const Icon(
            Icons.tune_rounded,
            color: tenantMuted,
            size: 19,
          ),
        ),
        SizedBox(
          height: 37,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final filter in ['Tất cả', 'Thành công', 'Đang xác nhận'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    selectedColor: tenantGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _filter == filter ? tenantGreen : tenantLine,
                    ),
                    labelStyle: TextStyle(
                      color: _filter == filter ? Colors.white : tenantMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        for (final payment in payments) ...[
          TenantPaymentHistoryCard(
            payment: payment,
            onTap: () => _showPaymentDetails(context, payment),
          ),
          const SizedBox(height: 10),
        ],
        if (payments.isEmpty)
          const TenantEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch',
            subtitle: 'Giao dịch sẽ hiển thị tại đây.',
          ),
        const SizedBox(height: 5),
        const Text(
          'Lịch sử minh họa trong bản xem trước',
          style: TextStyle(color: Color(0xFFA2ACB4), fontSize: 10),
        ),
      ],
    );
  }

  void _showPaymentDetails(BuildContext context, TenantPaymentRecord payment) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TenantPaymentDetailsSheet(payment: payment),
    );
  }
}
