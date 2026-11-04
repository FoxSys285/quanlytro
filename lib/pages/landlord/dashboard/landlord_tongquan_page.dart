import 'package:flutter/material.dart';

import '../../../layouts/landlord_navigation.dart';
import '../../../layouts/role_layout.dart';
import '../../shared/conversations/conversation_store.dart';
import '../../shared/rental/lease_member.dart';
import '../../shared/viewings/models/room_viewing.dart';
import '../../shared/viewings/viewing_store.dart';
import '../announcements/landlord_announcements_page.dart';
import '../billing/landlord_billing_page.dart';
import '../conversations/landlord_danhsachtinnhan_page.dart';
import '../finance/landlord_finance_models.dart';
import '../incidents/landlord_yeucausuachua_page.dart';
import '../incidents/models/landlord_suco.dart';
import '../landlord_demo_store.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import '../leases/landlord_leases_page.dart';
import '../members/landlord_nguoithue_page.dart';
import '../meter_readings/landlord_chisodiennuoc_page.dart';
import '../payments/landlord_payments_page.dart';
import '../rooms/landlord_rooms_page.dart';
import '../rooms/models/landlord_room.dart';
import '../services/landlord_dichvubanggia_page.dart';
import '../viewings/landlord_viewings_page.dart';

class LandlordTongQuanPage extends StatelessWidget {
  const LandlordTongQuanPage({super.key});

  static void _openPage(BuildContext context, String title, Widget page) {
    final destination = switch (page) {
      LandlordRoomsPage() => 'rooms',
      LandlordBillingPage() => 'billing',
      LandlordYeuCauSuaChuaPage() => 'incidents',
      LandlordViewingsPage() => 'viewings',
      LandlordPaymentsPage() => 'payments',
      LandlordDanhSachTinNhanPage() => 'conversations',
      LandlordChiSoDienNuocPage() => 'meter_readings',
      LandlordNguoiThuePage() => 'members',
      LandlordLeasesPage() => 'leases',
      LandlordDichVuBangGiaPage() => 'services',
      LandlordAnnouncementsPage() => 'announcements',
      _ => 'dashboard',
    };
    if (RoleLayoutShell.tryNavigateTo(context, destination)) return;
    LandlordNavigation.push<void>(
      context,
      title: title,
      page: page,
      destinationId: destination,
    );
  }

