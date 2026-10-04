import 'package:flutter/material.dart';

import '../models/landlord_viewing.dart';

class LandlordViewingCard extends StatelessWidget {
  const LandlordViewingCard({super.key, required this.viewing});
  final LandlordViewing viewing;

  @override
  Widget build(BuildContext context) {
    final date = viewing.startsAt;
    final time =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
    final confirmed = viewing.status == ViewingStatus.confirmed;
    final statusColor = confirmed
        ? const Color(0xFF16836F)
        : const Color(0xFF946000);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7ECEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF3769D6),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    viewing.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              viewing.roomName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              viewing.address,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const Divider(height: 28),
            _Information(
              icon: Icons.person_outline,
              label: 'Người đặt',
              value: viewing.customerName,
            ),
            const SizedBox(height: 10),
            _Information(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: viewing.phone,
            ),
            const SizedBox(height: 14),
            const Text(
              'Nhu cầu cá nhân',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(viewing.personalNeeds, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _Information extends StatelessWidget {
  const _Information({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: const Color(0xFF3769D6)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}
