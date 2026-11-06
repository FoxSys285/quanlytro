import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../layouts/landlord_navigation.dart';
import '../../shared/announcements/announcement_store.dart';
import '../../shared/conversations/conversation_store.dart';
import '../../shared/media/room_photo_gallery.dart';
import '../../shared/widgets/google_maps_actions.dart';
import '../announcements/landlord_announcements_page.dart';
import '../billing/landlord_billing_page.dart';
import '../conversations/landlord_tinnhan_page.dart';
import '../finance/landlord_room_balance.dart';
import '../finance/landlord_finance_models.dart';
import '../finance/landlord_room_balance_card.dart';
import '../incidents/components/landlord_incident_glass_card.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import 'components/landlord_room_editor.dart';
import 'models/landlord_room.dart';

class LandlordRoomDetailPage extends StatelessWidget {
  const LandlordRoomDetailPage({
    super.key,
    required this.store,
    required this.roomCode,
  });
  final LandlordDemoStore store;
  final String roomCode;

  @override
  Widget build(BuildContext context) {
    final announcements = AnnouncementStore.forRental(store);
    return ListenableBuilder(
      listenable: Listenable.merge([store, announcements]),
      builder: (context, _) {
        final details = store.roomDetails
            .where((d) => d.room.code == roomCode)
            .firstOrNull;
        final unread = announcements.inbox.where((a) => !a.isRead).length;
        return Scaffold(
          backgroundColor: LandlordPalette.of(context).canvas,
          appBar: AppBar(
            backgroundColor: LandlordPalette.of(context).surface
                .withValues(alpha: 0.92),
            leading: IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết phòng${details == null ? '' : ' ${details.room.code}'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  store.property.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandlordPalette.of(context).muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'Thông báo',
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                  onPressed: () => LandlordNavigation.push<void>(
                    context,
                    page: LandlordAnnouncementsPage(store: announcements),
                    title: 'Thông báo',
                    destinationId: 'announcements',
                  ),
                ),
              ),
            ],
          ),
          body: PropertyPortfolioBackdrop(
            child: details == null
                ? const Center(child: Text('Phòng không còn tồn tại.'))
                : _content(context, details),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, LandlordRoomDetails details) {
    final palette = LandlordPalette.of(context);
    final room = details.room;
    final lease = details.lease;
    final balance = landlordRoomBalances(
      store,
      DateTime.now(),
    ).firstWhere((b) => b.details.room.code == roomCode);
    final incidents = store.incidents
        .where(
          (i) => store.canonicalRoom(i.room) == store.canonicalRoom(roomCode),
        )
        .toList();
    final canDelete = !store.leases.any(
      (l) => store.canonicalRoom(l.room) == store.canonicalRoom(roomCode),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: RoomPhotoGallery(
                  interactive: true,
                  photos: details.type?.photos ?? const [],
                  label: 'Ảnh ${details.typeName} · Phòng $roomCode',
                  height: MediaQuery.sizeOf(context).width >= 700 ? 290 : 210,
                  onTap: () => showRoomPhotoViewer(
                    context,
                    photos: details.type?.photos ?? const [],
                    title: 'Phòng $roomCode',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LandlordBluePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Phòng $roomCode',
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            details.status.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.typeName,
                      style: const TextStyle(
                        color: Color(0xFFDDEBFF),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      details.monthlyRent == null
                          ? 'Chưa có giá thuê'
                          : '${formatLandlordMoney(details.monthlyRent!)} / tháng',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lease == null
                          ? 'Giá theo loại phòng'
                          : 'Giá theo hợp đồng',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFDDEBFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 640 ? 4 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (icon, label, value)
                          in <(IconData, String, String)>[
                            (Icons.layers_outlined, 'Tầng', '${room.floor}'),
                            (
                              Icons.square_foot_rounded,
                              'Diện tích',
                              '${room.area} m²',
                            ),
                            (
                              Icons.people_outline,
                              'Sức chứa',
                              '${room.capacity} người',
                            ),
                            (
                              Icons.person_outline,
                              'Đang ở',
                              lease == null
                                  ? 'Chưa có người thuê'
                                  : '${lease.occupantCount} người',
                            ),
                          ])
                        SizedBox(
                          width: width,
                          child: LandlordGlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, color: propertyBlue, size: 22),
                                const SizedBox(height: 10),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  value,
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const LandlordGlassSection(title: 'Thông tin nhà trọ'),
              LandlordGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.property.name,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: propertyBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            store.property.address,
                            style: TextStyle(
                              color: palette.muted,
                              height: 1.5,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GoogleMapsActions(
                      address: [
                        store.property.address,
                        store.property.ward,
                        store.property.city,
                      ].where((s) => s.isNotEmpty).join(', '),
                    ),
                    if (store.property.description.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        store.property.description,
                        style: TextStyle(
                          color: palette.muted,
                          height: 1.6,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const LandlordGlassSection(title: 'Hợp đồng & người thuê'),
              if (lease == null)
                const LandlordGlassCard(
                  child: Text('Chưa có người thuê cho phòng này.'),
                )
              else ...[
                LandlordGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE0EDFF),
                            child: Icon(
                              Icons.person_rounded,
                              color: propertyBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lease.tenantName,
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Liên hệ: ${lease.phone}',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      _DetailLine('Mã hợp đồng', lease.id),
                      _DetailLine(
                        'Thời hạn',
                        '${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
                      ),
                      _DetailLine(
                        'Đặt cọc',
                        formatLandlordMoney(lease.deposit),
                      ),
                      _DetailLine(
                        'Thanh toán',
                        'Ngày ${lease.dueDay} hằng tháng',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: lease.phone.isEmpty
                                ? null
                                : () => _call(context, lease.phone),
                            icon: const Icon(Icons.call_outlined, size: 18),
                            label: const Text('Gọi người thuê'),
                          ),
                          FilledButton.icon(
                            onPressed: lease.tenantId.isEmpty
                                ? null
                                : () => _chat(context, details),
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Nhắn tin'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LandlordGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thành viên trong phòng',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (store.membersForLease(lease.id).isEmpty)
                        const Text('Chưa có thành viên được ghi nhận.'),
                      for (final member in store.membersForLease(lease.id))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.person_outline,
                            color: propertyBlue,
                          ),
                          title: Text(
                            member.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(member.phone),
                          trailing: member.isRepresentative
                              ? const Icon(
                                  Icons.verified_user_outlined,
                                  color: propertyBlue,
                                  size: 20,
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const LandlordGlassSection(title: 'Thanh toán tiền phòng'),
              LandlordRoomBalanceCard(
                balance: balance,
                onTap: () => LandlordNavigation.push<void>(
                  context,
                  page: LandlordBillingPage(
                    store: store,
                    initialRoom: roomCode,
                  ),
                  destinationId: 'billing',
                ),
              ),
              const SizedBox(height: 24),
              LandlordGlassSection(
                title: 'Sự cố của phòng',
                subtitle: '${incidents.length} báo cáo từ người thuê',
              ),
              if (incidents.isEmpty)
                const LandlordGlassCard(
                  child: Text('Chưa có báo cáo sự cố cho phòng này.'),
                ),
              for (final incident in incidents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LandlordIncidentGlassCard(
                    incident: incident,
                    store: store,
                  ),
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _edit(context, room),
                    style: FilledButton.styleFrom(
                      backgroundColor: propertyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Chỉnh sửa phòng'),
                  ),
                  if (canDelete)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDA4458),
                      ),
                      onPressed: () => _delete(context, room),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Xóa phòng'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, LandlordRoom room) async {
    await showDialog<void>(
      context: context,
      builder: (_) => LandlordRoomEditor(store: store, room: room),
    );
    if (context.mounted &&
        !store.catalog.any((item) => item.code == room.code)) {
      Navigator.pop(context);
    }
  }

  Future<void> _call(BuildContext context, String phone) async {
    try {
      if (!await launchUrl(Uri(scheme: 'tel', path: phone)) &&
          context.mounted) {
        showLandlordMessage(context, 'Không thể mở ứng dụng gọi điện.');
      }
    } catch (_) {
      if (context.mounted) {
        showLandlordMessage(context, 'Không thể mở ứng dụng gọi điện.');
      }
    }
  }

  void _chat(BuildContext context, LandlordRoomDetails details) {
    final lease = details.lease!;
    final messages = ConversationStore.instance;
    final existing = messages
        .forProperty(store.property.id)
        .where(
          (c) =>
              c.tenantId == lease.tenantId &&
              (c.leaseId == lease.id ||
                  store.canonicalRoom(c.room) == store.canonicalRoom(roomCode)),
        )
        .firstOrNull;
    final conversation =
        existing ??
        messages.forRoom(
          propertyId: store.property.id,
          roomId: store.canonicalRoom(roomCode),
          roomName: lease.room,
          landlordName: store.property.ownerName,
          propertyName: store.property.name,
          tenantId: lease.tenantId,
          tenantName: lease.tenantName,
        );
    messages.markRead(conversation, landlord: true);
    LandlordNavigation.push<void>(
      context,
      page: LandlordTinNhanPage(conversation: conversation),
      destinationId: 'conversations',
    );
  }

  Future<void> _delete(BuildContext context, LandlordRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa phòng ${room.code}?'),
        content: const Text('Chỉ có thể xóa phòng chưa có lịch sử hợp đồng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa phòng'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      store.deleteRoom(room.code);
      if (context.mounted) Navigator.pop(context);
    } on ArgumentError catch (error) {
      if (context.mounted) {
        showLandlordMessage(context, error.message.toString());
      }
    }
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              color: LandlordPalette.of(context).muted,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: LandlordPalette.of(context).ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
