import 'package:flutter/material.dart';

import '../models/tenant_payment_record.dart';
import '../../tenant_ui.dart';

class TenantPaymentDetailsSheet extends StatelessWidget {
  const TenantPaymentDetailsSheet({required this.payment});
  final TenantPaymentRecord payment;

  @override
  Widget build(BuildContext context) => TenantBottomSheetSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TenantSheetHandle(),
        Text(
          payment.month,
          style: const TextStyle(
            color: tenantInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          payment.date,
          style: const TextStyle(color: tenantMuted, fontSize: 11),
        ),
        const SizedBox(height: 15),
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: tenantGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            payment.status == 'Thành công'
                ? Icons.check_rounded
                : Icons.hourglass_top_rounded,
            color: tenantGreen,
            size: 29,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          formatTenantMoney(payment.amount),
          style: const TextStyle(
            color: tenantInk,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TenantStatusPill(
          payment.status,
          color: payment.status == 'Thành công'
              ? tenantGreen
              : const Color(0xFFCE8A25),
        ),
        const SizedBox(height: 16),
        TenantSurface(
          child: Column(
            children: [
              TenantDataRow(label: 'Phương thức', value: payment.method),
              const TenantThinDivider(),
              TenantDataRow(label: 'Mã giao dịch', value: payment.reference),
              const TenantThinDivider(),
              const TenantDataRow(label: 'Nhà trọ', value: 'Mây House'),
              const TenantThinDivider(),
              const TenantDataRow(label: 'Phòng', value: 'A.302'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Giao dịch minh họa trong bản xem trước.',
          style: TextStyle(color: tenantMuted, fontSize: 10),
        ),
      ],
    ),
  );
}
