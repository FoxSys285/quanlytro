part of 'landlord_demo_store.dart';

/// Keeps each property's operational data isolated while sharing the catalogue.
class RentalPortfolio extends ChangeNotifier {
  RentalPortfolio(Iterable<LandlordDemoStore> stores, {String? selectedId})
    : _stores = List.of(stores) {
    if (_stores.isEmpty) throw ArgumentError('Cần ít nhất một nhà trọ.');
    _selectedId = selectedId ?? _stores.first.property.id;
    if (!_stores.any((s) => s.property.id == _selectedId)) {
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
  LandlordDemoStore get active => byId(_selectedId)!;
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

  factory RentalPortfolio.fromMap(Map<String, dynamic> map) => RentalPortfolio(
    (map['properties'] as List).map(
      (item) =>
          LandlordDemoStore.demo()
            ..restore(Map<String, dynamic>.from(item as Map)),
    ),
    selectedId: map['selectedId'] as String,
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
    );
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
  if (index.isOdd) store._roomTypes.removeLast();
  store._rooms.clear();
  for (var floor = 1; floor <= floors; floor++) {
    for (var number = 1; number <= count; number++) {
      final raw = '$floor${number.toString().padLeft(2, '0')}';
      final code = index == 0 && raw == '105'
          ? 'B.105'
          : index == 0 && raw == '302'
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
          leaseRoomCode: index == 0 && raw == '101' ? 'A.101' : null,
        ),
      );
    }
  }
  if (index == 0) {
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
