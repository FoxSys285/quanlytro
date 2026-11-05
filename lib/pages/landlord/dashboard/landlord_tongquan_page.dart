import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../layouts/landlord_navigation.dart';
import '../../shared/conversations/conversation_store.dart';
import '../../shared/viewings/viewing_store.dart';
import '../announcements/landlord_announcements_page.dart';
import '../billing/landlord_billing_page.dart';
import '../conversations/landlord_danhsachtinnhan_page.dart';
import '../finance/landlord_finance_models.dart';
import '../finance/landlord_room_balance.dart';
import '../finance/landlord_room_balance_card.dart';
import '../incidents/components/landlord_incident_glass_card.dart';
import '../incidents/landlord_yeucausuachua_page.dart';
import '../incidents/models/landlord_suco.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import '../leases/landlord_leases_page.dart';
import '../members/landlord_nguoithue_page.dart';
import '../meter_readings/landlord_chisodiennuoc_page.dart';
import '../payments/landlord_payments_page.dart';
import '../properties/landlord_properties_page.dart';
import '../properties/landlord_verification_page.dart';
import '../room_types/landlord_room_types_page.dart';
import '../rooms/landlord_floor_plan_page.dart';
import '../rooms/landlord_rooms_page.dart';
import '../rooms/models/landlord_room.dart';
import '../services/landlord_dichvubanggia_page.dart';
import '../viewings/landlord_viewings_page.dart';

