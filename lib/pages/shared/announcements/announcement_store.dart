import 'package:flutter/foundation.dart';

import '../../landlord/announcements/models/landlord_announcement.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/incidents/models/landlord_suco.dart';
import '../viewings/models/room_viewing.dart';
import '../viewings/viewing_store.dart';
import '../rental/tenant_session.dart';

/// Delivery snapshots and read state survive navigation and role switching.
class AnnouncementStore extends ChangeNotifier {
  AnnouncementStore({LandlordDemoStore? rental, ViewingStore? viewings})
    : rental = rental ?? LandlordDemoStore.instance,
      viewings = viewings ?? ViewingStore.instance {
    this.rental.addListener(_refresh);
    this.viewings.addListener(_refresh);
    _seed();
  }
  static AnnouncementStore instance = AnnouncementStore();
  static final _propertyStores = <String, AnnouncementStore>{};
  static void reset() {
    instance.dispose();
    for (final store in _propertyStores.values) {
      store.dispose();
    }
    _propertyStores.clear();
    instance = AnnouncementStore();
  }

  static AnnouncementStore forRental(LandlordDemoStore rental) {
    if (identical(rental, LandlordDemoStore.instance)) {
      if (!identical(instance.rental, rental) ||
          !identical(instance.viewings, ViewingStore.instance)) {
        instance.dispose();
        instance = AnnouncementStore(
          rental: rental,
          viewings: ViewingStore.instance,
        );
      }
      return instance;
    }
    final id = rental.property.id;
    final existing = _propertyStores[id];
    if (existing != null &&
        (!identical(existing.rental, rental) ||
            !identical(existing.viewings, ViewingStore.instance))) {
      existing.dispose();
      _propertyStores.remove(id);
    }
    return _propertyStores.putIfAbsent(
      id,
      () => AnnouncementStore(rental: rental),
    );
  }

  final LandlordDemoStore rental;
  final ViewingStore viewings;
  final _sent = <LandlordAnnouncement>[];
  final _recipients = <String, Set<String>>{};
  final _readByTenant = <String, Set<String>>{};
  final _landlordRead = <String>{};
  int _nextId = 1;
  Map<String, dynamic> toMap() => {
    'sent': _sent.map((r) => r.toMap()).toList(),
    'recipients': _recipients.map((k, v) => MapEntry(k, v.toList())),
    'readByTenant': _readByTenant.map((k, v) => MapEntry(k, v.toList())),
    'landlordRead': _landlordRead.toList(),
    'nextId': _nextId,
  };
  void restore(Map<String, dynamic> map) {
    _sent
      ..clear()
      ..addAll(
        (map['sent'] as List).map(
          (r) =>
              LandlordAnnouncement.fromMap(Map<String, dynamic>.from(r as Map)),
        ),
      );
    void restoreSets(String key, Map<String, Set<String>> target) {
      target.clear();
      (map[key] as Map).forEach(
        (k, v) => target[k as String] = Set<String>.from(v as List),
      );
    }

    restoreSets('recipients', _recipients);
    restoreSets('readByTenant', _readByTenant);
    _landlordRead
      ..clear()
      ..addAll(List<String>.from(map['landlordRead'] as List));
    _nextId = map['nextId'] as int;
    notifyListeners();
  }

  void _refresh() => notifyListeners();
  @override
  void dispose() {
    rental.removeListener(_refresh);
    viewings.removeListener(_refresh);
    super.dispose();
  }

