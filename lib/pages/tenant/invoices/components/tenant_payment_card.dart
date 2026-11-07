import 'package:flutter/material.dart';

import '../../../landlord/finance/landlord_finance_models.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';

class TenantPaymentCard extends StatelessWidget {
  const TenantPaymentCard({super.key, required this.payment});

  final LandlordPayment payment;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (payment.status) {
      LandlordPaymentStatus.pending => (
        'Chờ chủ trọ duyệt',
        const Color(0xFFB57920),
      ),
      LandlordPaymentStatus.approved => ('Đã xác nhận', tenantGreen),
      LandlordPaymentStatus.rejected => (
        'Chưa được duyệt',
        const Color(0xFFD64545),
      ),
    };
    return TenantSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatTenantMoney(payment.reportedAmount),
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TenantStatusPill(label, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            payment.invoiceId,
            style: const TextStyle(color: tenantMuted, fontSize: 11),
          ),
          const TenantThinDivider(),
          TenantDetailRow(label: 'Phương thức', value: payment.method),
          TenantDetailRow(
            label: 'Ngày báo trả',
            value: landlordDate(payment.paidAt),
          ),
          TenantDetailRow(label: 'Tham chiếu', value: payment.reference),
          if (payment.status == LandlordPaymentStatus.approved)
            TenantDetailRow(
              label: 'Đã xác nhận',
              value: formatTenantMoney(payment.approvedAmount ?? 0),
              emphasized: true,
            ),
          if (payment.status == LandlordPaymentStatus.rejected)
            TenantDetailNote(
              'Chưa được duyệt. Lý do: ${payment.rejectionReason ?? 'Chủ trọ chưa ghi lý do.'} Hãy kiểm tra thông tin và nộp lại.',
            ),
          if (payment.proofName != null)
            TenantDetailRow(label: 'Minh chứng', value: payment.proofName!),
        ],
      ),
    );
  }
}
