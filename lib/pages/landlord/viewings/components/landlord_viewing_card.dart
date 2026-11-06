import 'package:flutter/material.dart';

import '../../landlord_theme.dart';
import '../../landlord_glass.dart';

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: LandlordGlassCard(
        padding: const EdgeInsets.all(17),
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
                    color: const Color(0xFFE4EFFF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF0866FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ViewingStatusBadge(status: viewing.status),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              viewing.customerName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              viewing.roomName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              viewing.address,
              style: TextStyle(
                color: LandlordPalette.of(context).muted,
                fontSize: 12,
              ),
            ),
            Divider(height: 24, color: LandlordPalette.of(context).line),
            _Information(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: viewing.phone,
            ),
            const SizedBox(height: 13),
            Text(
              'Nhu cầu cá nhân',
              style: TextStyle(
                color: LandlordPalette.of(context).ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              viewing.personalNeeds,
              style: TextStyle(
                color: LandlordPalette.of(context).ink,
                height: 1.5,
              ),
            ),
            if (viewing.attendeeCount != null) ...[
              const SizedBox(height: 13),
              const Text(
                'Thông tin người đi xem',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              _RequestDetail(
                label: 'Số người cùng đến',
                value: '${viewing.attendeeCount} người',
              ),
            ],
            Divider(height: 24, color: LandlordPalette.of(context).line),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0866FF),
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
      Icon(icon, size: 20, color: const Color(0xFF1679BC)),
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
