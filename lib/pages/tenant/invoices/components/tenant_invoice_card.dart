import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantInvoiceCard extends StatelessWidget {
  const TenantInvoiceCard({
    required this.month,
    required this.invoiceId,
    required this.amount,
    required this.date,
    required this.paid,
    required this.onTap,
  });
  final String month;
  final String invoiceId;
  final int amount;
  final String date;
  final bool paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = paid ? tenantGreen : const Color(0xFFD18A22);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: tenantLine),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: statusColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          month,
                          style: const TextStyle(
                            color: tenantInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          invoiceId,
                          style: const TextStyle(
                            color: tenantMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TenantStatusPill(
                    paid ? 'Đã thanh toán' : 'Chưa thanh toán',
                    color: statusColor,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: tenantLine),
              ),
              Row(
                children: [
                  Icon(
                    paid
                        ? Icons.event_available_outlined
                        : Icons.event_outlined,
                    size: 15,
                    color: tenantMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${paid ? 'Thanh toán' : 'Đến hạn'} · $date',
                      style: const TextStyle(color: tenantMuted, fontSize: 10),
                    ),
                  ),
                  Text(
                    formatTenantMoney(amount),
                    style: const TextStyle(
                      color: tenantGreenDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: tenantMuted,
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
