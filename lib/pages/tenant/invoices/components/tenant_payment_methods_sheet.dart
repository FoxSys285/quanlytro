import 'package:flutter/material.dart';

import '../../../landlord/landlord_demo_store.dart';
import '../../../shared/payments/vietqr_service.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';
import 'tenant_bank_qr.dart';

void showTenantPaymentMethods(
  BuildContext context, {
  required LandlordDemoStore store,
  required String tenantId,
  String? invoiceId,
  VietQrService? qrService,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final invoices = store.invoicesForTenant(tenantId);
      final matching = invoices.where((invoice) => invoice.id == invoiceId);
      final invoice = matching.isEmpty ? null : matching.first;
      final lease = invoice == null
          ? store.currentLeaseForTenant(tenantId)
          : store.leaseById(invoice.leaseId);
      final account = store.defaultPaymentAccount;
      return TenantDetailTheme(
        child: TenantBottomSheetSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TenantSheetHandle(),
              const Text(
                'Phương thức thanh toán',
                style: TextStyle(
                  color: tenantInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thông tin nhận tiền do chủ trọ thiết lập.',
                style: TextStyle(color: tenantMuted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (lease == null || (invoiceId != null && invoice == null))
                const TenantDetailNote(
                  'Chưa có thông tin thanh toán cho hợp đồng của bạn.',
                )
              else ...[
                if (lease.cashPaymentEnabled)
                  TenantSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              color: tenantGreenDark,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Tiền mặt',
                                style: TextStyle(
                                  color: tenantInk,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lease.cashPaymentLocation.isEmpty
                              ? 'Liên hệ chủ trọ để hẹn địa điểm thanh toán.'
                              : lease.cashPaymentLocation,
                          style: const TextStyle(
                            color: tenantMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (lease.cashPaymentEnabled) const SizedBox(height: 14),
                if (lease.bankTransferEnabled)
                  TenantSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              color: tenantGreenDark,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Chuyển khoản ngân hàng',
                                style: TextStyle(
                                  color: tenantInk,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (account == null)
                          const TenantDetailNote(
                            'Chủ trọ chưa thiết lập tài khoản nhận tiền đang hoạt động.',
                          )
                        else
                          TenantBankQr(
                            bankName: account.bankName,
                            accountNumber: account.accountNumber,
                            accountName: account.accountName,
                            reference:
                                invoice?.id ??
                                'Thanh toan ${lease.id.replaceAll('-', ' ')}',
                            amount:
                                invoice != null &&
                                    !invoice.cancelled &&
                                    invoice.remaining > 0
                                ? invoice.remaining
                                : null,
                            service: qrService,
                          ),
                      ],
                    ),
                  ),
                if (!lease.cashPaymentEnabled && !lease.bankTransferEnabled)
                  const TenantDetailNote(
                    'Chủ trọ chưa thiết lập phương thức thanh toán.',
                  ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  ),
);