  static String _greeting(int hour) {
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final store = LandlordDemoStore.activeInstance;
    final conversations = ConversationStore.instance;
    final viewings = ViewingStore.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([store, conversations, viewings]),
      builder: (context, _) {
        final palette = LandlordPalette.of(context);
        final now = DateTime.now();
        final rooms = store.roomDetails;
        final occupied = rooms
            .where((room) => room.status == LandlordRoomStatus.occupied)
            .length;
        final currentInvoices = store.invoices.where(
          (invoice) =>
              !invoice.cancelled &&
              invoice.period.year == now.year &&
              invoice.period.month == now.month,
        );
        final due = currentInvoices.map((invoice) => invoice.total).sum;
        final paid = currentInvoices.map((invoice) => invoice.paidAmount).sum;
        final collectionRate = due == 0 ? 0.0 : (paid / due).clamp(0.0, 1.0);
        final unpaidInvoices = store.invoices
            .where(
              (invoice) =>
                  !invoice.cancelled &&
                  (invoice.status == LandlordInvoiceStatus.unpaid ||
                      invoice.status == LandlordInvoiceStatus.overdue),
            )
            .length;
        final newIncidents = store.incidents
            .where((incident) => incident.status == IncidentStatus.newly)
            .length;
        final upcomingViewings = viewings.records
            .where(
              (viewing) =>
                  viewing.propertyId == store.property.id &&
                  (viewing.status == ViewingStatus.pending ||
                      viewing.status == ViewingStatus.confirmed),
            )
            .length;
        final pendingPayments = store.payments
            .where((payment) => payment.status == LandlordPaymentStatus.pending)
            .length;
        final unreadMessages = conversations.conversations
            .where(
              (conversation) => conversation.propertyId == store.property.id,
            )
            .map((conversation) => conversation.unread)
            .sum;
        final period = DateTime(now.year, now.month);
        final missingReadings = store.activeLeases.where((lease) {
          final reading = store.readingForRoom(lease.room, period);
          return reading == null || !reading.isDone;
        }).length;
        final pendingMembers = store.members.where((member) {
          final lease = store.leaseById(member.leaseId);
          return member.status == LeaseMemberStatus.pending &&
              lease != null &&
              lease.isCurrent;
        }).length;
        final expiringLeases = store.activeLeases.where((lease) {
          final days = lease.endDate.difference(now).inDays;
          return days >= 0 && days <= 30;
        }).length;

        final tasks = <_DashboardTask>[
          _DashboardTask(
            icon: Icons.receipt_long_rounded,
            title: 'Hóa đơn chưa thanh toán',
            subtitle: '$unpaidInvoices hóa đơn đang chờ thu',
            count: unpaidInvoices,
            color: const Color(0xFFE76B52),
            onTap: () =>
                _openPage(context, 'Hóa đơn', const LandlordBillingPage()),
          ),
          _DashboardTask(
            icon: Icons.handyman_rounded,
            title: 'Yêu cầu sửa chữa mới',
            subtitle: '$newIncidents sự cố cần xem xét',
            count: newIncidents,
            color: const Color(0xFFD48A28),
            onTap: () => _openPage(
              context,
              'Yêu cầu sửa chữa',
              const LandlordYeuCauSuaChuaPage(),
            ),
          ),
          _DashboardTask(
            icon: Icons.calendar_month_rounded,
            title: 'Lịch xem phòng',
            subtitle: '$upcomingViewings lịch hẹn cần chuẩn bị',
            count: upcomingViewings,
            color: const Color(0xFF4A70CE),
            onTap: () => _openPage(
              context,
              'Lịch xem phòng',
              const LandlordViewingsPage(),
            ),
          ),
          _DashboardTask(
            icon: Icons.fact_check_rounded,
            title: 'Thanh toán chờ duyệt',
            subtitle: '$pendingPayments khoản cần kiểm tra',
            count: pendingPayments,
            color: const Color(0xFF279B91),
            onTap: () => _openPage(
              context,
              'Duyệt thanh toán',
              const LandlordPaymentsPage(),
            ),
          ),
          _DashboardTask(
            icon: Icons.chat_bubble_rounded,
            title: 'Tin nhắn chưa đọc',
            subtitle: '$unreadMessages tin nhắn từ người thuê',
            count: unreadMessages,
            color: const Color(0xFF665CC6),
            onTap: () => _openPage(
              context,
              'Tin nhắn',
              const LandlordDanhSachTinNhanPage(),
            ),
          ),
          _DashboardTask(
            icon: Icons.bolt_rounded,
            title: 'Chỉ số điện nước',
            subtitle: '$missingReadings phòng chưa ghi chỉ số tháng này',
            count: missingReadings,
            color: const Color(0xFFD48A28),
            onTap: () => _openPage(
              context,
              'Chỉ số điện nước',
              const LandlordChiSoDienNuocPage(),
            ),
          ),
          _DashboardTask(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Thành viên chờ duyệt',
            subtitle: '$pendingMembers yêu cầu thêm người vào phòng',
            count: pendingMembers,
            color: const Color(0xFF665CC6),
            onTap: () =>
                _openPage(context, 'Người thuê', const LandlordNguoiThuePage()),
          ),
          _DashboardTask(
            icon: Icons.description_rounded,
            title: 'Hợp đồng sắp hết hạn',
            subtitle: '$expiringLeases hợp đồng còn tối đa 30 ngày',
            count: expiringLeases,
            color: const Color(0xFF4A70CE),
            onTap: () =>
                _openPage(context, 'Hợp đồng thuê', const LandlordLeasesPage()),
          ),
        ];

        return LandlordPageFrame(
          children: [
            _DashboardWelcome(
              greeting: _greeting(now.hour),
              ownerName: store.property.ownerName,
              propertyName: store.property.name,
            ),
            const SizedBox(height: 17),
            _DashboardOverviewCard(
              month: now.month,
              year: now.year,
              paid: paid,
              due: due,
              occupied: occupied,
              totalRooms: rooms.length,
              collectionRate: collectionRate,
              onRooms: () =>
                  _openPage(context, 'Phòng trọ', const LandlordRoomsPage()),
            ),
            const SizedBox(height: 24),
            const _DashboardSectionTitle(
              eyebrow: 'LỐI TẮT QUẢN LÝ',
              title: 'Thao tác nhanh',
              subtitle: 'Những việc bạn thường dùng mỗi ngày',
            ),
            const SizedBox(height: 15),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 4 : 2;
                const spacing = 11.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: width,
                      child: _DashboardQuickCard(
                        icon: Icons.meeting_room_rounded,
                        title: 'Phòng trọ',
                        subtitle: '${rooms.length} phòng đang quản lý',
                        color: palette.primary,
                        onTap: () => _openPage(
                          context,
                          'Phòng trọ',
                          const LandlordRoomsPage(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _DashboardQuickCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'Hóa đơn',
                        subtitle: '$unpaidInvoices khoản cần thu',
                        color: const Color(0xFF248F89),
                        onTap: () => _openPage(
                          context,
                          'Hóa đơn',
                          const LandlordBillingPage(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _DashboardQuickCard(
                        icon: Icons.bolt_rounded,
                        title: 'Điện nước',
                        subtitle: '$missingReadings phòng chưa chốt',
                        color: const Color(0xFF695CC8),
                        onTap: () => _openPage(
                          context,
                          'Chỉ số điện nước',
                          const LandlordChiSoDienNuocPage(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _DashboardQuickCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Lịch xem',
                        subtitle: '$upcomingViewings lịch sắp tới',
                        color: const Color(0xFFD18729),
                        onTap: () => _openPage(
                          context,
                          'Lịch xem phòng',
                          const LandlordViewingsPage(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 29),
            _DashboardSectionTitle(
              eyebrow: 'ƯU TIÊN HÔM NAY',
              title: 'Cần xử lý',
              subtitle: 'Tập trung vào các mục đang chờ',
              count: tasks.where((task) => task.count > 0).length,
            ),
            const SizedBox(height: 15),
            _DashboardTaskQueue(tasks: tasks),
            const SizedBox(height: 29),
            const _DashboardSectionTitle(
              eyebrow: 'VẬN HÀNH NHÀ TRỌ',
              title: 'Công cụ khác',
              subtitle: 'Cập nhật dịch vụ và thông tin gửi người thuê',
            ),
            const SizedBox(height: 15),
            _DashboardUtilityCard(
              icon: Icons.tune_rounded,
              title: 'Dịch vụ & bảng giá',
              subtitle: '${store.services.length} dịch vụ đang áp dụng',
              onTap: () => _openPage(
                context,
                'Dịch vụ & bảng giá',
                const LandlordDichVuBangGiaPage(),
              ),
            ),
            const SizedBox(height: 10),
            _DashboardUtilityCard(
              icon: Icons.campaign_rounded,
              title: 'Gửi thông báo',
              subtitle: 'Nội quy, bảo trì và thông tin mới',
              onTap: () => _openPage(
                context,
                'Thông báo',
                const LandlordAnnouncementsPage(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardWelcome extends StatelessWidget {
  const _DashboardWelcome({
    required this.greeting,
    required this.ownerName,
    required this.propertyName,
  });

  final String greeting;
  final String ownerName;
  final String propertyName;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $ownerName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.65,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tổng quan vận hành · $propertyName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: palette.primarySoft,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Chủ trọ',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardOverviewCard extends StatelessWidget {
  const _DashboardOverviewCard({
    required this.month,
    required this.year,
    required this.paid,
    required this.due,
    required this.occupied,
    required this.totalRooms,
    required this.collectionRate,
    required this.onRooms,
  });

  final int month;
  final int year;
  final int paid;
  final int due;
  final int occupied;
  final int totalRooms;
  final double collectionRate;
  final VoidCallback onRooms;

  @override
  Widget build(BuildContext context) {
    final occupancyRate = totalRooms == 0
        ? 0
        : (occupied * 100 / totalRooms).round();
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142F70), Color(0xFF315FCA), Color(0xFF233F9A)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A315FC9),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -105,
            right: -85,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FFFFFF), width: 35),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: -112,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x10FFFFFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x2BFFFFFF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFB6E7FF),
                            size: 15,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'TỔNG QUAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'THÁNG $month/$year',
                      style: const TextStyle(
                        color: Color(0xFFD8E6FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đã thu trong tháng',
                  style: TextStyle(color: Color(0xFFD8E6FF), fontSize: 12),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatLandlordMoney(paid),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  due == 0
                      ? 'Chưa có hóa đơn trong tháng này'
                      : 'Tổng cần thu: ${formatLandlordMoney(due)}',
                  style: const TextStyle(
                    color: Color(0xFFD8E6FF),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardHeroMetric(
                        icon: Icons.door_front_door_rounded,
                        value: '$occupancyRate%',
                        label: '$occupied/$totalRooms phòng đang thuê',
                        progress: totalRooms == 0 ? 0 : occupied / totalRooms,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _DashboardHeroMetric(
                        icon: Icons.trending_up_rounded,
                        value: '${(collectionRate * 100).round()}%',
                        label: 'Tiến độ thu',
                        progress: collectionRate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onRooms,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFF254CBA),
                            size: 19,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Xem & quản lý phòng trọ',
                              style: TextStyle(
                                color: Color(0xFF2144A8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF254CBA),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroMetric extends StatelessWidget {
  const _DashboardHeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.progress,
  });

  final IconData icon;
  final String value;
  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: const Color(0x28FFFFFF),
        border: Border.all(color: const Color(0x30FFFFFF)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFBFE8FF), size: 16),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0x55FFFFFF),
              color: const Color(0xFF9CE5F4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionTitle extends StatelessWidget {
  const _DashboardSectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.count,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: palette.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (count != null && count! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF422F36)
                      : const Color(0xFFFDEBE7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$count việc',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFFFAF9F)
                        : const Color(0xFFB64A38),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: palette.muted, fontSize: 12)),
      ],
    );
  }
}

class _DashboardQuickCard extends StatelessWidget {
  const _DashboardQuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.north_east_rounded,
                      color: palette.muted,
                      size: 17,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTask {
  const _DashboardTask({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;
}

class _DashboardTaskQueue extends StatefulWidget {
  const _DashboardTaskQueue({required this.tasks});

  final List<_DashboardTask> tasks;

  @override
  State<_DashboardTaskQueue> createState() => _DashboardTaskQueueState();
}

class _DashboardTaskQueueState extends State<_DashboardTaskQueue> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final pending = widget.tasks.where((task) => task.count > 0).toList();
    final visible = expanded ? pending : pending.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: pending.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: palette.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mọi việc đã được xử lý. Nhà trọ đang vận hành ổn định.',
                      style: TextStyle(color: palette.ink, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  if (index > 0)
                    Divider(height: 1, indent: 62, color: palette.line),
                  _DashboardTaskRow(task: visible[index]),
                ],
                if (pending.length > 3) ...[
                  Divider(height: 1, color: palette.line),
                  TextButton.icon(
                    onPressed: () => setState(() => expanded = !expanded),
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 19,
                    ),
                    label: Text(
                      expanded
                          ? 'Thu gọn'
                          : 'Xem thêm ${pending.length - 3} mục',
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _DashboardTaskRow extends StatelessWidget {
  const _DashboardTaskRow({required this.task});

  final _DashboardTask task;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: task.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: task.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(task.icon, color: task.color, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: task.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${task.count}',
                  style: TextStyle(
                    color: task.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded, color: palette.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardUtilityCard extends StatelessWidget {
  const _DashboardUtilityCard({
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
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: palette.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: palette.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
