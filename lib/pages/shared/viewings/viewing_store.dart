import 'package:flutter/foundation.dart';

import '../../../data/admin_store.dart';

import 'models/room_viewing.dart';
import '../rental/tenant_session.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/rooms/models/landlord_room.dart';

/// Demo session data. Replace with a database repository after authentication.
class ViewingStore extends ChangeNotifier {
  ViewingStore(List<RoomViewing> records, {this.rental})
    : _records = List.of(records);
  final LandlordDemoStore? rental;
  static const demoTenantId = TenantSession.tenantId;
  static ViewingStore instance = ViewingStore.demo(
    rental: LandlordDemoStore.instance,
  );

  factory ViewingStore.demo({
    DateTime? referenceDate,
    String propertyName = 'Mây House',
    String address = '25 Nguyễn Gia Trí, Bình Thạnh, TP. Hồ Chí Minh',
    LandlordDemoStore? rental,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    RoomViewing appointment(
      int index,
      int day,
      int hour,
      int minute,
      String name,
      String phone,
      String needs,
      ViewingStatus status, {
      bool mine = false,
    }) {
      final date = today.add(Duration(days: day));
      const rooms = ['101', '102', '201', '202'];
      return RoomViewing(
        id: 'viewing-demo-$index',
        tenantId: mine ? demoTenantId : 'tenant-$index',
        roomName: '$propertyName · Phòng ${rooms[index % rooms.length]}',
        address: address,
        startsAt: DateTime(date.year, date.month, date.day, hour, minute),
        customerName: name,
        phone: mine ? TenantSession.phone : phone,
        roomId: 'may:${rooms[index % rooms.length]}',
        createdAt: today.subtract(Duration(hours: index + 1)),
        personalNeeds: needs,
        status: status,
      );
    }

    return ViewingStore([
      appointment(
        0,
        2,
        14,
        30,
        'Trần Hoàng Nam',
        '0900000002',
        'Cần phòng có ban công, máy lạnh và bếp riêng. Ngân sách khoảng 4 triệu/tháng.',
        ViewingStatus.confirmed,
        mine: true,
      ),
      appointment(
        1,
        1,
        9,
        0,
        'Trần Hoàng Nam',
        '0900000002',
        'Hai sinh viên cần phòng có gác, chỗ để hai xe máy và giờ giấc tự do.',
        ViewingStatus.pending,
        mine: true,
      ),
      appointment(
        2,
        1,
        16,
        0,
        'Lê Thu Hà',
        '0900000003',
        'Làm việc tại nhà, cần không gian yên tĩnh, internet ổn định và nội thất sẵn.',
        ViewingStatus.confirmed,
      ),
      appointment(
        3,
        3,
        10,
        30,
        'Phạm Gia Bảo',
        '0900000004',
        'Tìm phòng có cửa sổ và máy lạnh. Cần hỏi thêm tiền cọc và thời hạn hợp đồng.',
        ViewingStatus.pending,
      ),
      appointment(
        4,
        2,
        8,
        30,
        'Võ Ngọc Linh',
        '0900000005',
        'Hai người thuê lâu dài, muốn có thang máy, ban công và bếp riêng.',
        ViewingStatus.confirmed,
      ),
      appointment(
        5,
        1,
        9,
        30,
        'Trần Hoàng Nam',
        '0900000002',
        'Muốn xem độ cao gác và hệ thống thông gió. Đã hủy vì thay đổi nhu cầu.',
        ViewingStatus.cancelled,
        mine: true,
      ),
    ], rental: rental);
  }

  final List<RoomViewing> _records;
  int _nextRequestId = 1;
  void seedPortfolio(RentalPortfolio portfolio) {
    _records.clear();
    final now = DateTime.now();
    for (var i = 0; i < portfolio.stores.length; i++) {
      final store = portfolio.stores[i];
      final rooms = store.roomDetails
          .where((r) => r.status == LandlordRoomStatus.vacant)
          .take(2)
          .toList();
      for (var j = 0; j < rooms.length; j++) {
        final mine = j == 0 && i.isEven;
        _records.add(
          RoomViewing(
            id: 'viewing-${store.property.id}-$j',
            propertyId: store.property.id,
            tenantId: mine ? demoTenantId : 'visitor-$i-$j',
            roomId: '${store.property.id}:${rooms[j].room.code}',
            roomName: '${store.property.name} · Phòng ${rooms[j].room.code}',
            address: store.property.address,
            startsAt: DateTime(now.year, now.month, now.day + j + 1, 9 + i % 8),
            customerName: mine
                ? TenantSession.name
                : ['Trần Hoàng Nam', 'Lê Thu Hà'][j],
            phone: mine ? TenantSession.phone : '090000000${j + 2}',
            personalNeeds: 'Muốn xem phòng thực tế, hỏi thêm về nội thất và chi phí dịch vụ.',
            status: j == 0 ? ViewingStatus.pending : ViewingStatus.confirmed,
            attendeeCount: 2,
            createdAt: now,
          ),
        );
      }
    }
  }

  Map<String, dynamic> toMap() => {
    'records': _records.map((r) => r.toMap()).toList(),
    'nextId': _nextRequestId,
  };
  void restore(Map<String, dynamic> map) {
    _records
      ..clear()
      ..addAll(
        (map['records'] as List).map(
          (r) => RoomViewing.fromMap(Map<String, dynamic>.from(r as Map)),
        ),
      );
    _nextRequestId = map['nextId'] as int;
  }

  List<RoomViewing> get records => List.unmodifiable(_records);
  List<RoomViewing> forProperty(String id) =>
      _ordered(_records.where((item) => item.propertyId == id));
  List<RoomViewing> forTenant(String id) =>
      _ordered(_records.where((item) => item.tenantId == id));
  List<RoomViewing> _ordered(Iterable<RoomViewing> records) =>
      records.toList()..sort((a, b) {
        final order = a.startsAt.compareTo(b.startsAt);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });

  RoomViewing createRequest({
    required String propertyId,
    required String tenantId,
    required String roomName,
    required String address,
    required DateTime startsAt,
    required String customerName,
    required String phone,
    required String personalNeeds,
    required int attendeeCount,
    String? roomId,
  }) {
    final cleanName = customerName.trim();
    if (!AdminStore.instance.acceptingViewings ||
        AdminStore.instance.isHidden(propertyId)) {
      throw ArgumentError(
        'Hiện chưa tiếp nhận lịch xem phòng này. Vui lòng thử lại sau.',
      );
    }
    if (propertyId.trim().isEmpty ||
        tenantId.trim().isEmpty ||
        roomName.trim().isEmpty) {
      throw ArgumentError('Thiếu mã người thuê, nhà trọ hoặc phòng.');
    }
    final target = rental?.property.id == propertyId
        ? rental
        : RentalPortfolio.instance.byId(propertyId);
    if (target != null && roomId != null) {
      final available = target.roomDetails.any(
        (details) =>
            '$propertyId:${details.room.code}' == roomId &&
            details.type != null &&
            details.status == LandlordRoomStatus.vacant,
      );
      if (!available) {
        throw ArgumentError('Phòng không còn trống hoặc không còn được đăng.');
      }
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanName.isEmpty || cleanPhone.length < 9 || cleanPhone.length > 12) {
      throw ArgumentError('Vui lòng nhập họ tên và số điện thoại hợp lệ.');
    }
    if (!startsAt.isAfter(DateTime.now())) {
      throw ArgumentError('Chọn thời gian xem phòng trong tương lai.');
    }
    if (attendeeCount < 1 || attendeeCount > 10) {
      throw ArgumentError('Số người đi xem phải từ 1 đến 10.');
    }
    if (_records.any(
      (record) =>
          record.propertyId == propertyId &&
          (roomId == null
              ? record.roomName == roomName
              : record.roomId == roomId) &&
          record.startsAt == startsAt &&
          record.status != ViewingStatus.cancelled,
    )) {
      throw ArgumentError(
        'Khung giờ này vừa được một người khác đặt. Hãy chọn giờ khác.',
      );
    }

    String id;
    do {
      id = 'viewing-request-${_nextRequestId++}';
    } while (_records.any((record) => record.id == id));

    final request = RoomViewing(
      id: id,
      propertyId: propertyId,
      tenantId: tenantId,
      roomName: roomName,
      address: address,
      startsAt: startsAt,
      customerName: cleanName,
      phone: cleanPhone,
      personalNeeds: personalNeeds.trim().isEmpty
          ? 'Chưa có ghi chú bổ sung.'
          : personalNeeds.trim(),
      status: ViewingStatus.pending,
      attendeeCount: attendeeCount,
      roomId: roomId,
      createdAt: DateTime.now(),
    );
    _records.add(request);
    notifyListeners();
    return request;
  }

  bool confirm(String id, {required String propertyId}) =>
      _update(id, propertyId, ViewingStatus.confirmed);
  bool cancel(String id, {required String propertyId}) =>
      _update(id, propertyId, ViewingStatus.cancelled);
  bool _update(String id, String propertyId, ViewingStatus status) {
    final index = _records.indexWhere(
      (item) => item.id == id && item.propertyId == propertyId,
    );
    if (index == -1) return false;
    final current = _records[index];
    if (current.status == ViewingStatus.cancelled ||
        current.status == status ||
        (status == ViewingStatus.confirmed &&
            current.status != ViewingStatus.pending)) {
      return false;
    }
    _records[index] = current.withStatus(status);
    notifyListeners();
    return true;
  }
}
