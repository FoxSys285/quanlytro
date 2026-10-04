import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import 'components/tenant_invoice_charge_rows.dart';
import 'components/tenant_payment_instructions_sheet.dart';

class TenantInvoiceDetailPage extends StatelessWidget {
  const TenantInvoiceDetailPage({
    super.key,
    required this.paid,
    required this.amount,
    required this.month,
    required this.invoiceId,
    required this.date,
  });

  final bool paid;
  final int amount;
  final String month;
  final String invoiceId;
  final String date;

  @override
  Widget build(BuildContext context) {
    final statusColor = paid ? tenantGreen : const Color(0xFFD18A22);
    return Scaffold(
      backgroundColor: tenantCanvas,
      appBar: AppBar(
        backgroundColor: tenantCanvas,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chi tiết hóa đơn',
          style: TextStyle(color: tenantInk, fontWeight: FontWeight.w800),
        ),
      ),
      body: TenantPageFrame(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tenantGreenDark, tenantGreen],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2110685A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Text(
                        'HÓA ĐƠN · PHÒNG A.302',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        paid ? 'Đã thanh toán' : 'Chưa thanh toán',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                Text(
                  month,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatTenantMoney(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 15,
                  runSpacing: 6,
                  children: [
                    _InvoiceMetaItem(icon: Icons.tag_rounded, label: invoiceId),
                    _InvoiceMetaItem(
                      icon: paid
                          ? Icons.event_available_outlined
                          : Icons.event_outlined,
                      label: '${paid ? 'Thanh toán' : 'Đến hạn'} · $date',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TenantSectionHeading(
            'Chi tiết các khoản',
            trailing: TenantStatusPill(
              paid ? 'Hoàn tất' : 'Chờ thanh toán',
              color: statusColor,
            ),
          ),
          TenantSurface(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 13),
            child: Column(
              children: [
                TenantInvoiceChargeRows(amount: amount),
                const TenantThinDivider(),
                TenantDataRow(
                  label: 'TỔNG CỘNG',
                  value: formatTenantMoney(amount),
                  emphasized: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          TenantSurface(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  paid ? Icons.verified_rounded : Icons.info_outline_rounded,
                  color: statusColor,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paid
                            ? 'Hóa đơn đã hoàn tất'
                            : 'Hóa đơn đang chờ thanh toán',
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paid
                            ? 'Khoản thanh toán đã được ghi nhận vào ngày $date.'
                            : 'Vui lòng thanh toán trước ngày $date.',
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 10,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!paid) ...[
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showTenantPaymentInstructions(context),
                icon: const Icon(Icons.qr_code_2_rounded, size: 19),
                label: const Text('Thanh toán hóa đơn'),
                style: FilledButton.styleFrom(
                  backgroundColor: tenantGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Thông tin minh họa trong bản xem trước',
              style: TextStyle(color: tenantMuted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMetaItem extends StatelessWidget {
  const _InvoiceMetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white70, size: 13),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
    ],
  );
}
