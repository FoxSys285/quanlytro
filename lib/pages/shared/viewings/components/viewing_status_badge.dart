import 'package:flutter/material.dart';

import '../models/room_viewing.dart';

class ViewingStatusBadge extends StatelessWidget {
  const ViewingStatusBadge({super.key, required this.status});
  final ViewingStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ViewingStatus.pending => const Color(0xFF946000),
      ViewingStatus.confirmed => const Color(0xFF16836F),
      ViewingStatus.cancelled => const Color(0xFFBE3434),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String viewingDateLabel(DateTime date) {
  const weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ nhật',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String viewingTimeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';
