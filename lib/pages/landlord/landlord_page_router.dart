import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import 'announcements/landlord_announcements_page.dart';
import 'conversations/landlord_conversations_page.dart';
import 'dashboard/landlord_dashboard_page.dart';
import 'incidents/landlord_incidents_page.dart';
import 'landlord_ui.dart';
import 'members/landlord_members_page.dart';
import 'meter_readings/landlord_meter_readings_page.dart';
import 'properties/landlord_properties_page.dart';
import 'room_types/landlord_room_types_page.dart';
import 'services/landlord_services_page.dart';
import 'viewings/landlord_viewings_page.dart';

Widget buildLandlordPage(BuildContext context, RoleDestination destination) {
  return switch (destination.id) {
    // Phần của Minh
    'dashboard' => const LandlordDashboardPage(),
    'services' => const LandlordServicesPage(),
    'meter_readings' => const LandlordMeterReadingsPage(),
    'members' => const LandlordMembersPage(),
    'conversations' => const LandlordConversationsPage(),
    'incidents' => const LandlordIncidentsPage(),

    // Phần của Nguyên
    'properties' => const LandlordPropertiesPage(),
    'room_types' => const LandlordRoomTypesPage(),
    'viewings' => const LandlordViewingsPage(),
    'announcements' || 'notifications' => const LandlordAnnouncementsPage(),

    _ => _LandlordSecondaryPage(destination: destination),
  };
}

class _LandlordSecondaryPage extends StatelessWidget {
  const _LandlordSecondaryPage({required this.destination});
  final RoleDestination destination;

  @override
  Widget build(BuildContext context) => LandlordPageFrame(
    children: [
      LandlordPageTitle(
        title: destination.label,
        subtitle: 'Không gian chủ trọ tại An Cư.',
      ),
      const LandlordEmptyState(
        message: 'Màn hình này sẽ được thiết kế ở bước tiếp theo.',
      ),
    ],
  );
}

