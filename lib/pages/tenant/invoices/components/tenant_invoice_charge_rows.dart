import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantInvoiceChargeRows extends StatelessWidget {
  const TenantInvoiceChargeRows({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final rent = amount - 870000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InvoiceChargeSection(
          title: 'TIỀN PHÒNG',
          rows: [_InvoiceChargeRow(label: 'Tiền trọ', amount: rent)],
        ),
        _InvoiceChargeSection(
          title: 'ĐIỆN & NƯỚC',
          rows: [
            _InvoiceChargeRow(
              label: 'Tiền điện',
              detail: '180 kWh × 2.600 đ',
              amount: 468000,
            ),
            _InvoiceChargeRow(
              label: 'Tiền nước',
              detail: '8 m³ × 14.000 đ',
              amount: 112000,
            ),
          ],
        ),
        _InvoiceChargeSection(
          title: 'DỊCH VỤ',
          rows: [
            _InvoiceChargeRow(
              label: 'Tiền xe',
              detail: 'Xe máy · 59-X1 234.56',
              amount: 150000,
            ),
            _InvoiceChargeRow(label: 'Internet', amount: 80000),
            _InvoiceChargeRow(label: 'Vệ sinh', amount: 60000),
          ],
        ),
        _InvoiceChargeSection(
          title: 'KHÁC',
          rows: [
            _InvoiceChargeRow(label: 'Chi phí phát sinh', amount: 0),
            _InvoiceChargeRow(label: 'Ghi chú', value: '—'),
          ],
        ),
      ],
    );
  }
}

class _InvoiceChargeSection extends StatelessWidget {
  const _InvoiceChargeSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            title,
            style: const TextStyle(
              color: tenantMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final row in rows) row,
      ],
    ),
  );
}

class _InvoiceChargeRow extends StatelessWidget {
  const _InvoiceChargeRow({
    required this.label,
    this.amount,
    this.value,
    this.detail,
  });

  final String label;
  final int? amount;
  final String? value;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 3),
                Text(
                  detail!,
                  style: const TextStyle(color: tenantMuted, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(top: detail == null ? 1 : 17),
          child: Text(
            value ?? formatTenantMoney(amount ?? 0),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF43515D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
