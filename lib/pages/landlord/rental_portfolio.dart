part of 'landlord_demo_store.dart';

/// Keeps each property's operational data isolated while sharing the catalogue.
class RentalPortfolio extends ChangeNotifier {
  RentalPortfolio(Iterable<LandlordDemoStore> stores, {String? selectedId})
    : _stores = List.of(stores) {
    _selectedId = _stores.isEmpty
        ? ''
        : selectedId ?? _stores.first.property.id;
    if (_stores.isNotEmpty &&
        !_stores.any((s) => s.property.id == _selectedId)) {
      _selectedId = _stores.first.property.id;
    }
    for (final store in _stores) {
      store.addListener(notifyListeners);
    }
  }

  static RentalPortfolio instance = RentalPortfolio([
    LandlordDemoStore.instance,
  ]);
  final List<LandlordDemoStore> _stores;
  late String _selectedId;
  List<LandlordDemoStore> get stores => List.unmodifiable(_stores);
  LandlordDemoStore get active =>
      byId(_selectedId) ??
      (_stores.isEmpty ? LandlordDemoStore.instance : _stores.first);
  LandlordDemoStore? byId(String id) {
    for (final store in _stores) {
      if (store.property.id == id) return store;
    }
    return null;
  }

  void select(String id) {
    if (byId(id) == null) throw ArgumentError('Nhà trọ không tồn tại.');
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  LandlordDemoStore add(
    LandlordProperty property, {
    required int floors,
    required int roomsPerFloor,
  }) {
    if (byId(property.id) != null) {
      throw ArgumentError('Mã nhà trọ đã tồn tại.');
    }
    if (floors < 1 || floors > 30 || roomsPerFloor < 1 || roomsPerFloor > 50) {
      throw ArgumentError('Số tầng hoặc số phòng mỗi tầng không hợp lệ.');
    }
    if (floors * roomsPerFloor > 350) {
      throw ArgumentError('Mỗi nhà trọ có thể tạo tối đa 350 phòng.');
    }
    final store = _seedProperty(
      property,
      floors,
      roomsPerFloor,
      _stores.length,
      occupied: false,
    );
    _stores.add(store);
    store.addListener(notifyListeners);
    _selectedId = property.id;
    notifyListeners();
    return store;
  }

  LandlordDemoStore createSingleProperty(LandlordProperty property) {
    if (_stores.isNotEmpty) {
      throw ArgumentError('Mỗi chủ trọ chỉ được quản lý một nhà trọ.');
    }
    if (property.id.trim().isEmpty) {
      throw ArgumentError('Không xác định được mã chủ trọ. Hãy đăng nhập lại.');
    }
    final store = LandlordDemoStore.emptyForProperty(property);
    _stores.add(store);
    store.addListener(notifyListeners);
    _selectedId = property.id;
    notifyListeners();
    return store;
  }

  void remove(String id) {
    final store = byId(id);
    if (store == null) throw ArgumentError('Nhà trọ không tồn tại.');
    if (_stores.length == 1) {
      throw ArgumentError('Cần giữ ít nhất một nhà trọ.');
    }
    if (id == 'may' || store.leases.isNotEmpty || store.invoices.isNotEmpty) {
      throw ArgumentError(
        'Nhà trọ đã có hợp đồng hoặc dữ liệu liên quan, không thể xóa.',
      );
    }
    store.removeListener(notifyListeners);
    _stores.remove(store);
    if (_selectedId == id) _selectedId = _stores.first.property.id;
    notifyListeners();
  }

  Map<String, dynamic> toMap() => {
    'selectedId': _selectedId,
    'properties': _stores.map((s) => s.toMap()).toList(),
  };

  /// Nhận bản mới từ server, giữ store và nhà đang mở để không mất màn hình.
  void restore(Map<String, dynamic> map) {
    final rows = (map['properties'] as List).cast<Map>();
    final ids = rows.map((row) => (row['property'] as Map)['id']).toSet();
    for (final store
        in _stores.where((s) => !ids.contains(s.property.id)).toList()) {
      store.removeListener(notifyListeners);
      _stores.remove(store);
    }
    for (final row in rows) {
      final data = Map<String, dynamic>.from(row);
      final id = (row['property'] as Map)['id'] as String;
      var store = byId(id);
      if (store == null) {
        store = LandlordDemoStore.demo();
        _stores.add(store);
        store.addListener(notifyListeners);
      }
      store.restore(data);
    }
    _selectedId = _stores.isEmpty
        ? ''
        : byId(_selectedId)?.property.id ?? _stores.first.property.id;
    for (final store in _stores) {
      store._changed();
    }
    notifyListeners();
  }

  factory RentalPortfolio.fromMap(Map<String, dynamic> map) => RentalPortfolio(
    (map['properties'] as List).map(
      (item) =>
          LandlordDemoStore.demo()
            ..restore(Map<String, dynamic>.from(item as Map)),
    ),
    selectedId: map['selectedId'] as String?,
  );

  factory RentalPortfolio.seeded() {
    const names = [
      'Mây House',
      'Nhà Nâu',
      'Ban Mai Residence',
      'Thanh Xuân House',
      'An Nhiên Home',
      'Gác Mộc',
      'Cỏ May Studio',
      'Bình Yên House',
      'Nhà Xinh Thảo Điền',
      'Tân Bình Home',
    ];
    const addresses = [
      '25 Nguyễn Gia Trí, Bình Thạnh',
      '18 Phan Xích Long, Phú Nhuận',
      '45 Nguyễn Văn Thương, Bình Thạnh',
      '103 Điện Biên Phủ, Bình Thạnh',
      '69 Ung Văn Khiêm, Bình Thạnh',
      '7 Xô Viết Nghệ Tĩnh, Bình Thạnh',
      '112 Chu Văn An, Bình Thạnh',
      '8 Nguyễn Xí, Bình Thạnh',
      '20 Quốc Hương, Thủ Đức',
      '15 Cộng Hòa, Tân Bình',
    ];
    const wards = [
      'Phường 25',
      'Phường 2',
      'Phường 25',
      'Phường 15',
      'Phường 25',
      'Phường 17',
      'Phường 26',
      'Phường 13',
      'Phường Thảo Điền',
      'Phường 4',
    ];
    const floors = [5, 3, 6, 4, 8, 3, 5, 4, 7, 6];
    const counts = [8, 6, 10, 8, 12, 7, 9, 6, 10, 8];
    return RentalPortfolio(
      List.generate(
        10,
        (i) => _seedProperty(
          LandlordProperty(
            id: i == 0 ? 'may' : 'property-${i + 1}',
            name: names[i],
            address: '${addresses[i]}, TP. Hồ Chí Minh',
            ownerName: 'Nguyễn Văn An',
            phone: '0900000000',
            ward: wards[i],
            description:
                '${names[i]} có ${floors[i]} tầng, mỗi tầng ${counts[i]} phòng. '
                'Phòng có cửa sổ, khu bếp và nhà vệ sinh riêng. Giờ giấc tự do, camera an ninh, '
                'wifi và khu để xe. Điện 4.000 đ/kWh, nước 15.000 đ/m³; internet 100.000 đ/phòng/tháng. '
                'Đặt cọc một tháng, hợp đồng 12 tháng. Liên hệ chủ trọ để xem phòng thực tế.',
          ),
          floors[i],
          counts[i],
          i,
        ),
      ),
    )..supplementDemoActivity();
  }

  /// Chỉ gọi khi tạo dữ liệu mẫu hoặc bổ sung mẫu theo yêu cầu, không khi mở app.
  void supplementDemoActivity() {
    const amenities = [
      ['Wifi', 'Máy lạnh', 'Thang máy', 'Bãi xe', 'Camera'],
      ['Wifi', 'Bếp riêng', 'Giờ giấc tự do', 'Bãi xe'],
      ['Wifi', 'Ban công', 'Máy lạnh', 'Thang máy'],
      ['Wifi', 'Gác lửng', 'Bãi xe', 'Camera'],
      ['Wifi', 'Thang máy', 'Máy giặt chung', 'Camera'],
      ['Wifi', 'Gác lửng', 'Bếp riêng', 'Giờ giấc tự do'],
      ['Wifi', 'Máy lạnh', 'Nội thất', 'Bãi xe'],
      ['Wifi', 'Cửa sổ', 'Bếp riêng', 'Camera'],
      ['Wifi', 'Ban công', 'Nội thất', 'Thang máy'],
      ['Wifi', 'Máy lạnh', 'Bãi xe', 'Máy giặt chung'],
    ];
    const descriptions = [
      'Không gian sáng gần HUTECH, phù hợp sinh viên và người mới đi làm.',
      'Ngõ yên tĩnh gần Phan Xích Long, có bếp riêng để tự nấu ăn.',
      'Phòng đón nắng sáng, ban công thoáng và thang máy tiện di chuyển.',
      'Phòng có gác tách khu ngủ, thuận tiện đi trung tâm bằng xe buýt.',
      'Tòa nhà có thang máy, sân phơi và máy giặt dùng chung.',
      'Nội thất tông gỗ, gác rộng và khu bếp gọn cho hai người.',
      'Studio có sẵn máy lạnh, bàn làm việc và tủ quần áo.',
      'Khu dân cư yên tĩnh, phòng có cửa sổ và bếp riêng.',
      'Căn hộ gần Quốc Hương, nội thất đầy đủ và ban công nhiều ánh sáng.',
      'Gần Cộng Hòa, thuận tiện đến sân bay và các văn phòng Tân Bình.',
    ];
    for (var index = 0; index < _stores.length; index++) {
      final store = _stores[index];
      final property = store.property;
      const oldNames = {
        'Trần Hoàng Nam',
        'Lê Thu Hà',
        'Phạm Gia Bảo',
        'Võ Ngọc Linh',
        'Nguyễn Minh Tâm',
        'Đặng Thùy Dương',
        'Hoàng Đức Huy',
        'Bùi Thanh Trúc',
        'Đỗ Tuấn Kiệt',
        'Phan Ngọc Mai',
        'Trương Anh Tú',
        'Lý Khánh Vy',
      };
      const families = [
        'Nguyễn',
        'Trần',
        'Lê',
        'Phạm',
        'Võ',
        'Đặng',
        'Bùi',
        'Đỗ',
        'Hoàng',
        'Phan',
      ];
      const middle = [
        'Minh',
        'Ngọc',
        'Thanh',
        'Gia',
        'Khánh',
        'Hoài',
        'Anh',
        'Bảo',
      ];
      const given = [
        'An',
        'Bình',
        'Châu',
        'Dương',
        'Giang',
        'Hà',
        'Hân',
        'Hiếu',
        'Huy',
        'Khang',
        'Khôi',
        'Lâm',
        'Linh',
        'Long',
        'Mai',
        'Nam',
        'Nhi',
        'Phúc',
        'Quân',
        'Trang',
      ];
      final renamed = <String, String>{};
      for (
        var leaseIndex = 0;
        leaseIndex < store._leases.length;
        leaseIndex++
      ) {
        final lease = store._leases[leaseIndex];
        if (!lease.id.startsWith('${property.id}-HD-') ||
            !oldNames.contains(lease.tenantName)) {
          continue;
        }
        final sequence = index * 100 + leaseIndex;
        lease.tenantName =
            '${families[(sequence ~/ 160) % families.length]} ${middle[(sequence ~/ 20) % middle.length]} ${given[sequence % given.length]}';
        renamed[lease.id] = lease.tenantName;
      }
      if (renamed.isNotEmpty) {
        for (var i = 0; i < store._invoices.length; i++) {
          final invoice = store._invoices[i];
          if (renamed.containsKey(invoice.leaseId)) {
            store._invoices[i] = LandlordInvoice.fromMap({
              ...invoice.toMap(),
              'tenantName': renamed[invoice.leaseId],
            });
          }
        }
        final invoiceNames = {
          for (final invoice in store._invoices) invoice.id: invoice.tenantName,
        };
        for (var i = 0; i < store._payments.length; i++) {
          final payment = store._payments[i];
          if (invoiceNames.containsKey(payment.invoiceId)) {
            store._payments[i] = LandlordPayment.fromMap({
              ...payment.toMap(),
              'tenantName': invoiceNames[payment.invoiceId],
            });
          }
        }
        for (var i = 0; i < store._incidents.length; i++) {
          final incident = store._incidents[i];
          if (renamed.containsKey(incident.leaseId)) {
            store._incidents[i] = LandlordIncident.fromMap({
              ...incident.toMap(),
              'reporter': renamed[incident.leaseId],
            });
          }
        }
      }
      final sampleImage =
          property.imageUrl.isEmpty ||
          property.imageUrl.startsWith('assets/images/room_types/') ||
          property.imageUrl.startsWith('assets/images/rental_api/');
      if (property.amenities.isEmpty ||
          (sampleImage && property.imageBytes == null)) {
        store._property = LandlordProperty.fromMap({
          ...property.toMap(),
          if (property.amenities.isEmpty) 'amenities': amenities[index % 10],
          if (sampleImage && property.imageBytes == null) ...{
            'imageUrl': RoomPhoto.propertyAsset(index),
            'imageName': 'Ảnh minh họa nội thất',
          },
          if (property.description.startsWith('${property.name} có '))
            'description':
                '${descriptions[index % 10]} '
                'Điện 4.000 đ/kWh, nước 15.000 đ/m³; internet 100.000 đ/tháng. '
                'Cọc một tháng. Ảnh minh họa, hãy đặt lịch để xem phòng thực tế.',
        });
      }
      for (var i = 0; i < store._roomTypes.length; i++) {
        final type = store._roomTypes[i];
        final samples = RoomPhoto.demoForPropertyType(type.id, index);
        // Album trống hoặc ảnh riêng là lựa chọn người dùng; chỉ mở rộng album mẫu.
        if (samples.isNotEmpty &&
            type.photos.isNotEmpty &&
            type.photos.every(
              (p) =>
                  p.bytes == null &&
                  p.isReference &&
                  (p.assetPath.startsWith('assets/images/room_types/') ||
                      p.assetPath.startsWith('assets/images/rental_api/')),
            )) {
          final basePrice = {
            'studio': 3000000,
            'balcony': 3500000,
            'loft': 2800000,
            'group': 5000000,
          }[type.id]!;
          store._roomTypes[i] = LandlordRoomType(
            id: type.id,
            name: type.name,
            monthlyRent: type.monthlyRent == basePrice
                ? basePrice + index * 150000
                : type.monthlyRent,
            photos: samples,
          );
        }
      }
      final now = DateTime.now();
      final expiringId = 'demo-expiring-${property.id}';
      final available = store.roomDetails.where(
        (r) => r.status == LandlordRoomStatus.vacant && r.type != null,
      );
      if (!store._leases.any((l) => l.id == expiringId) &&
          available.isNotEmpty &&
          store.activeLeases.isNotEmpty) {
        final details = available.last;
        final source = store.activeLeases.last;
        store._leases.add(
          LandlordLease.fromMap({
            ...source.toMap(),
            'id': expiringId,
            'tenantId': 'demo-expiring-tenant-${property.id}',
            'propertyId': property.id,
            'room': store.canonicalRoom(details.room.code),
            'tenantName': 'Đào Ngọc Hân',
            'phone': '0900000078',
            'startDate': DateTime(now.year, now.month - 3, 1).toIso8601String(),
            'endDate': now.add(const Duration(days: 21)).toIso8601String(),
            'monthlyRent': details.type!.monthlyRent,
            'deposit': details.type!.monthlyRent,
            'occupantCount': 1,
            'termMonths': 4,
            'note': 'Hợp đồng mẫu sắp hết hạn; liên hệ để gia hạn.',
          }),
        );
      }
      final leases = store.activeLeases;
      if (leases.isEmpty) continue;
      // Thêm hóa đơn riêng, không sửa số tiền hay trạng thái hóa đơn có sẵn.
      for (var i = 0; i < 3; i++) {
        final lease = leases.last;
        final invoiceId = 'demo-scenario-${property.id}-$i';
        if (store._invoices.any((v) => v.id == invoiceId)) continue;
        final total = lease.monthlyRent + 435000;
        final partial = i == 0 ? total ~/ 2 : 0;
        final invoice = LandlordInvoice(
          id: invoiceId,
          leaseId: lease.id,
          room: lease.room,
          tenantName: lease.tenantName,
          period: DateTime(now.year, now.month - i),
          dueDate: now.add(Duration(days: i == 1 ? -7 : 7)),
          charges: [
            LandlordInvoiceCharge(
              name: 'Tiền thuê phòng',
              amount: lease.monthlyRent,
            ),
            const LandlordInvoiceCharge(name: 'Điện · 70 kWh', amount: 280000),
            const LandlordInvoiceCharge(name: 'Nước · 3 m³', amount: 45000),
            const LandlordInvoiceCharge(
              name: 'Internet và vệ sinh',
              amount: 110000,
            ),
          ],
          paidAmount: partial,
        );
        store._invoices.add(invoice);
        store._payments.add(
          LandlordPayment(
            id: 'demo-scenario-payment-${property.id}-$i',
            invoiceId: invoice.id,
            tenantName: lease.tenantName,
            room: lease.room,
            reportedAmount: i == 0 ? partial : total,
            paidAt: now.subtract(Duration(days: i + 1)),
            method: 'Chuyển khoản',
            reference: 'DEMO-${property.id}-$i',
            status: LandlordPaymentStatus.values[[1, 2, 0][i]],
            approvedAmount: i == 0 ? partial : null,
            rejectionReason: i == 1
                ? 'Sai nội dung chuyển khoản, vui lòng kiểm tra lại. (Mẫu)'
                : null,
          )..reviewedAt = i == 2 ? null : now,
        );
      }
      const names = ['Nguyễn Khánh Vy', 'Lê Minh Quân', 'Phạm Thảo Nhi'];
      for (var i = 0; i < 3 && i < leases.length; i++) {
        final lease = leases[i];
        final id = 'demo-member-${property.id}-$i';
        final status = [
          LeaseMemberStatus.active,
          LeaseMemberStatus.pending,
          LeaseMemberStatus.rejected,
        ][i];
        final room = store.roomByCode(lease.room);
        if (!store._members.any((m) => m.id == id) &&
            room != null &&
            store.membersForLease(lease.id).length < room.capacity) {
          store._members.add(
            LeaseMember(
              id: id,
              leaseId: lease.id,
              tenantId: id,
              name: names[i],
              phone: '090000002${i + 1}',
              joinedAt: now,
              requestedBy: lease.tenantId,
              requestedAt: now.subtract(Duration(days: i + 1)),
              status: status,
              rejectionReason: i == 2 ? 'Cần bổ sung thông tin liên hệ.' : null,
            ),
          );
          if (status == LeaseMemberStatus.active) {
            lease.occupantCount = store.membersForLease(lease.id).length;
          }
        }
      }
      const titles = [
        'Vòi nước rò rỉ',
        'Máy lạnh cần vệ sinh',
        'Bóng đèn không sáng',
        'Wifi chập chờn',
      ];
      for (var i = 0; i < 4; i++) {
        final lease = leases[i % leases.length];
        final id = 'demo-incident-${property.id}-$i';
        if (store._incidents.any((item) => item.id == id)) continue;
        store._incidents.add(
          LandlordIncident(
            id: id,
            leaseId: lease.id,
            reporterId: lease.tenantId,
            title: titles[i],
            room: lease.room,
            reporter: lease.tenantName,
            category: ['Nước', 'Điện lạnh', 'Điện', 'Internet'][i],
            description:
                '${titles[i]}. Nhờ quản lý kiểm tra giúp vào giờ hành chính. (Dữ liệu mẫu)',
            date: landlordDate(now.subtract(Duration(days: i + 1))),
            status: IncidentStatus.values[i],
            urgent: i == 0,
          ),
        );
      }
      // Không thay đổi số tiền đã thu; khoản đã duyệt khớp hóa đơn có sẵn.
      final invoices = store.invoices.where((item) => !item.cancelled).take(8);
      for (final invoice in invoices) {
        if (store._payments.any((p) => p.invoiceId == invoice.id)) continue;
        final paid = invoice.paidAmount > 0;
        store._payments.add(
          LandlordPayment(
            id: 'demo-payment-${invoice.id}',
            invoiceId: invoice.id,
            tenantName: invoice.tenantName,
            room: invoice.room,
            reportedAmount: paid ? invoice.paidAmount : invoice.remaining,
            paidAt: now.subtract(const Duration(days: 1)),
            method: 'Chuyển khoản',
            reference: 'DEMO-${invoice.id}',
            status: paid
                ? LandlordPaymentStatus.approved
                : LandlordPaymentStatus.pending,
            approvedAmount: paid ? invoice.paidAmount : null,
          )..reviewedAt = paid ? now : null,
        );
      }
    }
  }

  @override
  void dispose() {
    for (final store in _stores) {
      store.removeListener(notifyListeners);
    }
    super.dispose();
  }
}

LandlordDemoStore _seedProperty(
  LandlordProperty property,
  int floors,
  int count,
  int index, {
  bool occupied = true,
}) {
  final store = LandlordDemoStore.demo();
  store._property = property;
  final preserveDemoData = property.id == 'may' && index == 0 && occupied;
  if (occupied && index.isOdd) store._roomTypes.removeLast();
  if (!occupied) {
    store._paymentAccounts.clear();
    for (var i = 0; i < store._roomTypes.length; i++) {
      final type = store._roomTypes[i];
      store._roomTypes[i] = LandlordRoomType(
        id: type.id,
        name: type.name,
        monthlyRent: type.monthlyRent,
        photos: const [],
      );
    }
  }
  store._rooms.clear();
  for (var floor = 1; floor <= floors; floor++) {
    for (var number = 1; number <= count; number++) {
      final raw = '$floor${number.toString().padLeft(2, '0')}';
      final code = preserveDemoData && raw == '105'
          ? 'B.105'
          : preserveDemoData && raw == '302'
          ? 'A.302'
          : raw;
      final typeIndex = (number - 1) % store._roomTypes.length;
      store._rooms.add(
        LandlordRoom(
          code: code,
          floor: floor,
          roomTypeId: store._roomTypes[typeIndex].id,
          area: [25, 28, 22, 40][typeIndex],
          capacity: [2, 4, 3, 5][typeIndex],
          leaseRoomCode: preserveDemoData && raw == '101' ? 'A.101' : null,
        ),
      );
    }
  }
  if (preserveDemoData) {
    // Preserve the linked demonstration tenant and the original room types.
    for (final original in LandlordDemoStore.roomCatalog) {
      final pos = store._rooms.indexWhere((r) => r.code == original.code);
      if (pos >= 0) store._rooms[pos] = original;
    }
  } else {
    store._leases.clear();
    store._invoices.clear();
    store._payments.clear();
    store._members.clear();
    store._incidents.clear();
    store._readings.clear();
    store._paymentAccounts.clear();
  }
  final now = DateTime.now();
  final period = DateTime(now.year, now.month);
  for (final lease in store._leases) {
    lease.startDate = DateTime(now.year, now.month - 3, 1);
    lease.endDate = DateTime(now.year + 1, now.month, 0);
  }
  const tenants = [
    'Trần Hoàng Nam',
    'Lê Thu Hà',
    'Phạm Gia Bảo',
    'Võ Ngọc Linh',
    'Nguyễn Minh Tâm',
    'Đặng Thùy Dương',
    'Hoàng Đức Huy',
    'Bùi Thanh Trúc',
    'Đỗ Tuấn Kiệt',
    'Phan Ngọc Mai',
    'Trương Anh Tú',
    'Lý Khánh Vy',
  ];
  if (occupied) {
    for (var i = 0; i < store._rooms.length; i++) {
      final room = store._rooms[i];
      if (i % 3 == 1 ||
          store._leases.any(
            (l) =>
                store.canonicalRoom(l.room) == store.canonicalRoom(room.code),
          )) {
        continue;
      }
      final type = store._roomTypes.firstWhere((t) => t.id == room.roomTypeId);
      final lease = LandlordLease(
        id: '${property.id}-HD-${room.code}',
        propertyId: property.id,
        tenantId: '${property.id}-tenant-${room.code}',
        room: store.canonicalRoom(room.code),
        tenantName: tenants[(i + index) % tenants.length],
        phone: '09${(10000000 + index * 10000 + i).toString()}',
        startDate: DateTime(now.year, now.month - 3, 1),
        endDate: DateTime(now.year + 1, now.month, 0),
        monthlyRent: type.monthlyRent,
        deposit: type.monthlyRent,
        termMonths: 12,
        dueDay: 10,
        landlordName: property.ownerName,
        landlordPermanentAddress: property.address,
        landlordCitizenId: '079000000001',
        landlordContact: property.phone,
        tenantBirthYear: '${1995 + i % 9}',
        tenantCitizenId: '079${(100000000 + index * 1000 + i).toString()}',
        tenantCitizenIssueDate: DateTime(2021, 6, 15),
        tenantPermanentAddress: 'TP. Hồ Chí Minh',
        electricityPrice: 4000,
        waterPrice: 15000,
        vehicleFee: 80000,
        serviceFee: 100000,
        cashPaymentLocation: 'Văn phòng ${property.name}',
        bankName: 'Vietcombank',
        bankAccountNumber: '0123456789',
      );
      store._leases.add(lease);
      final charges = [
        LandlordInvoiceCharge(
          name: 'Tiền thuê phòng',
          amount: lease.monthlyRent,
        ),
        const LandlordInvoiceCharge(name: 'Điện · 85 kWh', amount: 340000),
        const LandlordInvoiceCharge(name: 'Nước · 4 m³', amount: 60000),
        const LandlordInvoiceCharge(name: 'Internet và gửi xe', amount: 180000),
      ];
      final total = charges.fold<int>(0, (sum, c) => sum + c.amount);
      store._invoices.add(
        LandlordInvoice(
          id: '${lease.id}-${now.year}-${now.month}',
          leaseId: lease.id,
          room: lease.room,
          tenantName: lease.tenantName,
          period: period,
          dueDate: DateTime(now.year, now.month, 10),
          charges: charges,
          paidAmount: i.isEven ? total : 0,
        ),
      );
      store._readings.add(
        LandlordMeterReading(
          room: lease.room,
          period: period,
          oldElectric: 1000 + i * 20,
          newElectric: 1085 + i * 20,
          oldWater: 100 + i * 3,
          newWater: 104 + i * 3,
        ),
      );
    }
  }
  return store;
}

extension RentalStorePersistence on LandlordDemoStore {
  Map<String, dynamic> toMap() => {
    'property': _property.toMap(),
    'rooms': _rooms.map((r) => r.toMap()).toList(),
    'roomTypes': _roomTypes.map((r) => r.toMap()).toList(),
    'leases': _leases.map((r) => r.toMap()).toList(),
    'invoices': _invoices.map((r) => r.toMap()).toList(),
    'payments': _payments.map((r) => r.toMap()).toList(),
    'paymentAccounts': _paymentAccounts.map((r) => r.toMap()).toList(),
    'members': _members.map((r) => r.toMap()).toList(),
    'incidents': _incidents.map((r) => r.toMap()).toList(),
    'services': _services.map((r) => r.toMap()).toList(),
    'readings': _readings.map((r) => r.toMap()).toList(),
    'counters': [
      _nextLease,
      _nextInvoice,
      _nextPaymentAccount,
      _nextType,
      _nextPayment,
      _nextIncident,
      _nextService,
    ],
  };
  void restore(Map<String, dynamic> map) {
    List<T> read<T>(String key, T Function(Map<String, dynamic>) factory) =>
        (map[key] as List)
            .map((item) => factory(Map<String, dynamic>.from(item as Map)))
            .toList();
    _property = LandlordProperty.fromMap(
      Map<String, dynamic>.from(map['property'] as Map),
    );
    _rooms
      ..clear()
      ..addAll(read('rooms', LandlordRoom.fromMap));
    _roomTypes
      ..clear()
      ..addAll(read('roomTypes', LandlordRoomType.fromMap));
    _leases
      ..clear()
      ..addAll(read('leases', LandlordLease.fromMap));
    _invoices
      ..clear()
      ..addAll(read('invoices', LandlordInvoice.fromMap));
    _payments
      ..clear()
      ..addAll(read('payments', LandlordPayment.fromMap));
    _paymentAccounts
      ..clear()
      ..addAll(read('paymentAccounts', LandlordPaymentAccount.fromMap));
    _members
      ..clear()
      ..addAll(read('members', LeaseMember.fromMap));
    _incidents
      ..clear()
      ..addAll(read('incidents', LandlordIncident.fromMap));
    _services
      ..clear()
      ..addAll(read('services', LandlordService.fromMap));
    _readings
      ..clear()
      ..addAll(read('readings', LandlordMeterReading.fromMap));
    final counters = List<int>.from(map['counters'] as List);
    _nextLease = counters[0];
    _nextInvoice = counters[1];
    _nextPaymentAccount = counters[2];
    _nextType = counters[3];
    _nextPayment = counters[4];
    _nextIncident = counters[5];
    _nextService = counters[6];
  }

