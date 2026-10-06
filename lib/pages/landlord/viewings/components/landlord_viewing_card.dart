import 'package:flutter/material.dart';

import '../../../shared/viewings/components/viewing_status_badge.dart';
import '../models/landlord_viewing.dart';

class LandlordViewingCard extends StatelessWidget {
  const LandlordViewingCard({
    super.key,
    required this.viewing,
    this.onConfirm,
    this.onCancel,
    this.onMessage,
  });
  final LandlordViewing viewing;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final date = viewing.startsAt;
    final time =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
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
                ViewingStatusBadge(status: viewing.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              viewing.customerName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              viewing.roomName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              viewing.address,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const Divider(height: 28),
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
            if (viewing.attendeeCount != null) ...[
              const SizedBox(height: 13),
              const Text(
                'Thông tin người đi xem',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              _RequestDetail(
                label: 'Số người cùng đến',
                value: '${viewing.attendeeCount} người',
              ),
            ],
            const Divider(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3769D6),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Xác nhận lịch'),
                ),
                OutlinedButton.icon(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Hủy lịch'),
                ),
                OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Nhắn tin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 145,
        child: Text(
          label,
          style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
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
