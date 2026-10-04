import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantHistorySummary extends StatelessWidget {
  const TenantHistorySummary({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => TenantSurface(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: tenantMuted, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
