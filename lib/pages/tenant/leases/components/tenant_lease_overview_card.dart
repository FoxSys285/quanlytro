import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantLeaseOverviewCard extends StatelessWidget {
  const TenantLeaseOverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) => TenantSurface(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: tenantMuted, fontSize: 10),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                caption,
                style: const TextStyle(color: tenantMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
