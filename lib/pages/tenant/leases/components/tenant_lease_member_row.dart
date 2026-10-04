import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantLeaseMemberRow extends StatelessWidget {
  const TenantLeaseMemberRow({
    required this.initials,
    required this.name,
    required this.detail,
    required this.color,
  });

  final String initials;
  final String name;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(color: tenantMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: tenantMuted, size: 19),
      ],
    ),
  );
}
