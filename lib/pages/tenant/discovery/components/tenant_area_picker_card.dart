import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantAreaPickerCard extends StatelessWidget {
  const TenantAreaPickerCard({
    super.key,
    this.city,
    this.ward,
    required this.onPressed,
  });
  final String? city;
  final String? ward;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TenantSurface(
    padding: EdgeInsets.zero,
    child: ListTile(
      leading: const Icon(Icons.location_on_outlined, color: tenantGreen),
      title: const Text(
        'Khu vực tìm phòng',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [ward, city].whereType<String>().join(', ').isEmpty
            ? 'Chọn tỉnh, thành phố và phường, xã'
            : [ward, city].whereType<String>().join(', '),
        style: const TextStyle(fontSize: 11, color: tenantMuted),
      ),
      trailing: const Icon(Icons.tune_rounded, size: 20, color: tenantGreen),
      onTap: onPressed,
    ),
  );
}