  void _seed() {
    if (rental.activeLeases.isEmpty) return;
    final rooms = rental.roomFloors.keys.toList();
    final target =
        rental.currentLeaseForTenant(TenantSession.tenantId)?.room ??
        rental.activeLeases.first.room;
    for (final seed in [
      (
        'power',
        'Tạm ngừng cấp điện để bảo trì',
        'Nhà trọ sẽ tạm ngừng cấp điện từ 09:00 đến 11:00 ngày 06/10/2026 để kiểm tra hệ thống điện. Vui lòng sạc thiết bị trước thời gian bảo trì.',
        rooms,
        AnnouncementPriority.high,
      ),
      (
        'rent',
        'Nhắc thanh toán tiền phòng tháng 10',
        'Vui lòng kiểm tra các khoản trong mục Hóa đơn và thanh toán theo hạn trên hóa đơn. Khi chuyển khoản, ghi rõ mã hóa đơn.',
        <String>[target],
        AnnouncementPriority.normal,
      ),
      (
        'meters',
        'Kiểm tra chỉ số điện nước tháng này',
        'Chủ trọ sẽ kiểm tra chỉ số điện nước lúc 18:00 ngày 07/10/2026. Vui lòng sắp xếp một người có mặt tại phòng.',
        <String>[target],
        AnnouncementPriority.normal,
      ),
      (
        'cleaning',
        'Giữ vệ sinh khu vực sinh hoạt chung',
        'Vui lòng để rác đúng nơi quy định và giữ vệ sinh hành lang, khu vực giặt chung.',
        rooms,
        AnnouncementPriority.normal,
      ),
    ]) {
      _deliver(
        LandlordAnnouncement(
          id: seed.$1,
          propertyId: rental.property.id,
          title: seed.$2,
          content: seed.$3,
          category: seed.$1 == 'rent'
              ? AnnouncementCategory.finance
              : AnnouncementCategory.operations,
          priority: seed.$5,
          createdAt: DateTime(2026, 10, 5 - _sent.length, 8, 30),
          recipients: seed.$4,
          audienceLabel: seed.$4.length == 1
              ? 'Phòng ${seed.$4.single}'
              : 'Tất cả các phòng',
        ),
      );
    }
  }

  List<LandlordAnnouncement> get sent => List.unmodifiable(_sent);
  void _deliver(LandlordAnnouncement announcement) {
    final rooms = announcement.recipients.map(rental.canonicalRoom).toSet();
    final leases = rental.activeLeases.where(
      (lease) =>
          lease.propertyId == announcement.propertyId &&
          rooms.contains(rental.canonicalRoom(lease.room)),
    );
    _recipients[announcement.id] = {
      for (final lease in leases)
        for (final member in rental.membersForLease(lease.id)) member.tenantId,
    };
    _sent.add(announcement);
  }

  void send(LandlordAnnouncement draft) {
    if (draft.propertyId != rental.property.id ||
        draft.title.trim().isEmpty ||
        draft.content.trim().isEmpty ||
        draft.recipients.isEmpty ||
        draft.recipients.any((room) => rental.roomByCode(room) == null)) {
      throw ArgumentError(
        'Kiểm tra nhà trọ, nội dung và phòng nhận thông báo.',
      );
    }
    _deliver(
      LandlordAnnouncement(
        id: 'announcement-${_nextId++}',
        title: draft.title.trim(),
        content: draft.content.trim(),
        category: draft.category,
        createdAt: DateTime.now(),
        propertyId: draft.propertyId,
        priority: draft.priority,
        recipients: List.unmodifiable(draft.recipients),
        audienceLabel: draft.audienceLabel,
      ),
    );
    notifyListeners();
  }

  List<LandlordAnnouncement> forTenant(String tenantId) => [
    ..._sent.where((item) => _recipients[item.id]?.contains(tenantId) ?? false),
    for (final payment in rental.paymentsForTenant(tenantId))
      if (payment.status == LandlordPaymentStatus.rejected)
        LandlordAnnouncement(
          id: 'payment-rejected:${payment.id}',
          propertyId: rental.property.id,
          title: 'Thanh toán chưa được duyệt',
          content:
              'Khoản ${payment.id} cho hóa đơn ${payment.invoiceId} chưa được duyệt. Lý do: ${payment.rejectionReason ?? 'Chủ trọ chưa ghi lý do.'} Vui lòng kiểm tra và nộp lại.',
          category: AnnouncementCategory.finance,
          priority: AnnouncementPriority.high,
          createdAt: payment.reviewedAt ?? payment.paidAt,
          recipients: [tenantId],
          audienceLabel: 'Phòng ${payment.room}',
        ),
  ];
  bool isRead(String announcementId, String tenantId) =>
      _readByTenant[tenantId]?.contains(announcementId) ?? false;
  void markTenantRead(String announcementId, String tenantId) {
    final isPaymentRejection = announcementId.startsWith('payment-rejected:');
    final belongsToTenant = isPaymentRejection
        ? forTenant(tenantId).any((item) => item.id == announcementId)
        : (_recipients[announcementId]?.contains(tenantId) ?? false);
    if (!belongsToTenant) {
      throw ArgumentError('Thông báo không thuộc người thuê.');
    }
    _readByTenant.putIfAbsent(tenantId, () => {}).add(announcementId);
    notifyListeners();
  }

