import 'package:flutter/material.dart';

import '../../../landlord/finance/landlord_finance_models.dart';
import '../../tenant_ui.dart';

class TenantInvoiceChargeRows extends StatelessWidget {
  const TenantInvoiceChargeRows({super.key, required this.charges});
  final List<LandlordInvoiceCharge> charges;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final charge in charges)
        TenantDataRow(
          label: charge.name,
          value: formatTenantMoney(charge.amount),
        ),
    ],
  );
}