class LandlordTongQuanPage extends StatelessWidget {
  const LandlordTongQuanPage({super.key, this.profileName});
  final String? profileName;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      RentalPortfolio.instance,
      AdminStore.instance,
      ConversationStore.instance,
      ViewingStore.instance,
    ]),
    builder: (context, _) {
      final portfolio = RentalPortfolio.instance;
      final store = portfolio.active;
      final palette = LandlordPalette.of(context);
      final now = DateTime.now();
      final rooms = portfolio.stores.expand((s) => s.roomDetails).toList();
      final occupied = rooms
          .where((r) => r.status == LandlordRoomStatus.occupied)
          .length;
      final vacant = rooms
          .where((r) => r.status == LandlordRoomStatus.vacant)
          .length;
      final unpaid =
          landlordRoomBalances(
              store,
              now,
            ).where((b) => b.remaining > 0).toList()
            ..sort((a, b) => b.remaining.compareTo(a.remaining));
      final incidents = [...store.incidents]
        ..sort((a, b) {
          final rankA =
              (a.status == IncidentStatus.closed ? 10 : 0) + (a.urgent ? 0 : 1);
          final rankB =
              (b.status == IncidentStatus.closed ? 10 : 0) + (b.urgent ? 0 : 1);
          return rankA.compareTo(rankB);
        });
      final monthly = store.invoices.where(
        (i) =>
            !i.cancelled &&
            i.period.year == now.year &&
            i.period.month == now.month,
      );
      final paid = monthly.fold<int>(0, (sum, i) => sum + i.paidAmount);
      final due = monthly.fold<int>(0, (sum, i) => sum + i.total);
      final pendingPayments = store.payments
          .where((p) => p.status == LandlordPaymentStatus.pending)
          .length;
      final unread = ConversationStore.instance
          .forProperty(store.property.id)
          .fold<int>(0, (sum, c) => sum + c.unread);
      final verified = AdminStore.instance.isVerified(store.property.id);
      return LandlordGlassPage(
        title: 'Tổng quan nhà trọ',
        kicker: 'KHÔNG GIAN CHỦ TRỌ',
        subtitle: portfolio.stores.isEmpty
            ? 'Bắt đầu quản lý nhà trọ của bạn.'
            : 'Theo dõi hoạt động · ${store.property.name}',
        profileName: profileName,
        children: [
          PropertyPortfolioSummary(
            properties: portfolio.stores.length,
            rooms: rooms.length,
            occupied: occupied,
            vacant: vacant,
          ),
          const SizedBox(height: 22),
          if (portfolio.stores.isEmpty) ...[
            LandlordGlassCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.add_home_work_rounded,
                    size: 36,
                    color: propertyBlue,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có nhà trọ nào',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tạo hồ sơ nhà trọ, thêm loại phòng và thiết lập sơ đồ tầng.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _open(
                      context,
                      'properties',
                      'Nhà trọ',
                      const LandlordPropertiesPage(),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo phòng trọ'),
                  ),
                ],
              ),
            ),
          ] else ...[
            LandlordGlassCard(
              onTap: () => LandlordNavigation.push<void>(
                context,
                page: LandlordVerificationPage(store: store),
                title: 'Xác minh nhà trọ',
                destinationId: 'properties',
              ),
              child: Row(
                children: [
                  Icon(
                    verified ? Icons.verified_rounded : Icons.shield_outlined,
                    color: verified ? const Color(0xFF17A374) : propertyBlue,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verified
                              ? 'Nhà trọ đã xác minh'
                              : 'Hoàn thiện hồ sơ nhà trọ',
                          style: TextStyle(
                            color: palette.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          verified
                              ? 'Hồ sơ đã được quản trị viên duyệt.'
                              : AdminStore.instance
                                    .reviewNote(store.property.id)
                                    .isNotEmpty
                              ? 'Quản trị viên yêu cầu bổ sung hồ sơ.'
                              : store.property.verificationSubmittedAt == null
                              ? 'Gửi thông tin để xác minh nhà trọ.'
                              : 'Hồ sơ đang chờ quản trị viên xét duyệt.',
                          style: TextStyle(color: palette.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: propertyBlue),
                ],
              ),
            ),
            if (store.roomTypes.isEmpty || store.catalog.isEmpty) ...[
              const SizedBox(height: 14),
              LandlordGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.roomTypes.isEmpty
                          ? 'Thêm loại phòng'
                          : 'Thiết lập tầng và số phòng',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Khai báo giá thuê, tiện nghi và số phòng cho từng tầng.',
                      style: TextStyle(color: palette.muted),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        store.roomTypes.isEmpty
                            ? 'Thêm loại phòng'
                            : 'Thiết lập sơ đồ tầng',
                      ),
                      onPressed: () {
                        if (store.roomTypes.isEmpty) {
                          _open(
                            context,
                            'room_types',
                            'Loại phòng',
                            const LandlordRoomTypesPage(),
                          );
                        } else {
                          LandlordNavigation.push<void>(
                            context,
                            page: LandlordFloorPlanSetupPage(store: store),
                            title: 'Thiết lập tầng và phòng',
                            destinationId: 'rooms',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const LandlordGlassSection(
              title: 'Thao tác nhanh',
              subtitle: 'Lối tắt quản lý nhà trọ mỗi ngày',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 4 : 2;
                final width =
                    (constraints.maxWidth - 10 * (columns - 1)) / columns;
                final actions = <(IconData, String, String, VoidCallback)>[
                  (
                    Icons.meeting_room_rounded,
                    'Phòng',
                    '${store.catalog.length} phòng',
                    () => _open(
                      context,
                      'rooms',
                      'Phòng trọ',
                      const LandlordRoomsPage(),
                    ),
                  ),
                  (
                    Icons.receipt_long_rounded,
                    'Lập hóa đơn',
                    '${unpaid.length} phòng còn nợ',
                    () => _open(
                      context,
                      'billing',
                      'Thu chi',
                      const LandlordBillingPage(),
                    ),
                  ),
                  (
                    Icons.bolt_rounded,
                    'Ghi điện nước',
                    'Cập nhật chỉ số',
                    () => _open(
                      context,
                      'meter_readings',
                      'Chỉ số điện nước',
                      const LandlordChiSoDienNuocPage(),
                    ),
                  ),
                  (
                    Icons.forum_rounded,
                    'Tin nhắn',
                    '$unread tin chưa đọc',
                    () => _open(
                      context,
                      'conversations',
                      'Tin nhắn',
                      const LandlordDanhSachTinNhanPage(),
                    ),
                  ),
                  (
                    Icons.calendar_month_rounded,
                    'Lịch xem phòng',
                    'Quản lý lịch hẹn',
                    () => _open(
                      context,
                      'viewings',
                      'Lịch xem phòng',
                      const LandlordViewingsPage(),
                    ),
                  ),
                  (
                    Icons.fact_check_rounded,
                    'Duyệt thanh toán',
                    '$pendingPayments khoản chờ duyệt',
                    () => _open(
                      context,
                      'payments',
                      'Duyệt thanh toán',
                      const LandlordPaymentsPage(),
                    ),
                  ),
                  (
                    Icons.people_alt_rounded,
                    'Người thuê',
                    'Thành viên & yêu cầu',
                    () => _open(
                      context,
                      'members',
                      'Người thuê',
                      const LandlordNguoiThuePage(),
                    ),
                  ),
                  (
                    Icons.description_rounded,
                    'Hợp đồng',
                    '${store.activeLeases.length} đang có hiệu lực',
                    () => _open(
                      context,
                      'leases',
                      'Hợp đồng',
                      const LandlordLeasesPage(),
                    ),
                  ),
                ];
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (icon, title, subtitle, action) in actions)
                      SizedBox(
                        width: width,
                        child: _Shortcut(
                          icon: icon,
                          title: title,
                          subtitle: subtitle,
                          onTap: action,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            LandlordGlassSection(
              title: 'Báo cáo sự cố',
              subtitle:
                  '${incidents.where((i) => i.status != IncidentStatus.closed).length} yêu cầu đang theo dõi',
              trailing: TextButton(
                onPressed: () => _open(
                  context,
                  'incidents',
                  'Yêu cầu sửa chữa',
                  const LandlordYeuCauSuaChuaPage(),
                ),
                child: const Text('Xem tất cả'),
              ),
            ),
            if (incidents.isEmpty)
              const LandlordGlassCard(
                child: Text('Chưa có báo cáo sự cố từ người thuê.'),
              ),
            for (final incident in incidents.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LandlordIncidentGlassCard(
                  incident: incident,
                  store: store,
                ),
              ),
            const SizedBox(height: 24),
            LandlordGlassSection(
              title: 'Phòng chưa đóng tiền',
              subtitle:
                  '${unpaid.length} phòng · ${formatLandlordMoney(unpaid.fold<int>(0, (sum, b) => sum + b.remaining))} còn phải thu',
              trailing: TextButton(
                onPressed: () => _open(
                  context,
                  'billing',
                  'Thu chi',
                  const LandlordBillingPage(),
                ),
                child: const Text('Xem tất cả'),
              ),
            ),
            if (unpaid.isEmpty)
              const LandlordGlassCard(
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF17A374)),
                    SizedBox(width: 10),
                    Expanded(child: Text('Không có phòng còn nợ tiền trọ.')),
                  ],
                ),
              ),
            for (final balance in unpaid.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LandlordRoomBalanceCard(
                  balance: balance,
                  onTap: () => LandlordNavigation.push<void>(
                    context,
                    page: LandlordBillingPage(
                      initialRoom: balance.details.room.code,
                    ),
                    destinationId: 'billing',
                    title: 'Thu chi',
                  ),
                ),
              ),
            const SizedBox(height: 24),
            LandlordGlassSection(
              title: 'Thu tiền tháng ${now.month}/${now.year}',
              subtitle: 'Khoản đã thu được tính sau khi xác nhận thanh toán',
            ),
            LandlordBluePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đã thu trong tháng',
                    style: TextStyle(color: Color(0xFFDDEBFF), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatLandlordMoney(paid),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng cần thu: ${formatLandlordMoney(due)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDDEBFF),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: due == 0 ? 0 : (paid / due).clamp(0, 1),
                      minHeight: 6,
                      color: const Color(0xFF9BE8FF),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => _open(
                      context,
                      'rooms',
                      'Phòng trọ',
                      const LandlordRoomsPage(),
                    ),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Xem & quản lý phòng trọ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const LandlordGlassSection(title: 'Công cụ khác'),
            _Utility(
              icon: Icons.tune_rounded,
              title: 'Dịch vụ & bảng giá',
              subtitle: '${store.services.length} dịch vụ đang áp dụng',
              onTap: () => _open(
                context,
                'services',
                'Dịch vụ & bảng giá',
                const LandlordDichVuBangGiaPage(),
              ),
            ),
            const SizedBox(height: 10),
            _Utility(
              icon: Icons.campaign_rounded,
              title: 'Gửi thông báo',
              subtitle: 'Nội quy, bảo trì và thông tin mới',
              onTap: () => _open(
                context,
                'announcements',
                'Thông báo',
                const LandlordAnnouncementsPage(),
              ),
            ),
          ],
        ],
      );
    },
  );

  void _open(
    BuildContext context,
    String destination,
    String title,
    Widget page,
  ) => openLandlordDestination(context, destination, title, page);
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LandlordGlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78D9FF), propertyBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 13),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _Utility extends StatelessWidget {
  const _Utility({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LandlordGlassCard(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: propertyBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: propertyBlue),
      ],
    ),
  );
}