  void markLandlordRead(String id) {
    _landlordRead.add(id);
    notifyListeners();
  }

  void markAllLandlordRead() {
    _landlordRead.addAll(inbox.map((item) => item.id));
    notifyListeners();
  }

  List<LandlordAnnouncement> get inbox => [
    for (final payment in rental.payments)
      if (payment.status == LandlordPaymentStatus.pending)
        LandlordAnnouncement(
          id: 'payment:${payment.id}',
          propertyId: rental.property.id,
          title: 'Phòng ${payment.room} - Đã gửi thanh toán',
          content:
              '${payment.tenantName} báo trả ${payment.reportedAmount} đ. Tham chiếu: ${payment.reference}. Cần đối chiếu trước khi duyệt.',
          category: AnnouncementCategory.finance,
          priority: AnnouncementPriority.high,
          createdAt: payment.paidAt,
          isRead: _landlordRead.contains('payment:${payment.id}'),
        ),
    for (final incident in rental.incidents)
      if (incident.status == IncidentStatus.newly ||
          incident.status == IncidentStatus.inProgress)
        LandlordAnnouncement(
          id: 'incident:${incident.id}',
          propertyId: rental.property.id,
          title: 'Phòng ${incident.room} - ${incident.title}',
          content:
              '${incident.description}\nTrạng thái: ${incident.status.label}',
          category: AnnouncementCategory.incident,
          priority: incident.urgent
              ? AnnouncementPriority.urgent
              : AnnouncementPriority.high,
          createdAt: _date(incident.date),
          isRead: _landlordRead.contains('incident:${incident.id}'),
        ),
    for (final viewing in viewings.forProperty(rental.property.id))
      if (viewing.status == ViewingStatus.pending)
        LandlordAnnouncement(
          id: 'viewing:${viewing.id}',
          propertyId: rental.property.id,
          title: '${viewing.roomName} - Có lịch xem phòng mới',
          content:
              '${viewing.customerName} · ${viewing.phone}\n${viewing.personalNeeds}',
          category: AnnouncementCategory.viewing,
          createdAt: viewing.createdAt ?? viewing.startsAt,
          isRead: _landlordRead.contains('viewing:${viewing.id}'),
        ),
    for (final invoice in rental.payableInvoices)
      if (invoice.status == LandlordInvoiceStatus.overdue)
        LandlordAnnouncement(
          id: 'debt:${invoice.id}',
          propertyId: rental.property.id,
          title: 'Phòng ${invoice.room} - Hóa đơn quá hạn',
          content:
              '${invoice.id} còn ${invoice.remaining} đ, hạn ${landlordDate(invoice.dueDate)}.',
          category: AnnouncementCategory.finance,
          priority: AnnouncementPriority.high,
          createdAt: invoice.dueDate,
          isRead: _landlordRead.contains('debt:${invoice.id}'),
        ),
    for (final lease in rental.activeLeases)
      if (lease.isExpiringSoon)
        LandlordAnnouncement(
          id: 'lease:${lease.id}',
          propertyId: rental.property.id,
          title: 'Phòng ${lease.room} - Hợp đồng sắp hết hạn',
          content:
              '${lease.tenantName} · hết hạn ${landlordDate(lease.endDate)}.',
          category: AnnouncementCategory.lease,
          createdAt: lease.endDate,
          isRead: _landlordRead.contains('lease:${lease.id}'),
        ),
  ];
  DateTime _date(String value) {
    final parts = value.split('/').map(int.parse).toList();
    return DateTime(parts[2], parts[1], parts[0]);
  }
}
