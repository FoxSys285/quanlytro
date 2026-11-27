import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../../../data/local_auth.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../shared/rental/tenant_session.dart';
import '../tenant_ui.dart';
import '../tenant_detail_ui.dart';
import 'components/tenant_payment_card.dart';
import 'components/tenant_invoice_charge_rows.dart';
import 'components/tenant_payment_instructions_sheet.dart';

class TenantInvoiceDetailPage extends StatelessWidget {
  const TenantInvoiceDetailPage({
    super.key,
    required this.invoiceId,
    this.store,
    String? tenantId,
  }) : _tenantId = tenantId ?? '';
  final String invoiceId;
  final LandlordDemoStore? store;
  final String _tenantId;
  String get tenantId =>
      _tenantId.isEmpty ? TenantSession.currentTenantId : _tenantId;

  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    return TenantSubpageScaffold(
      title: 'Chi tiết hóa đơn',
      child: ListenableBuilder(
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
          final pendingPayment = payments
              .where(
                (payment) => payment.status == LandlordPaymentStatus.pending,
              )
              .firstOrNull;
          final rejected = payments.any(
            (payment) => payment.status == LandlordPaymentStatus.rejected,
          );
          final lease = data.leaseById(invoice.leaseId);
          final transferAccount = data.defaultPaymentAccount;
          return TenantDetailFrame(
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
                      invoice.isDeposit
                          ? 'TIỀN ĐẶT CỌC · PHÒNG ${invoice.room}'
                          : 'HÓA ĐƠN · PHÒNG ${invoice.room}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      invoice.isDeposit
                          ? 'Tiền đặt cọc'
                          : landlordMonth(invoice.period),
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
                    TenantDetailRow(
                      label: 'TỔNG CỘNG',
                      value: formatTenantMoney(invoice.total),
                      emphasized: true,
                    ),
                    TenantDetailRow(
                      label: 'Đã xác nhận',
                      value: formatTenantMoney(invoice.paidAmount),
                    ),
                    TenantDetailRow(
                      label: 'Còn phải trả',
                      value: formatTenantMoney(invoice.remaining),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              for (final payment in payments) ...[
                TenantPaymentCard(
                  payment: payment,
                  onCancel:
                      payment.status == LandlordPaymentStatus.pending &&
                          payment.method == 'Tiền mặt'
                      ? () => _cancelPayment(context, data, payment, tenantId)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
              if (!invoice.cancelled &&
                  invoice.remaining > 0 &&
                  pendingPayment != null)
                TenantDetailNote(
                  pendingPayment.method == 'Tiền mặt'
                      ? 'Đang chờ xác nhận tiền mặt. Chưa ghi nhận khoản này vào hóa đơn.'
                      : 'Đang chờ chủ trọ đối chiếu chuyển khoản.',
                ),
              if (!invoice.cancelled &&
                  invoice.remaining > 0 &&
                  pendingPayment == null)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: !pending && lease?.cashPaymentEnabled == true
                          ? () => _openPayment(
                              context,
                              data,
                              tenantId,
                              'Tiền mặt',
                            )
                          : null,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Thanh toán bằng tiền mặt'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          !pending &&
                              lease?.bankTransferEnabled == true &&
                              transferAccount != null
                          ? () => _openPayment(
                              context,
                              data,
                              tenantId,
                              'Chuyển khoản',
                            )
                          : null,
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text('Thanh toán chuyển khoản'),
                    ),
                    if (lease?.cashPaymentEnabled != true)
                      const Text('Tiền mặt đã tắt trong hợp đồng.'),
                    if (lease?.bankTransferEnabled != true)
                      const Text('Chuyển khoản đã tắt trong hợp đồng.'),
                    if (lease?.bankTransferEnabled == true &&
                        transferAccount == null)
                      const Text(
                        'Chủ trọ chưa thiết lập tài khoản nhận chuyển khoản.',
                      ),
                    if (rejected)
                      const Text(
                        'Yêu cầu trước bị từ chối. Bạn có thể gửi yêu cầu mới.',
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _openPayment(
    BuildContext context,
    LandlordDemoStore data,
    String tenantId,
    String method,
  ) => showTenantPaymentInstructions(
    context,
    invoiceId: invoiceId,
    method: method,
    store: data,
    tenantId: tenantId,
  );

  Future<void> _cancelPayment(
    BuildContext context,
    LandlordDemoStore data,
    LandlordPayment payment,
    String tenantId,
  ) async {
    var changedLocally = false;
    try {
      data.cancelPayment(payment, tenantId: tenantId);
      changedLocally = true;
      final persistence = AppPersistence.current;
      if (persistence == null && LocalAuth.instance.isCloudMode) {
        throw StateError('Chưa kết nối phiên lưu Firebase.');
      }
      await persistence?.flush();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy yêu cầu tiền mặt.')));
    } catch (failure) {
      if (changedLocally) data.restoreCancelledPayment(payment);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppPersistence.saveFailureMessage(failure))),
      );
    }
  }
}
