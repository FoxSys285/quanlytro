import 'package:flutter/material.dart';

import '../../landlord_ui.dart';

/// Trạng thái sự cố (rút gọn theo tài liệu nghiệp vụ).
enum IncidentStatus { newly, inProgress, resolved, closed }

extension IncidentStatusX on IncidentStatus {
  String get label => switch (this) {
    IncidentStatus.newly => 'Mới',
    IncidentStatus.inProgress => 'Đang xử lý',
    IncidentStatus.resolved => 'Đã xử lý',
    IncidentStatus.closed => 'Đã đóng',
  };

  Color get color => switch (this) {
    IncidentStatus.newly => const Color(0xFFD64545),
    IncidentStatus.inProgress => const Color(0xFFE08A1E),
    IncidentStatus.resolved => const Color(0xFF16836F),
    IncidentStatus.closed => landlordMuted,
  };
}

class LandlordIncident {
  LandlordIncident({
    required this.title,
    required this.room,
    required this.reporter,
    required this.category,
    required this.description,
    required this.date,
    this.status = IncidentStatus.newly,
    this.urgent = false,
  });

  final String title;
  final String room;
  final String reporter;
  final String category;
  final String description;
  final String date;
  final bool urgent;
  IncidentStatus status;
}
