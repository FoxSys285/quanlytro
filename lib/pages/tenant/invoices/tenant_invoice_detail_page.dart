import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../shared/rental/tenant_session.dart';
import '../tenant_ui.dart';
import 'components/tenant_invoice_charge_rows.dart';
import 'components/tenant_payment_instructions_sheet.dart';

class TenantInvoiceDetailPage extends StatelessWidget {
  const TenantInvoiceDetailPage({
    super.key,
    required this.invoiceId,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final String invoiceId;
  final LandlordDemoStore? store;
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    return Scaffold(
      backgroundColor: tenantCanvas,
      appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final invoice = data.invoiceById(invoiceId);
          if (invoice == null ||
              !data.invoicesForTenant(tenantId).contains(invoice)) {
            return const TenantEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Không tìm thấy hóa đơn',
              subtitle: 'Hóa đơn không thuộc hợp đồng của bạn.',
            );
          }
          final payments = data
              .paymentsForTenant(tenantId)
              .where((payment) => payment.invoiceId == invoiceId)
              .toList();
          final pending = payments.any(
            (payment) => payment.status == LandlordPaymentStatus.pending,
          );
          return TenantPageFrame(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [tenantGreenDark, tenantGreen],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HÓA ĐƠN · PHÒNG ${invoice.room}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      landlordMonth(invoice.period),
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    Text(
                      formatTenantMoney(invoice.total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      invoice.id,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Đến hạn · ${landlordDate(invoice.dueDate)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      invoice.status.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const TenantSectionHeading('Chi tiết các khoản'),
              TenantSurface(
                child: Column(
                  children: [
                    TenantInvoiceChargeRows(charges: invoice.charges),
                    const TenantThinDivider(),
                    TenantDataRow(
                      label: 'TỔNG CỘNG',
                      value: formatTenantMoney(invoice.total),
                      emphasized: true,
                    ),
                    TenantDataRow(
                      label: 'Đã xác nhận',
                      value: formatTenantMoney(invoice.paidAmount),
                    ),
                    TenantDataRow(
                      label: 'Còn phải trả',
                      value: formatTenantMoney(invoice.remaining),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              for (final payment in payments) ...[
                TenantSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatTenantMoney(payment.reportedAmount)} · ${payment.method}',
                      ),
                      Text('Tham chiếu: ${payment.reference}'),
                      Text('Ngày báo trả: ${landlordDate(payment.paidAt)}'),
                      Text(switch (payment.status) {
                        LandlordPaymentStatus.pending => 'Chờ chủ trọ duyệt',
                        LandlordPaymentStatus.approved =>
                          'Đã xác nhận ${formatTenantMoney(payment.approvedAmount ?? 0)}',
                        LandlordPaymentStatus.rejected =>
                          'Từ chối: ${payment.rejectionReason}',
                      }),
                      if (payment.proofName != null)
                        Text('Minh chứng: ${payment.proofName}'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (!invoice.cancelled && invoice.remaining > 0)
                FilledButton.icon(
                  onPressed: pending
                      ? null
                      : () => showTenantPaymentInstructions(
                          context,
                          invoiceId: invoice.id,
                          store: data,
                          tenantId: tenantId,
                        ),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    pending
                        ? 'Đang chờ duyệt thanh toán'
                        : 'Thanh toán hóa đơn',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
