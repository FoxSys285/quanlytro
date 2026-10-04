import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantInvoiceChargeRows extends StatelessWidget {
  const TenantInvoiceChargeRows({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final rent = amount - 870000;
    final charges = <(String, int)>[
      ('Tiền trọ', rent),
      ('Tiền điện · 180 kWh × 2.600 đ', 468000),
      ('Tiền nước · 8 m³ × 14.000 đ', 112000),
      ('Tiền xe · Xe máy 59-X1 234.56', 150000),
      ('Dịch vụ · Internet', 80000),
      ('Dịch vụ · Vệ sinh', 60000),
      ('Chi phí phát sinh', 0),
      ('Ghi chú', 0),
    ];
    return Column(
      children: [
        for (var index = 0; index < charges.length; index++) ...[
          if (index > 0) const TenantThinDivider(),
          TenantDataRow(
            label: charges[index].$1,
            value: charges[index].$1 == 'Ghi chú'
                ? 'Không có · 0 đ'
                : formatTenantMoney(charges[index].$2),
          ),
        ],
      ],
    );
  }
}
