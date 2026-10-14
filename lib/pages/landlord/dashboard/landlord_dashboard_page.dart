import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import '../finance/landlord_finance_models.dart';
import '../incidents/models/landlord_incident.dart';
import '../rooms/models/landlord_room.dart';
import '../../shared/rental/lease_member.dart';

class LandlordDashboardPage extends StatelessWidget {
  const LandlordDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LandlordDemoStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final rooms = store.roomDetails;
        final vacant = rooms
            .where((room) => room.status == LandlordRoomStatus.vacant)
            .length;
        final occupied = rooms
            .where((room) => room.status == LandlordRoomStatus.occupied)
            .length;
        final now = DateTime.now();
        final invoices = store.invoices.where(
          (invoice) =>
              !invoice.cancelled &&
              invoice.period.year == now.year &&
              invoice.period.month == now.month,
        );
        final total = invoices.fold<int>(
          0,
          (sum, invoice) => sum + invoice.total,
        );
        final paid = invoices.fold<int>(
          0,
          (sum, invoice) => sum + invoice.paidAmount,
        );
        final pending = store.payments
            .where((payment) => payment.status == LandlordPaymentStatus.pending)
            .length;
        final newIncidents = store.incidents.where(
          (incident) => incident.status == IncidentStatus.newly,
        );
        final pendingMembers = store.members
            .where(
              (member) =>
                  member.status == LeaseMemberStatus.pending &&
                  (store.leaseById(member.leaseId)?.isCurrent ?? false),
            )
            .length;
        final unrecorded = store.activeLeases
            .where(
              (lease) =>
                  !(store
                          .readingForRoom(
                            lease.room,
                            DateTime(now.year, now.month),
                          )
                          ?.isDone ??
                      false),
            )
            .length;
        return LandlordPageFrame(
          children: [
            LandlordPageTitle(
              title: 'Xin chào, ${store.property.ownerName}',
              subtitle: 'Tình hình nhà trọ ${store.property.name} hôm nay.',
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _StatCard(
                  label: 'Phòng trống',
                  value: '$vacant / ${rooms.length}',
                  icon: Icons.meeting_room_outlined,
                  color: const Color(0xFF16836F),
                ),
                _StatCard(
                  label: 'Đang thuê',
                  value: '$occupied',
                  icon: Icons.groups_outlined,
                  color: landlordBlue,
                ),
                _StatCard(
                  label: 'Hóa đơn cần thu',
                  value: '${store.payableInvoices.length}',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFE08A1E),
                ),
                _StatCard(
                  label: 'Sự cố mới',
                  value: '${newIncidents.length}',
                  icon: Icons.build_outlined,
                  color: const Color(0xFFD64545),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LandlordCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đã thu cho hóa đơn tháng này',
                    style: TextStyle(color: landlordMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatLandlordMoney(paid),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : (paid / total).clamp(0, 1),
                    color: landlordBlue,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đã thu ${total == 0 ? 0 : (paid * 100 / total).round()}% · còn $pending thanh toán chờ duyệt',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Việc cần làm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _TodoTile(
              icon: Icons.bolt_outlined,
              title: 'Nhập chỉ số điện nước tháng ${now.month}',
              subtitle: 'Còn $unrecorded phòng đang thuê chưa nhập',
            ),
            _TodoTile(
              icon: Icons.fact_check_outlined,
              title: 'Duyệt thanh toán',
              subtitle: '$pending khoản đang chờ kiểm tra',
            ),
            for (final incident in newIncidents)
              _TodoTile(
                icon: Icons.build_outlined,
                title: 'Sự cố: ${incident.title}',
                subtitle: 'Phòng ${incident.room} · ${incident.status.label}',
              ),
            _TodoTile(
              icon: Icons.person_add_alt_outlined,
              title: 'Duyệt thành viên mới',
              subtitle: '$pendingMembers yêu cầu thêm người',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: landlordLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            value,
            style: const TextStyle(
              color: landlordInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: landlordMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LandlordCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: landlordBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: landlordBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
