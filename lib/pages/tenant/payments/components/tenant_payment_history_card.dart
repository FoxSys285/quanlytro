import 'package:flutter/material.dart';

import '../models/tenant_payment_record.dart';
import '../../tenant_ui.dart';

class TenantPaymentHistoryCard extends StatelessWidget {
  const TenantPaymentHistoryCard({required this.payment, required this.onTap});
  final TenantPaymentRecord payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final success = payment.status == 'Thành công';
    final color = success ? tenantGreen : const Color(0xFFCE8A25);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: tenantLine),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  success ? Icons.check_rounded : Icons.hourglass_top_rounded,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.month,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.date,
                      style: const TextStyle(color: tenantMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 7),
                    TenantStatusPill(payment.status, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTenantMoney(payment.amount),
                    style: const TextStyle(
                      color: tenantInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Chi tiết  ›',
                    style: TextStyle(
                      color: tenantGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
