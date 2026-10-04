import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import 'properties/landlord_properties_page.dart';

Widget buildLandlordPage(BuildContext context, RoleDestination destination) {
  return switch (destination.id) {
    'properties' => const LandlordPropertiesPage(),
    _ => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(destination.icon, size: 48, color: const Color(0xFF3769D6)),
            const SizedBox(height: 16),
            Text(
              destination.label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Màn hình này sẽ được thiết kế ở bước tiếp theo.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  };
}
