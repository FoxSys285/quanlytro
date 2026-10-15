import 'package:flutter/material.dart';

import '../../layouts/role_layout.dart';
import 'announcements/landlord_announcements_page.dart';
import 'conversations/landlord_danhsachtinnhan_page.dart';
import 'dashboard/landlord_tongquan_page.dart';
import 'incidents/landlord_yeucausuachua_page.dart';
import 'billing/landlord_billing_page.dart';
import 'leases/landlord_leases_page.dart';
import 'payments/landlord_payments_page.dart';
import 'payment_accounts/landlord_payment_accounts_page.dart';
import 'landlord_ui.dart';
import 'members/landlord_nguoithue_page.dart';
import 'meter_readings/landlord_chisodiennuoc_page.dart';
import 'properties/landlord_properties_page.dart';
import 'room_types/landlord_room_types_page.dart';
import 'rooms/landlord_rooms_page.dart';
import 'services/landlord_dichvubanggia_page.dart';
import 'viewings/landlord_viewings_page.dart';

Widget buildLandlordPage(BuildContext context, RoleDestination destination) {
  return switch (destination.id) {
    // Phần của Minh
    'dashboard' => const LandlordTongQuanPage(),
    'services' => const LandlordDichVuBangGiaPage(),
    'meter_readings' => const LandlordChiSoDienNuocPage(),
    'members' => const LandlordNguoiThuePage(),
    'conversations' => const LandlordDanhSachTinNhanPage(),
    'incidents' => const LandlordYeuCauSuaChuaPage(),

    // Phần của Nguyên
    'properties' => const LandlordPropertiesPage(),
    'room_types' => const LandlordRoomTypesPage(),
    'rooms' => const LandlordRoomsPage(),
    'viewings' => const LandlordViewingsPage(),
    'announcements' || 'notifications' => const LandlordAnnouncementsPage(),
    'leases' => const LandlordLeasesPage(),
    'billing' => const LandlordBillingPage(),
    'payments' => const LandlordPaymentsPage(),
    'payment_accounts' => const LandlordPaymentAccountsPage(),

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
        subtitle: 'Không gian chủ trọ trên Ứng dụng thuê trọ.',
      ),
      const LandlordEmptyState(
        message: 'Màn hình này sẽ được thiết kế ở bước tiếp theo.',
      ),
    ],
  );
}