  void saveRoom(LandlordRoom room, {String? existingCode}) {
    if (room.code.trim().isEmpty ||
        room.floor < 1 ||
        room.floor > 30 ||
        room.area < 6 ||
        room.area > 500 ||
        room.capacity < 1 ||
        room.capacity > 20 ||
        !_roomTypes.any((t) => t.id == room.roomTypeId)) {
      throw ArgumentError(
        'Kiểm tra mã phòng, tầng (1–30), diện tích (6–500 m²), sức chứa (1–20) và loại phòng.',
      );
    }
    final index = existingCode == null
        ? -1
        : _rooms.indexWhere((r) => r.code == existingCode);
    if (existingCode != null && index == -1) {
      throw ArgumentError('Phòng không tồn tại.');
    }
    final duplicate = _rooms.any(
      (r) =>
          r.code != existingCode &&
          canonicalRoom(r.code) == canonicalRoom(room.code),
    );
    if (duplicate) throw ArgumentError('Mã phòng đã tồn tại trong nhà trọ.');
    if (index >= 0) {
      final prior = _rooms[index];
      if (room.code != prior.code &&
          _leases.any(
            (l) => canonicalRoom(l.room) == canonicalRoom(prior.code),
          )) {
        throw ArgumentError(
          'Phòng đã có hợp đồng; vui lòng giữ nguyên mã phòng.',
        );
      }
      final count = _leases.where(
        (l) =>
            canonicalRoom(l.room) == canonicalRoom(prior.code) &&
            (l.isCurrent || l.isUpcoming),
      );
      if (count.any((l) => l.occupantCount > room.capacity)) {
        throw ArgumentError('Sức chứa nhỏ hơn số người đang ở.');
      }
      _rooms[index] = room;
    } else {
      _rooms.add(room);
    }
    _rooms.sort(
      (a, b) => a.floor == b.floor
          ? a.code.compareTo(b.code)
          : a.floor.compareTo(b.floor),
    );
    _changed();
  }

  void deleteRoom(String code) {
    if (_leases.any((l) => canonicalRoom(l.room) == canonicalRoom(code))) {
      throw ArgumentError('Phòng đã có hợp đồng; không thể xóa lịch sử.');
    }
    _rooms.removeWhere((r) => r.code == code);
    _changed();
  }

  void prepareReadings(DateTime period) {
    var changed = false;
    for (final details in roomDetails.where(
      (d) => d.status == LandlordRoomStatus.occupied,
    )) {
      final code = canonicalRoom(details.room.code);
      if (readingForRoom(code, period) != null) continue;
      final previous =
          _readings
              .where(
                (r) =>
                    canonicalRoom(r.room) == code && r.period.isBefore(period),
              )
              .toList()
            ..sort((a, b) => b.period.compareTo(a.period));
      final prior = previous.isEmpty ? null : previous.first;
      _readings.add(
        LandlordMeterReading(
          room: code,
          period: DateTime(period.year, period.month),
          oldElectric: prior?.newElectric ?? prior?.oldElectric ?? 0,
          oldWater: prior?.newWater ?? prior?.oldWater ?? 0,
        ),
      );
      changed = true;
    }
    if (changed) _changed();
  }
}
