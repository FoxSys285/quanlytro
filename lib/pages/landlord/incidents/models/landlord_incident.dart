import 'package:flutter/material.dart';

import '../../landlord_ui.dart';

/// Trạng thái sự cố (rút gọn theo tài liệu nghiệp vụ).
enum IncidentStatus { newly, inProgress, resolved, closed }

extension IncidentStatusX on IncidentStatus {
  String get label {
    if (this == IncidentStatus.newly) {
      return 'Mới';
    } else if (this == IncidentStatus.inProgress) {
      return 'Đang xử lý';
    } else if (this == IncidentStatus.resolved) {
      return 'Đã xử lý';
    } else {
      return 'Đã đóng';
    }
  }

  Color get color {
    if (this == IncidentStatus.newly) {
      return const Color(0xFFD64545);
    } else if (this == IncidentStatus.inProgress) {
      return const Color(0xFFE08A1E);
    } else if (this == IncidentStatus.resolved) {
      return const Color(0xFF16836F);
    } else {
      return landlordMuted;
    }
  }
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
