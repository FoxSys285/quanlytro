import 'package:flutter/foundation.dart';

import 'properties/models/landlord_property.dart';
import 'room_types/models/landlord_room_type.dart';
import '../shared/media/room_photo.dart';
import 'rooms/models/landlord_room.dart';
import 'finance/landlord_finance_models.dart';
import '../shared/rental/lease_member.dart';
import '../shared/rental/tenant_session.dart';
import '../shared/rental/rental_record_id.dart';
import 'incidents/models/landlord_suco.dart';
import 'services/models/landlord_dichvu.dart';
import 'meter_readings/models/landlord_chisodiennuoc.dart';
import 'leases/models/landlord_lease_template.dart';

part 'rental_portfolio.dart';

/// Shared rental data for both roles in the preview session.
/// The historical name is retained for existing landlord screens.
class LandlordDemoStore extends ChangeNotifier {
  LandlordDemoStore.demo();
  factory LandlordDemoStore.empty() {
    final store = LandlordDemoStore.demo();
    final data = store.toMap()
      ..['property'] = const LandlordProperty(
        id: '',
        name: '',
        address: '',
        ownerName: '',
        phone: '',
        description: '',
        city: '',
        ward: '',
      ).toMap()
      ..['rooms'] = <dynamic>[]
      ..['roomTypes'] = <dynamic>[]
      ..['leases'] = <dynamic>[]
      ..['leaseTemplates'] = <dynamic>[]
      ..['invoices'] = <dynamic>[]
      ..['payments'] = <dynamic>[]
      ..['paymentAccounts'] = <dynamic>[]
      ..['members'] = <dynamic>[]
      ..['incidents'] = <dynamic>[]
      ..['services'] = <dynamic>[]
      ..['readings'] = <dynamic>[]
      ..['counters'] = List<int>.filled(7, 1);
    store.restore(data);
    return store;
  }

  static LandlordDemoStore emptyForProperty(LandlordProperty property) {
    final store = LandlordDemoStore.empty();
    store._property = property;
    return store;
  }

  void _changed() => notifyListeners();
  static LandlordDemoStore instance = LandlordDemoStore.demo();
  static LandlordDemoStore get activeInstance =>
      RentalPortfolio.instance.active;
  final _rooms = <LandlordRoom>[...roomCatalog];
  List<LandlordRoom> get catalog => List.unmodifiable(_rooms);
  Map<String, int> get roomFloors =>
      Map.unmodifiable({for (final room in _rooms) room.code: room.floor});

  LandlordProperty _property = const LandlordProperty(
    id: 'may',
    name: 'Mây House',
    address: '25 Nguyễn Gia Trí, Bình Thạnh, TP. Hồ Chí Minh',
    ownerName: 'Nguyễn Văn An',
    phone: '0900000000',
    description:
        'Nhà trọ có không gian thoáng, giờ giấc tự do và chỗ để xe. '
        'Liên hệ chủ trọ để biết thêm thông tin phòng và nội quy.',
  );
  LandlordProperty get property => _property;

  static const roomCatalog = [
    LandlordRoom(
      code: '101',
      floor: 1,
      roomTypeId: 'studio',
      area: 25,
      capacity: 2,
      leaseRoomCode: 'A.101',
    ),
    LandlordRoom(
      code: '102',
      floor: 1,
      roomTypeId: 'balcony',
      area: 28,
      capacity: 2,
    ),
    LandlordRoom(
      code: 'B.105',
      floor: 1,
      roomTypeId: 'studio',
      area: 25,
      capacity: 2,
    ),
    LandlordRoom(
      code: '201',
      floor: 2,
      roomTypeId: 'loft',
      area: 22,
      capacity: 3,
    ),
    LandlordRoom(
      code: '202',
      floor: 2,
      roomTypeId: 'group',
      area: 40,
      capacity: 5,
    ),
    LandlordRoom(
      code: 'A.302',
      floor: 3,
      roomTypeId: 'balcony',
      area: 28,
      capacity: 4,
    ),
  ];
  static final Map<String, int> rooms = Map.unmodifiable({
    for (final room in roomCatalog) room.code: room.floor,
  });

  List<LandlordRoomDetails> get roomDetails => List.unmodifiable(
    _rooms.map((room) {
      LandlordRoomType? type;
      for (final item in _roomTypes) {
        if (item.id == room.roomTypeId) {
          type = item;
          break;
        }
      }
      final leases =
          _leases
              .where(
                (lease) =>
                    lease.room.trim().toLowerCase() ==
                        (room.leaseRoomCode ?? room.code).toLowerCase() &&
                    (lease.isCurrent || lease.isUpcoming),
              )
              .toList()
            ..sort((a, b) {
              if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
              return a.startDate.compareTo(b.startDate);
            });
      return LandlordRoomDetails(
        room: room,
        type: type,
        lease: leases.isEmpty ? null : leases.first,
      );
    }),
  );

  final _leases = <LandlordLease>[
    LandlordLease(
      id: 'HD-2026-0101',
      tenantId: 'tenant-khoa',
      room: 'A.101',
      tenantName: 'Lê Văn Khoa',
      phone: '0987 654 321',
      startDate: DateTime(2026, 5, 15),
      endDate: DateTime(2027, 5, 14),
      monthlyRent: 3000000,
      deposit: 3000000,
      termMonths: 12,
      dueDay: 10,
      landlordName: 'Nguyễn Văn An',
      landlordPermanentAddress:
          '25 Nguyễn Gia Trí, Bình Thạnh, TP. Hồ Chí Minh',
      landlordCitizenId: '000000000000',
      landlordContact: '0900000000',
      tenantBirthYear: '1998',
      tenantCitizenId: '000000000001',
      tenantCitizenIssueDate: DateTime(2020, 5, 12),
      tenantPermanentAddress: 'Phường 25, Bình Thạnh, TP. Hồ Chí Minh',
      electricityPrice: 3500,
      waterPrice: 15000,
      waterType: 'Theo m³',
      vehicleFee: 80000,
      serviceFee: 100000,
      cashPaymentLocation: 'Tại nhà trọ Mây House',
      bankName: 'Vietcombank',
      bankAccountNumber: '0123456789',
      occupantCount: 1,
      note: 'Đã nhận đủ tiền đặt cọc.',
    ),
    LandlordLease(
      id: 'HD-2026-0302',
      tenantId: TenantSession.tenantId,
      room: 'A.302',
      tenantName: 'Minh Anh',
      phone: '0901 234 567',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2027, 2, 28),
      monthlyRent: 3500000,
      deposit: 3500000,
      termMonths: 12,
      dueDay: 10,
      landlordName: 'Nguyễn Văn An',
      landlordPermanentAddress:
          '25 Nguyễn Gia Trí, Bình Thạnh, TP. Hồ Chí Minh',
      landlordCitizenId: '000000000000',
      landlordContact: '0900000000',
      tenantBirthYear: '1996',
      tenantCitizenId: '000000000002',
      tenantCitizenIssueDate: DateTime(2019, 8, 20),
      tenantPermanentAddress: 'Thủ Đức, TP. Hồ Chí Minh',
      electricityPrice: 3500,
      waterPrice: 15000,
      waterType: 'Theo m³',
      vehicleFee: 80000,
      serviceFee: 100000,
      cashPaymentLocation: 'Tại nhà trọ Mây House',
      bankName: 'Vietcombank',
      bankAccountNumber: '0123456789',
      occupantCount: 2,
      note: 'Người đại diện phòng.',
    ),
    LandlordLease(
      id: 'HD-2026-0105',
      tenantId: 'tenant-bao',
      room: 'B.105',
      tenantName: 'Phạm Quốc Bảo',
      phone: '0933 222 444',
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 11, 15),
      monthlyRent: 3000000,
      deposit: 3000000,
      termMonths: 3,
      dueDay: 5,
      landlordName: 'Nguyễn Văn An',
      landlordPermanentAddress:
          '25 Nguyễn Gia Trí, Bình Thạnh, TP. Hồ Chí Minh',
      landlordCitizenId: '000000000000',
      landlordContact: '0900000000',
      tenantBirthYear: '1997',
      tenantCitizenId: '000000000003',
      tenantCitizenIssueDate: DateTime(2021, 2, 15),
      tenantPermanentAddress: 'Bình Chánh, TP. Hồ Chí Minh',
      electricityPrice: 3500,
      waterPrice: 15000,
      waterType: 'Theo m³',
      vehicleFee: 80000,
      serviceFee: 100000,
      cashPaymentLocation: 'Tại nhà trọ Mây House',
      bankName: 'Vietcombank',
      bankAccountNumber: '0123456789',
      occupantCount: 1,
      note: '',
    ),
  ];
  int _nextLease = 1;
  List<LandlordLease> get leases => List.unmodifiable(_leases);
  final _leaseTemplates = <LandlordLeaseTemplate>[];
  List<LandlordLeaseTemplate> get leaseTemplates =>
      List.unmodifiable(_leaseTemplates);

  LandlordLeaseTemplate? leaseTemplateById(String id) {
    for (final template in _leaseTemplates) {
      if (template.id == id) return template;
    }
    return null;
  }

  void saveLeaseTemplate({
    LandlordLeaseTemplate? existing,
    required String name,
    required String landlordName,
    required String landlordPermanentAddress,
    required String landlordCitizenId,
    required String landlordContact,
    required DateTime? landlordBirthDate,
    required DateTime? landlordCitizenIssueDate,
    required String landlordCitizenIssuePlace,
    required int electricityPrice,
    required int waterPrice,
    required String waterType,
    String? electricityServiceId,
    String? waterServiceId,
    required bool cashPaymentEnabled,
    required String cashPaymentLocation,
    required bool bankTransferEnabled,
    required String bankName,
    required String bankAccountNumber,
    required String responsibilityA,
    required String responsibilityB,
    required String commonResponsibilities,
  }) {
    if (existing != null && !_leaseTemplates.contains(existing)) {
      throw ArgumentError('Mẫu hợp đồng không tồn tại.');
    }
    final bankDigits = bankAccountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final ownerPhoneDigits = landlordContact.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.trim().isEmpty ||
        landlordName.trim().isEmpty ||
        landlordPermanentAddress.trim().isEmpty ||
        !RegExp(r'^(\d{9}|\d{12})$').hasMatch(landlordCitizenId.trim()) ||
        ownerPhoneDigits.length < 9 ||
        ownerPhoneDigits.length > 12) {
      throw ArgumentError('Nhập tên mẫu và đầy đủ thông tin bên A.');
    }
    if (electricityPrice <= 0 || waterPrice < 0) {
      throw ArgumentError('Kiểm tra đơn giá điện và nước.');
    }
    if (!cashPaymentEnabled && !bankTransferEnabled) {
      throw ArgumentError('Chọn ít nhất một phương thức thanh toán.');
    }
    if (cashPaymentEnabled && cashPaymentLocation.trim().isEmpty) {
      throw ArgumentError('Nhập địa điểm nhận tiền mặt.');
    }
    if (bankTransferEnabled &&
        (bankName.trim().isEmpty ||
            bankDigits.length < 6 ||
            bankDigits.length > 20)) {
      throw ArgumentError('Nhập tên ngân hàng và số tài khoản hợp lệ.');
    }
    final template = LandlordLeaseTemplate(
      id: existing?.id ?? rentalRecordId('lease-template'),
      name: name.trim(),
      landlordName: landlordName.trim(),
      landlordPermanentAddress: landlordPermanentAddress.trim(),
      landlordCitizenId: landlordCitizenId.trim(),
      landlordContact: landlordContact.trim(),
      landlordBirthDate: landlordBirthDate,
      landlordCitizenIssueDate: landlordCitizenIssueDate,
      landlordCitizenIssuePlace: landlordCitizenIssuePlace.trim(),
      electricityPrice: electricityPrice,
      waterPrice: waterPrice,
      waterType: waterType,
      electricityServiceId:
          electricityServiceId ??
          existing?.electricityServiceId ??
          'electricity',
      waterServiceId: waterServiceId ?? existing?.waterServiceId ?? 'water',
      cashPaymentEnabled: cashPaymentEnabled,
      cashPaymentLocation: cashPaymentLocation.trim(),
      bankTransferEnabled: bankTransferEnabled,
      bankName: bankName.trim(),
      bankAccountNumber: bankDigits,
      responsibilityA: responsibilityA.trim(),
      responsibilityB: responsibilityB.trim(),
      commonResponsibilities: commonResponsibilities.trim(),
    );
    if (existing == null) {
      _leaseTemplates.insert(0, template);
    } else {
      _leaseTemplates[_leaseTemplates.indexOf(existing)] = template;
    }
    notifyListeners();
  }

  void deleteLeaseTemplate(LandlordLeaseTemplate template) {
    _leaseTemplates.remove(template);
    notifyListeners();
  }

  List<LandlordLease> get activeLeases =>
      List.unmodifiable(_leases.where((lease) => lease.isCurrent));

  final _invoices = <LandlordInvoice>[
    LandlordInvoice(
      id: 'HD-2026-10-0302',
      leaseId: 'HD-2026-0302',
      room: 'A.302',
      tenantName: 'Minh Anh',
      period: DateTime(2026, 10),
      dueDate: DateTime(2026, 10, 10),
      charges: const [
        LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: 3500000),
        LandlordInvoiceCharge(name: 'Điện · 126 kWh', amount: 441000),
        LandlordInvoiceCharge(name: 'Nước · 7 m³', amount: 105000),
        LandlordInvoiceCharge(name: 'Internet', amount: 100000),
        LandlordInvoiceCharge(name: 'Gửi xe', amount: 80000),
        LandlordInvoiceCharge(name: 'Vệ sinh', amount: 40000),
        LandlordInvoiceCharge(name: 'Công nợ kỳ trước', amount: 404000),
      ],
    ),
    LandlordInvoice(
      id: 'HD-2026-10-0105',
      leaseId: 'HD-2026-0105',
      room: 'B.105',
      tenantName: 'Phạm Quốc Bảo',
      period: DateTime(2026, 10),
      dueDate: DateTime(2026, 10, 5),
      charges: const [
        LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: 3000000),
        LandlordInvoiceCharge(name: 'Điện nước và dịch vụ', amount: 420000),
      ],
    ),
    LandlordInvoice(
      id: 'HD-2026-09-0101',
      leaseId: 'HD-2026-0101',
      room: 'A.101',
      tenantName: 'Lê Văn Khoa',
      period: DateTime(2026, 9),
      dueDate: DateTime(2026, 9, 10),
      charges: const [
        LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: 3000000),
        LandlordInvoiceCharge(name: 'Điện nước và dịch vụ', amount: 800000),
      ],
      paidAmount: 3800000,
    ),
  ];
  int _nextInvoice = 1;
  List<LandlordInvoice> get invoices => List.unmodifiable(_invoices);
  List<LandlordInvoice> get payableInvoices => List.unmodifiable(
    _invoices.where(
      (invoice) =>
          invoice.status != LandlordInvoiceStatus.cancelled &&
          invoice.status != LandlordInvoiceStatus.paid,
    ),
  );

  final _payments = <LandlordPayment>[
    LandlordPayment(
      id: 'TT-2026-10061',
      invoiceId: 'HD-2026-10-0302',
      tenantName: 'Minh Anh',
      room: 'A.302',
      reportedAmount: 4670000,
      paidAt: DateTime(2026, 10, 6, 9, 42),
      method: 'Chuyển khoản',
      reference: 'MBVCB.061024.0942.MA',
    ),
    LandlordPayment(
      id: 'TT-2026-10058',
      invoiceId: 'HD-2026-10-0105',
      tenantName: 'Phạm Quốc Bảo',
      room: 'B.105',
      reportedAmount: 1500000,
      paidAt: DateTime(2026, 10, 5, 19, 12),
      method: 'Chuyển khoản',
      reference: 'VCB.051026.1912.BAO',
    ),
  ];
  int _nextPaymentAccount = 1;
  List<LandlordPayment> get payments => List.unmodifiable(_payments);
  final _paymentAccounts = <LandlordPaymentAccount>[
    LandlordPaymentAccount(
      id: 'bank-vcb',
      bankName: 'Vietcombank',
      accountName: 'NGUYEN VAN AN',
      accountNumber: '0123456789',
      branch: 'Chi nhánh Bình Thạnh',
      isDefault: true,
    ),
    LandlordPaymentAccount(
      id: 'bank-mb',
      bankName: 'MB Bank',
      accountName: 'NGUYEN VAN AN',
      accountNumber: '6688990011',
      branch: 'Tài khoản dự phòng',
      isDefault: false,
      isActive: false,
      isVerified: false,
    ),
  ];
  List<LandlordPaymentAccount> get paymentAccounts =>
      List.unmodifiable(_paymentAccounts);
  LandlordPaymentAccount? get defaultPaymentAccount {
    for (final account in _paymentAccounts) {
      if (account.isDefault && account.isActive) return account;
    }
    return null;
  }

  LandlordLease? leaseById(String id) {
    for (final lease in _leases) {
      if (lease.id == id) return lease;
    }
    return null;
  }

  LandlordInvoice? invoiceById(String id) {
    for (final invoice in _invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  }

  void saveLease({
    LandlordLease? existing,
    required String room,
    required String landlordName,
    required String landlordPermanentAddress,
    required String landlordCitizenId,
    required String landlordContact,
    required String tenantName,
    required String tenantBirthYear,
    required String tenantCitizenId,
    required DateTime? tenantCitizenIssueDate,
    required String tenantPermanentAddress,
    required String phone,
    required DateTime startDate,
    required DateTime endDate,
    required int monthlyRent,
    required int deposit,
    required int termMonths,
    required int electricityPrice,
    required int waterPrice,
    required String waterType,
    String? electricityServiceId,
    String? waterServiceId,
    required int vehicleFee,
    required int serviceFee,
    String? serviceId,
    String? serviceName,
    String? serviceUnit,
    String? serviceBasis,
    List<LandlordLeaseService>? services,
    required int dueDay,
    required bool cashPaymentEnabled,
    required String cashPaymentLocation,
    required bool bankTransferEnabled,
    required String bankName,
    required String bankAccountNumber,
    required int occupantCount,
    required String note,
    required LandlordLeaseStatus status,
    String? tenantId,
    DateTime? landlordBirthDate,
    DateTime? landlordCitizenIssueDate,
    String landlordCitizenIssuePlace = '',
    DateTime? tenantBirthDate,
    String tenantCitizenIssuePlace = '',
    String responsibilityA = '',
    String responsibilityB = '',
    String commonResponsibilities = '',
    String templateId = '',
    String rentalAddress = '',
  }) {
    if (existing != null && !_leases.contains(existing)) {
      throw ArgumentError('Hợp đồng không tồn tại.');
    }
    if (tenantId != null && !RegExp(r'^[^\s/:]+$').hasMatch(tenantId)) {
      throw ArgumentError('Mã người thuê không hợp lệ.');
    }
    final requiredFields = [
      room,
      landlordName,
      landlordPermanentAddress,
      landlordCitizenId,
      landlordContact,
      tenantName,
      tenantBirthYear,
      tenantCitizenId,
      tenantPermanentAddress,
      phone,
    ];
    if (requiredFields.any((value) => value.trim().isEmpty) ||
        tenantCitizenIssueDate == null) {
      throw ArgumentError('Vui lòng điền đầy đủ thông tin hai bên hợp đồng.');
    }
    final birthYear = int.tryParse(tenantBirthYear.trim());
    final validId = RegExp(r'^(\d{9}|\d{12})$');
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final ownerPhoneDigits = landlordContact.replaceAll(RegExp(r'[^0-9]'), '');
    final bankDigits = bankAccountNumber.replaceAll(RegExp(r'\s+'), '');
    if (birthYear == null ||
        birthYear < 1900 ||
        birthYear > DateTime.now().year) {
      throw ArgumentError('Năm sinh bên B không hợp lệ.');
    }
    if (!validId.hasMatch(landlordCitizenId.trim()) ||
        !validId.hasMatch(tenantCitizenId.trim())) {
      throw ArgumentError('CCCD phải gồm 9 hoặc 12 chữ số.');
    }
    if (phoneDigits.length < 9 ||
        phoneDigits.length > 12 ||
        ownerPhoneDigits.length < 9 ||
        ownerPhoneDigits.length > 12) {
      throw ArgumentError('Kiểm tra số điện thoại/Zalo của hai bên.');
    }
    if (monthlyRent <= 0 ||
        deposit < 0 ||
        termMonths < 1 ||
        termMonths > 120 ||
        electricityPrice <= 0 ||
        waterPrice < 0 ||
        vehicleFee < 0 ||
        serviceFee < 0 ||
        dueDay < 1 ||
        dueDay > 31 ||
        occupantCount < 1) {
      throw ArgumentError(
        'Kiểm tra giá phòng, các khoản phí, ngày đóng tiền và số người ở.',
      );
    }
    if (!cashPaymentEnabled && !bankTransferEnabled) {
      throw ArgumentError('Chọn ít nhất một phương thức thanh toán.');
    }
    if (cashPaymentEnabled && cashPaymentLocation.trim().isEmpty) {
      throw ArgumentError('Nhập nơi nhận tiền mặt.');
    }
    if (bankTransferEnabled &&
        (bankName.trim().isEmpty ||
            !RegExp(r'^\d{6,20}$').hasMatch(bankDigits))) {
      throw ArgumentError('Nhập ngân hàng và số tài khoản hợp lệ.');
    }
    if (!endDate.isAfter(startDate)) {
      throw ArgumentError('Ngày kết thúc phải sau ngày bắt đầu.');
    }
    final occupied = _leases.any(
      (lease) =>
          lease.id != existing?.id &&
          lease.status == LandlordLeaseStatus.active &&
          canonicalRoom(lease.room) == canonicalRoom(room) &&
          !endDate.isBefore(lease.startDate) &&
          !startDate.isAfter(lease.endDate),
    );
    if (occupied && status == LandlordLeaseStatus.active) {
      throw ArgumentError('Phòng này đã có hợp đồng đang hiệu lực.');
    }
    final targetRoom = roomByCode(room);
    if (targetRoom == null) throw ArgumentError('Phòng không tồn tại.');
    if (occupantCount > targetRoom.capacity) {
      throw ArgumentError('Số người vượt sức chứa của phòng.');
    }
    if (existing != null &&
        occupantCount < membersForLease(existing.id).length) {
      throw ArgumentError(
        'Số người ở không thể nhỏ hơn số thành viên đã được duyệt.',
      );
    }
    if (existing == null) {
      String? knownTenantId = tenantId;
      for (final prior in {
        ..._leases,
        for (final store in RentalPortfolio.instance.stores) ...store.leases,
      }) {
        if (prior.tenantCitizenId == tenantCitizenId.trim()) {
          if (knownTenantId != null && knownTenantId != prior.tenantId) {
            throw ArgumentError('CCCD đã liên kết với mã người thuê khác.');
          }
          knownTenantId ??= prior.tenantId;
        }
      }
      String leaseId;
      do {
        leaseId =
            'HD-${DateTime.now().year}-${(_nextLease++).toString().padLeft(4, '0')}';
      } while (leaseById(leaseId) != null);
      _leases.add(
        LandlordLease(
          id: leaseId,
          propertyId: property.id,
          tenantId: knownTenantId ?? 'tenant-$leaseId',
          room: canonicalRoom(room),
          landlordName: landlordName.trim(),
          landlordPermanentAddress: landlordPermanentAddress.trim(),
          landlordCitizenId: landlordCitizenId.trim(),
          landlordContact: landlordContact.trim(),
          landlordBirthDate: landlordBirthDate,
          landlordCitizenIssueDate: landlordCitizenIssueDate,
          landlordCitizenIssuePlace: landlordCitizenIssuePlace.trim(),
          tenantName: tenantName.trim(),
          tenantBirthYear: tenantBirthYear.trim(),
          tenantBirthDate: tenantBirthDate,
          tenantCitizenId: tenantCitizenId.trim(),
          tenantCitizenIssueDate: tenantCitizenIssueDate,
          tenantCitizenIssuePlace: tenantCitizenIssuePlace.trim(),
          tenantPermanentAddress: tenantPermanentAddress.trim(),
          phone: phone.trim(),
          startDate: startDate,
          endDate: endDate,
          monthlyRent: monthlyRent,
          deposit: deposit,
          termMonths: termMonths,
          electricityPrice: electricityPrice,
          waterPrice: waterPrice,
          waterType: waterType,
          electricityServiceId: electricityServiceId ?? 'electricity',
          waterServiceId: waterServiceId ?? 'water',
          vehicleFee: vehicleFee,
          serviceFee: serviceFee,
          serviceId: serviceId ?? '',
          serviceName: serviceName ?? '',
          serviceUnit: serviceUnit ?? '',
          serviceBasis: serviceBasis ?? '',
          services: List.unmodifiable(services ?? const []),
          dueDay: dueDay,
          cashPaymentEnabled: cashPaymentEnabled,
          cashPaymentLocation: cashPaymentLocation.trim(),
          bankTransferEnabled: bankTransferEnabled,
          bankName: bankName.trim(),
          bankAccountNumber: bankDigits,
          occupantCount: occupantCount,
          note: note.trim(),
          responsibilityA: responsibilityA.trim(),
          responsibilityB: responsibilityB.trim(),
          commonResponsibilities: commonResponsibilities.trim(),
          templateId: templateId,
          rentalAddress: rentalAddress.trim(),
          status: status,
        ),
      );
    } else {
      existing
        ..room = canonicalRoom(room)
        ..landlordName = landlordName.trim()
        ..landlordPermanentAddress = landlordPermanentAddress.trim()
        ..landlordCitizenId = landlordCitizenId.trim()
        ..landlordContact = landlordContact.trim()
        ..landlordBirthDate = landlordBirthDate
        ..landlordCitizenIssueDate = landlordCitizenIssueDate
        ..landlordCitizenIssuePlace = landlordCitizenIssuePlace.trim()
        ..tenantName = tenantName.trim()
        ..tenantBirthYear = tenantBirthYear.trim()
        ..tenantBirthDate = tenantBirthDate
        ..tenantCitizenId = tenantCitizenId.trim()
        ..tenantCitizenIssueDate = tenantCitizenIssueDate
        ..tenantCitizenIssuePlace = tenantCitizenIssuePlace.trim()
        ..tenantPermanentAddress = tenantPermanentAddress.trim()
        ..phone = phone.trim()
        ..startDate = startDate
        ..endDate = endDate
        ..monthlyRent = monthlyRent
        ..deposit = deposit
        ..termMonths = termMonths
        ..electricityPrice = electricityPrice
        ..waterPrice = waterPrice
        ..waterType = waterType
        ..electricityServiceId =
            electricityServiceId ?? existing.electricityServiceId
        ..waterServiceId = waterServiceId ?? existing.waterServiceId
        ..vehicleFee = vehicleFee
        ..serviceFee = serviceFee
        ..serviceId = serviceId ?? existing.serviceId
        ..serviceName = serviceName ?? existing.serviceName
        ..serviceUnit = serviceUnit ?? existing.serviceUnit
        ..serviceBasis = serviceBasis ?? existing.serviceBasis
        ..services = List.unmodifiable(services ?? existing.services)
        ..dueDay = dueDay
        ..cashPaymentEnabled = cashPaymentEnabled
        ..cashPaymentLocation = cashPaymentLocation.trim()
        ..bankTransferEnabled = bankTransferEnabled
        ..bankName = bankName.trim()
        ..bankAccountNumber = bankDigits
        ..occupantCount = occupantCount
        ..note = note.trim()
        ..responsibilityA = responsibilityA.trim()
        ..responsibilityB = responsibilityB.trim()
        ..commonResponsibilities = commonResponsibilities.trim()
        ..templateId = templateId
        ..rentalAddress = rentalAddress.trim()
        ..status = status;
    }
    notifyListeners();
  }

  void endLease(LandlordLease lease, {String reason = ''}) {
    if (!_leases.contains(lease)) {
      throw ArgumentError('Hợp đồng không tồn tại.');
    }
    lease
      ..status = LandlordLeaseStatus.terminated
      ..terminationReason = reason.trim().isEmpty
          ? 'Chủ trọ cập nhật chấm dứt hợp đồng.'
          : reason.trim()
      ..terminatedAt = DateTime.now();
    notifyListeners();
  }

  void requestLeaseTermination({
    required String tenantId,
    required String leaseId,
    required String reason,
  }) {
    final lease = leaseById(leaseId);
    if (lease == null ||
        !lease.isCurrent ||
        lease.tenantId != tenantId ||
        !leasesForTenant(tenantId).any((item) => item.id == leaseId)) {
      throw ArgumentError(
        'Chỉ người đại diện có thể gửi yêu cầu kết thúc hợp đồng.',
      );
    }
    if (reason.trim().length < 5) {
      throw ArgumentError('Nhập lý do kết thúc hợp đồng (ít nhất 5 ký tự).');
    }
    if (lease.terminationRequestStatus == 'pending') {
      throw ArgumentError('Yêu cầu kết thúc hợp đồng đang chờ chủ trọ xử lý.');
    }
    lease
      ..terminationRequestStatus = 'pending'
      ..terminationRequestedAt = DateTime.now()
      ..terminationRequestedBy = tenantId
      ..terminationRequestReason = reason.trim()
      ..terminationRejectionReason = ''
      ..terminationReviewedAt = null;
    notifyListeners();
  }

  void reviewLeaseTermination(
    LandlordLease lease, {
    required bool approve,
    String reason = '',
  }) {
    if (!_leases.contains(lease) ||
        lease.terminationRequestStatus != 'pending') {
      throw ArgumentError('Yêu cầu kết thúc hợp đồng không còn chờ xử lý.');
    }
    if (!approve && reason.trim().length < 5) {
      throw ArgumentError('Nhập lý do từ chối (ít nhất 5 ký tự).');
    }
    lease
      ..terminationRequestStatus = approve ? 'approved' : 'rejected'
      ..terminationReviewedAt = DateTime.now()
      ..terminationRejectionReason = approve ? '' : reason.trim();
    if (approve) {
      endLease(lease, reason: lease.terminationRequestReason);
    } else {
      notifyListeners();
    }
  }

  void requestLeaseRenewal({
    required String tenantId,
    required String leaseId,
    required DateTime proposedEndDate,
    String reason = '',
  }) {
    final lease = leaseById(leaseId);
    if (lease == null ||
        !lease.isCurrent ||
        !leasesForTenant(tenantId).any((item) => item.id == leaseId)) {
      throw ArgumentError('Hợp đồng không còn hiệu lực hoặc không thuộc bạn.');
    }
    final now = DateTime.now();
    final endDay = DateTime(
      lease.endDate.year,
      lease.endDate.month,
      lease.endDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (endDay.difference(today).inDays > 31) {
      throw ArgumentError('Có thể đề nghị gia hạn trong vòng một tháng cuối.');
    }
    if (lease.renewalStatus == 'pending') {
      throw ArgumentError('Yêu cầu gia hạn đang chờ chủ trọ xử lý.');
    }
    final requestedEnd = DateTime(
      proposedEndDate.year,
      proposedEndDate.month,
      proposedEndDate.day,
    );
    if (!requestedEnd.isAfter(endDay)) {
      throw ArgumentError('Ngày kết thúc mới phải sau thời hạn hiện tại.');
    }
    lease
      ..renewalStatus = 'pending'
      ..renewalRequestedAt = now
      ..renewalRequestedBy = tenantId
      ..renewalProposedEndDate = requestedEnd
      ..renewalReason = reason.trim()
      ..renewalRejectionReason = ''
      ..renewalReviewedAt = null;
    notifyListeners();
  }

  void reviewLeaseRenewal(
    LandlordLease lease, {
    required bool approve,
    String reason = '',
  }) {
    if (!_leases.contains(lease) || lease.renewalStatus != 'pending') {
      throw ArgumentError('Yêu cầu gia hạn không còn chờ xử lý.');
    }
    if (!approve && reason.trim().isEmpty) {
      throw ArgumentError('Nhập lý do từ chối gia hạn.');
    }
    if (approve) {
      final newEnd = lease.renewalProposedEndDate;
      if (newEnd == null || !newEnd.isAfter(lease.endDate)) {
        throw ArgumentError('Ngày gia hạn không hợp lệ.');
      }
      final months =
          (newEnd.year - lease.endDate.year) * 12 +
          newEnd.month -
          lease.endDate.month;
      lease
        ..endDate = newEnd
        ..termMonths += months > 0 ? months : 1
        ..renewalStatus = 'approved'
        ..renewalRejectionReason = '';
    } else {
      lease
        ..renewalStatus = 'rejected'
        ..renewalRejectionReason = reason.trim();
    }
    lease.renewalReviewedAt = DateTime.now();
    notifyListeners();
  }

  LandlordInvoice createInvoice({
    required LandlordLease lease,
    required DateTime period,
    required DateTime dueDate,
    required List<LandlordInvoiceCharge> charges,
  }) {
    if (!lease.isCurrent) {
      throw ArgumentError('Chỉ lập hóa đơn cho hợp đồng đang hiệu lực.');
    }
    if (!identical(leaseById(lease.id), lease)) {
      throw ArgumentError('Hợp đồng không tồn tại.');
    }
    final periodStart = DateTime(period.year, period.month);
    final periodEnd = DateTime(period.year, period.month + 1, 0, 23, 59, 59);
    if (periodEnd.isBefore(lease.startDate) ||
        periodStart.isAfter(lease.endDate)) {
      throw ArgumentError('Kỳ hóa đơn nằm ngoài thời hạn hợp đồng.');
    }
    final alreadyExists = _invoices.any(
      (invoice) =>
          invoice.leaseId == lease.id &&
          invoice.period.year == period.year &&
          invoice.period.month == period.month &&
          !invoice.cancelled,
    );
    if (alreadyExists) {
      throw ArgumentError('Hợp đồng này đã có hóa đơn cho kỳ đã chọn.');
    }
    if (charges.isEmpty ||
        charges.any(
          (charge) => charge.amount < 0 || charge.name.trim().isEmpty,
        ) ||
        charges.fold<int>(0, (sum, charge) => sum + charge.amount) <= 0) {
      throw ArgumentError('Hóa đơn cần có ít nhất một khoản thu hợp lệ.');
    }
    String invoiceId;
    do {
      invoiceId =
          'HD-${period.year}-${period.month.toString().padLeft(2, '0')}-${(_nextInvoice++).toString().padLeft(4, '0')}';
    } while (invoiceById(invoiceId) != null);
    final invoice = LandlordInvoice(
      id: invoiceId,
      leaseId: lease.id,
      room: lease.room,
      tenantName: lease.tenantName,
      period: DateTime(period.year, period.month),
      dueDate: dueDate,
      charges: List.unmodifiable(charges),
    );
    _invoices.insert(0, invoice);
    notifyListeners();
    return invoice;
  }

  void cancelInvoice(LandlordInvoice invoice) {
    if (!_invoices.contains(invoice)) {
      throw ArgumentError('Hóa đơn không tồn tại.');
    }
    if (invoice.paidAmount > 0) {
      throw ArgumentError('Hóa đơn đã có thanh toán nên không thể hủy.');
    }
    if (_payments.any(
      (payment) =>
          payment.invoiceId == invoice.id &&
          payment.status == LandlordPaymentStatus.pending,
    )) {
      throw ArgumentError('Hóa đơn còn khoản thanh toán đang chờ duyệt.');
    }
    invoice.cancelled = true;
    notifyListeners();
  }

  void approvePayment(LandlordPayment payment, int amount) {
    if (!_payments.contains(payment)) {
      throw ArgumentError('Thanh toán không tồn tại.');
    }
    if (payment.status != LandlordPaymentStatus.pending) {
      throw ArgumentError('Khoản thanh toán này đã được xử lý.');
    }
    final invoice = invoiceById(payment.invoiceId);
    if (invoice == null || invoice.cancelled) {
      throw ArgumentError('Không tìm thấy hóa đơn còn hiệu lực.');
    }
    if (amount <= 0 ||
        amount > payment.reportedAmount ||
        amount > invoice.remaining) {
      throw ArgumentError(
        'Số tiền xác nhận vượt số đã báo hoặc dư nợ hóa đơn.',
      );
    }
    payment
      ..approvedAmount = amount
      ..reviewedAt = DateTime.now()
      ..status = LandlordPaymentStatus.approved;
    invoice.paidAmount += amount;
    notifyListeners();
  }

  void rejectPayment(LandlordPayment payment, String reason) {
    if (!_payments.contains(payment)) {
      throw ArgumentError('Thanh toán không tồn tại.');
    }
    if (payment.status != LandlordPaymentStatus.pending) {
      throw ArgumentError('Khoản thanh toán này đã được xử lý.');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('Hãy nhập lý do từ chối để người thuê biết.');
    }
    payment
      ..status = LandlordPaymentStatus.rejected
      ..reviewedAt = DateTime.now()
      ..rejectionReason = reason.trim();
    notifyListeners();
  }

  void savePaymentAccount({
    LandlordPaymentAccount? existing,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String branch,
    required bool makeDefault,
  }) {
    final digits = accountNumber.replaceAll(RegExp(r'\s+'), '');
    if (bankName.trim().isEmpty ||
        accountName.trim().isEmpty ||
        !RegExp(r'^\d{6,20}$').hasMatch(digits)) {
      throw ArgumentError(
        'Vui lòng kiểm tra ngân hàng, chủ tài khoản và số tài khoản.',
      );
    }
    if (existing == null) {
      final shouldBeDefault = makeDefault || defaultPaymentAccount == null;
      if (shouldBeDefault) {
        for (final account in _paymentAccounts) {
          account.isDefault = false;
        }
      }
      _paymentAccounts.add(
        LandlordPaymentAccount(
          id: 'bank-${_nextPaymentAccount++}',
          bankName: bankName.trim(),
          accountName: accountName.trim().toUpperCase(),
          accountNumber: digits,
          branch: branch.trim(),
          isDefault: shouldBeDefault,
          isVerified: false,
        ),
      );
    } else {
      final wasDefault = existing.isDefault;
      final anotherActive = _paymentAccounts.where(
        (item) => item.id != existing.id && item.isActive,
      );
      if (makeDefault) {
        for (final account in _paymentAccounts) {
          account.isDefault = false;
        }
      }
      existing
        ..bankName = bankName.trim()
        ..accountName = accountName.trim().toUpperCase()
        ..accountNumber = digits
        ..branch = branch.trim()
        ..isActive = makeDefault || existing.isActive
        ..isDefault = makeDefault || (wasDefault && anotherActive.isEmpty);
      if (!makeDefault && wasDefault && anotherActive.isNotEmpty) {
        anotherActive.first.isDefault = true;
      }
    }
    notifyListeners();
  }

  void setDefaultPaymentAccount(LandlordPaymentAccount account) {
    if (!account.isActive) {
      throw ArgumentError('Hãy bật tài khoản trước khi chọn làm mặc định.');
    }
    for (final item in _paymentAccounts) {
      item.isDefault = item.id == account.id;
    }
    notifyListeners();
  }

  void setPaymentAccountActive(LandlordPaymentAccount account, bool active) {
    if (!active && account.isDefault) {
      final anotherActive = _paymentAccounts.any(
        (item) => item.id != account.id && item.isActive,
      );
      if (!anotherActive) {
        throw ArgumentError(
          'Cần bật một tài khoản khác trước khi ngừng tài khoản mặc định.',
        );
      }
      account.isDefault = false;
      final replacement = _paymentAccounts.firstWhere(
        (item) => item.id != account.id && item.isActive,
      );
      replacement.isDefault = true;
    }
    account.isActive = active;
    if (active && defaultPaymentAccount == null) {
      for (final item in _paymentAccounts) {
        item.isDefault = false;
      }
      account.isDefault = true;
    }
    notifyListeners();
  }

  final _roomTypes = [
    const LandlordRoomType(
      id: 'studio',
      name: 'Studio',
      monthlyRent: 3000000,
      serviceIds: const ['electricity', 'water'],
      servicePrices: const {'electricity': 4000, 'water': 15000},
      photos: [RoomPhoto.studio],
    ),
    const LandlordRoomType(
      id: 'balcony',
      name: 'Phòng có ban công',
      monthlyRent: 3500000,
      serviceIds: const ['electricity', 'water'],
      servicePrices: const {'electricity': 4000, 'water': 15000},
      photos: [RoomPhoto.balcony],
    ),
    const LandlordRoomType(
      id: 'loft',
      name: 'Phòng có gác',
      monthlyRent: 2800000,
      serviceIds: const ['electricity', 'water'],
      servicePrices: const {'electricity': 4000, 'water': 15000},
      photos: [RoomPhoto.loft],
    ),
    const LandlordRoomType(
      id: 'group',
      name: 'Phòng lớn cho 5 người',
      monthlyRent: 5000000,
      serviceIds: const ['electricity', 'water'],
      servicePrices: const {'electricity': 4000, 'water': 15000},
      photos: [RoomPhoto.group],
    ),
  ];
  int _nextType = 1;
  List<LandlordRoomType> get roomTypes => List.unmodifiable(_roomTypes);

  void updateProperty(LandlordProperty property) {
    if (property.id != _property.id) {
      throw ArgumentError('Nhà trọ không hợp lệ.');
    }
    _property = property;
    notifyListeners();
  }

  bool nameExists(String name, {String? excludingId}) => _roomTypes.any(
    (type) =>
        type.id != excludingId &&
        type.name.toLowerCase() == name.trim().toLowerCase(),
  );

  void saveRoomType(
    String name, {
    required int monthlyRent,
    String? id,
    List<String>? serviceIds,
    Map<String, int>? servicePrices,
    List<RoomPhoto>? photos,
    List<RoomTypeImage>? images,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || nameExists(trimmed, excludingId: id)) {
      throw ArgumentError('Tên loại phòng trống hoặc trùng.');
    }
    if (monthlyRent <= 0) throw ArgumentError('Giá thuê phải lớn hơn 0.');
    if (serviceIds != null &&
        serviceIds.any((serviceId) => serviceRecordById(serviceId) == null)) {
      throw ArgumentError('Có dịch vụ được chọn không còn tồn tại.');
    }
    if (servicePrices != null &&
        servicePrices.entries.any(
          (entry) =>
              entry.value < 0 ||
              (serviceIds != null && !serviceIds.contains(entry.key)),
        )) {
      throw ArgumentError('Kiểm tra đơn giá dịch vụ của loại phòng.');
    }
    if (photos != null &&
        (photos.length > 12 || photos.any((photo) => !photo.hasSource))) {
      throw ArgumentError('Chọn tối đa 12 ảnh hợp lệ cho mỗi loại phòng.');
    }
    if (id == null) {
      final selected = (serviceIds ?? const ['electricity', 'water']).toSet();
      _roomTypes.add(
        LandlordRoomType(
          id: 'custom-${_nextType++}',
          name: trimmed,
          monthlyRent: monthlyRent,
          serviceIds: List.unmodifiable(selected),
          servicePrices: Map.unmodifiable({
            for (final serviceId in selected)
              serviceId:
                  servicePrices?[serviceId] ??
                  serviceRecordById(serviceId)?.price ??
                  0,
          }),
          photos: List.unmodifiable(photos ?? images ?? const <RoomPhoto>[]),
        ),
      );
    } else {
      final index = _roomTypes.indexWhere((type) => type.id == id);
      if (index == -1) throw ArgumentError('Loại phòng không tồn tại.');
      final selected = (serviceIds ?? _roomTypes[index].serviceIds).toSet();
      final previousPrices = _roomTypes[index].servicePrices;
      _roomTypes[index] = LandlordRoomType(
        id: id,
        name: trimmed,
        monthlyRent: monthlyRent,
        serviceIds: List.unmodifiable(selected),
        servicePrices: Map.unmodifiable({
          for (final serviceId in selected)
            serviceId:
                servicePrices?[serviceId] ??
                previousPrices[serviceId] ??
                serviceRecordById(serviceId)?.price ??
                0,
        }),
        photos: List.unmodifiable(photos ?? images ?? _roomTypes[index].photos),
      );
    }
    notifyListeners();
  }

  void deleteRoomType(String id) {
    if (_rooms.any((room) => room.roomTypeId == id)) {
      throw ArgumentError(
        'Loại phòng đang được sử dụng. Hãy chuyển các phòng sang loại khác trước khi xóa.',
      );
    }
    _roomTypes.removeWhere((type) => type.id == id);
    notifyListeners();
  }

  String canonicalRoom(String code) {
    final clean = code.trim().toUpperCase();
    for (final room in _rooms) {
      if (room.code.toUpperCase() == clean ||
          room.leaseRoomCode?.toUpperCase() == clean) {
        return room.leaseRoomCode ?? room.code;
      }
    }
    return clean;
  }

  LandlordRoom? roomByCode(String code) {
    for (final room in _rooms) {
      if (canonicalRoom(room.code) == canonicalRoom(code)) return room;
    }
    return null;
  }

  LandlordRoomType? roomTypeForRoom(String code) {
    final room = roomByCode(code);
    if (room == null) return null;
    for (final type in _roomTypes) {
      if (type.id == room.roomTypeId) return type;
    }
    return null;
  }

  LandlordService? serviceRecordById(String id) {
    for (final service in _services) {
      if (service.id == id) return service;
    }
    return null;
  }

  List<LandlordLease> leasesForTenant(String tenantId) => List.unmodifiable(
    _leases.where(
      (lease) =>
          lease.status != LandlordLeaseStatus.draft &&
          (lease.tenantId == tenantId ||
              membersForLease(lease.id)
                  .any((member) => member.tenantId == tenantId)),
    ),
  );

  LandlordLease? currentLeaseForTenant(String tenantId) {
    for (final lease in leasesForTenant(tenantId)) {
      if (lease.isCurrent) return lease;
    }
    return null;
  }

  void updateTenantContact(
    String tenantId, {
    required String name,
    required String phone,
  }) {
    for (final lease in _leases.where((item) => item.tenantId == tenantId)) {
      lease.tenantName = name;
      lease.phone = phone;
    }
    for (final member in _members.where((item) => item.tenantId == tenantId)) {
      member.name = name;
      member.phone = phone;
    }
    notifyListeners();
  }

  List<LandlordInvoice> invoicesForTenant(String tenantId) {
    final ids = leasesForTenant(tenantId).map((lease) => lease.id).toSet();
    return List.unmodifiable(
      _invoices.where((invoice) => ids.contains(invoice.leaseId)),
    );
  }

  List<LandlordPayment> paymentsForTenant(String tenantId) {
    final ids = invoicesForTenant(tenantId)
        .map((invoice) => invoice.id)
        .toSet();
    return List.unmodifiable(
      _payments.where((payment) => ids.contains(payment.invoiceId)),
    );
  }

  int _nextPayment = 1;
  LandlordPayment submitPayment({
    required String tenantId,
    required String invoiceId,
    required int amount,
    required String reference,
    required String method,
    List<int>? proofBytes,
    String? proofName,
  }) {
    final invoice = invoiceById(invoiceId);
    if (invoice == null ||
        !invoicesForTenant(tenantId).contains(invoice) ||
        invoice.cancelled ||
        invoice.remaining == 0) {
      throw ArgumentError(
        'Hóa đơn không thuộc người thuê hoặc không còn phải trả.',
      );
    }
    final lease = leaseById(invoice.leaseId)!;
    if ((method == 'Chuyển khoản' && !lease.bankTransferEnabled) ||
        (method == 'Tiền mặt' && !lease.cashPaymentEnabled) ||
        !['Chuyển khoản', 'Tiền mặt'].contains(method)) {
      throw ArgumentError(
        'Phương thức thanh toán không được phép trong hợp đồng.',
      );
    }
    if (method == 'Chuyển khoản' && defaultPaymentAccount == null) {
      throw ArgumentError(
        'Chủ trọ chưa có tài khoản nhận tiền đang hoạt động.',
      );
    }
    if (amount <= 0 || amount > invoice.remaining || reference.trim().isEmpty) {
      throw ArgumentError('Nhập số tiền hợp lệ và tham chiếu giao dịch.');
    }
    if (_payments.any(
      (payment) =>
          payment.invoiceId == invoiceId &&
          payment.status == LandlordPaymentStatus.pending,
    )) {
      throw ArgumentError('Hóa đơn đã có thanh toán đang chờ chủ trọ duyệt.');
    }
    final payment = LandlordPayment(
      id: rentalRecordId('TT-GUI'),
      invoiceId: invoiceId,
      tenantName: invoice.tenantName,
      room: invoice.room,
      reportedAmount: amount,
      paidAt: DateTime.now(),
      method: method,
      reference: reference.trim(),
      proofBytes: proofBytes == null ? null : List.unmodifiable(proofBytes),
      proofName: proofName,
      paymentAccountId: method == 'Chuyển khoản'
          ? defaultPaymentAccount?.id
          : null,
    );
    _payments.insert(0, payment);
    notifyListeners();
    return payment;
  }

  final _members = <LeaseMember>[
    LeaseMember(
      id: 'member-ha',
      leaseId: 'HD-2026-0302',
      tenantId: 'tenant-ha',
      name: 'Trần Thu Hà',
      phone: '0912 888 111',
      joinedAt: DateTime(2026, 3, 1),
    ),
    LeaseMember(
      id: 'member-lan',
      leaseId: 'HD-2026-0105',
      tenantId: 'tenant-lan',
      name: 'Võ Ngọc Lan',
      phone: '0977 111 999',
      joinedAt: DateTime(2026, 10, 15),
      requestedBy: 'tenant-bao',
      requestedAt: DateTime(2026, 10, 14),
      status: LeaseMemberStatus.pending,
    ),
  ];

  List<LeaseMember> get members => List.unmodifiable([
    for (final lease in _leases)
      LeaseMember(
        id: 'representative-${lease.id}',
        leaseId: lease.id,
        tenantId: lease.tenantId,
        name: lease.tenantName,
        phone: lease.phone,
        joinedAt: lease.startDate,
        isRepresentative: true,
      ),
    ..._members,
  ]);

  List<LeaseMember> membersForLease(String leaseId) => members
      .where(
        (member) =>
            member.leaseId == leaseId &&
            member.status == LeaseMemberStatus.active,
      )
      .toList();

  LeaseMember requestMember({
    required String tenantId,
    required String name,
    required String phone,
    String? memberTenantId,
    DateTime? joinedAt,
  }) {
    final lease = currentLeaseForTenant(tenantId);
    if (lease == null || lease.tenantId != tenantId) {
      throw ArgumentError(
        'Chỉ người đại diện phòng đang thuê được đề nghị thêm thành viên.',
      );
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final linkedTenantId = memberTenantId?.trim().toUpperCase();
    if (linkedTenantId != null &&
        linkedTenantId.isNotEmpty &&
        !RegExp(r'^[A-Z0-9]{8}$').hasMatch(linkedTenantId)) {
      throw ArgumentError('Mã người thuê phải gồm đúng 8 chữ cái hoặc chữ số.');
    }
    if (name.trim().isEmpty || !RegExp(r'^0\d{9}$').hasMatch(digits)) {
      throw ArgumentError('Nhập họ tên và số điện thoại hợp lệ (10 chữ số).');
    }
    final now = DateTime.now();
    final requestedDate = joinedAt ?? now;
    final date = DateTime(
      requestedDate.year,
      requestedDate.month,
      requestedDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today) ||
        date.isBefore(
          DateTime(
            lease.startDate.year,
            lease.startDate.month,
            lease.startDate.day,
          ),
        ) ||
        date.isAfter(
          DateTime(lease.endDate.year, lease.endDate.month, lease.endDate.day),
        )) {
      throw ArgumentError(
        'Ngày vào ở phải từ hôm nay và trong thời hạn hợp đồng.',
      );
    }
    final reserved = members
        .where(
          (member) =>
              member.leaseId == lease.id &&
              ![
                LeaseMemberStatus.rejected,
                LeaseMemberStatus.left,
              ].contains(member.status),
        )
        .toList();
    if (reserved.any(
      (member) =>
          member.phone.replaceAll(RegExp(r'[^0-9]'), '') == digits ||
          (linkedTenantId != null &&
              linkedTenantId.isNotEmpty &&
              member.tenantId.toUpperCase() == linkedTenantId),
    )) {
      throw ArgumentError(
        'Số điện thoại đã có trong phòng hoặc đang chờ duyệt.',
      );
    }
    if (reserved.length >= (roomByCode(lease.room)?.capacity ?? 0)) {
      throw ArgumentError(
        'Phòng đã đủ sức chứa, bao gồm yêu cầu đang chờ duyệt.',
      );
    }
    final id = rentalRecordId('member-request');
    final member = LeaseMember(
      id: id,
      leaseId: lease.id,
      tenantId: linkedTenantId?.isNotEmpty == true
          ? linkedTenantId!
          : 'tenant-$id',
      name: name.trim(),
      phone: digits,
      joinedAt: date,
      requestedBy: tenantId,
      requestedAt: DateTime.now(),
      status: LeaseMemberStatus.pending,
    );
    _members.insert(0, member);
    notifyListeners();
    return member;
  }

  void updateMemberIdentityDocuments(
    String tenantId, {
    String? identityFrontPath,
    String? identityBackPath,
    String? portraitPath,
  }) {
    final member = _members
        .where(
          (item) =>
              item.tenantId == tenantId &&
              item.status == LeaseMemberStatus.active,
        )
        .firstOrNull;
    if (member == null) {
      throw ArgumentError('Không tìm thấy thành viên đang ở.');
    }
    final prefix =
        'lease-member-identity/${Uri.encodeComponent(_property.id)}/${Uri.encodeComponent(tenantId)}/${Uri.encodeComponent(member.id)}/';
    for (final path in [identityFrontPath, identityBackPath, portraitPath]) {
      if (path != null && !path.startsWith(prefix)) {
        throw ArgumentError('Đường dẫn hồ sơ định danh không hợp lệ.');
      }
    }
    if (identityFrontPath != null) member.identityFrontPath = identityFrontPath;
    if (identityBackPath != null) member.identityBackPath = identityBackPath;
    if (portraitPath != null) member.portraitPath = portraitPath;
    notifyListeners();
  }

  LeaseMember requestMemberLeave({
    required String tenantId,
    required String reason,
  }) {
    final member = members
        .where(
          (item) =>
              item.tenantId == tenantId &&
              item.status == LeaseMemberStatus.active,
        )
        .firstOrNull;
    if (member == null || member.isRepresentative) {
      throw ArgumentError(
        'Người đại diện cần liên hệ chủ trọ để kết thúc hợp đồng.',
      );
    }
    if (member.leaveRequestedAt != null) {
      throw ArgumentError('Bạn đã gửi yêu cầu rời phòng rồi.');
    }
    if (reason.trim().length < 5) {
      throw ArgumentError('Nhập lý do rời phòng (ít nhất 5 ký tự).');
    }
    final now = DateTime.now();
    final effective = now.add(const Duration(days: 30));
    member
      ..leaveReason = reason.trim()
      ..leaveRequestedAt = now
      ..leaveEffectiveAt = DateTime(
        effective.year,
        effective.month,
        effective.day,
      )
      ..leaveAcknowledgedAt = null;
    notifyListeners();
    return member;
  }

  void acknowledgeMemberLeave(LeaseMember member) {
    if (!_members.contains(member) ||
        member.status != LeaseMemberStatus.active ||
        member.leaveRequestedAt == null) {
      throw ArgumentError('Không tìm thấy yêu cầu rời phòng đang chờ.');
    }
    member.leaveAcknowledgedAt = DateTime.now();
    notifyListeners();
  }

  void completeMemberLeave(LeaseMember member) {
    if (!_members.contains(member) ||
        member.status != LeaseMemberStatus.active ||
        member.leaveRequestedAt == null ||
        member.leaveEffectiveAt == null) {
      throw ArgumentError('Không tìm thấy yêu cầu rời phòng hợp lệ.');
    }
    final today = DateTime.now();
    final effective = member.leaveEffectiveAt!;
    if (DateTime(
      today.year,
      today.month,
      today.day,
    ).isBefore(DateTime(effective.year, effective.month, effective.day))) {
      throw ArgumentError('Chỉ hoàn tất rời phòng sau đủ 30 ngày báo trước.');
    }
    member.status = LeaseMemberStatus.left;
    final lease = leaseById(member.leaseId);
    if (lease != null) {
      lease.occupantCount = membersForLease(lease.id).length;
      lease.services = List.unmodifiable(
        lease.services.map((service) {
          if (!service.basis.toLowerCase().contains('người')) return service;
          return LandlordLeaseService(
            serviceId: service.serviceId,
            name: service.name,
            unit: service.unit,
            basis: service.basis,
            price: service.price,
            quantity: lease.occupantCount,
            amount: service.price * lease.occupantCount,
          );
        }),
      );
      if (lease.services.isNotEmpty) {
        lease.serviceFee = lease.services.fold<int>(
          0,
          (sum, service) => sum + service.amount,
        );
      }
    }
    notifyListeners();
  }

  void reviewMember(
    LeaseMember member, {
    required bool approve,
    String reason = '',
  }) {
    final lease = leaseById(member.leaseId);
    if (!_members.contains(member) ||
        member.status != LeaseMemberStatus.pending ||
        lease == null ||
        !lease.isCurrent) {
      throw ArgumentError(
        'Yêu cầu không còn chờ duyệt hoặc hợp đồng hết hiệu lực.',
      );
    }
    final count = membersForLease(lease.id).length;
    if (approve && count >= (roomByCode(lease.room)?.capacity ?? 0)) {
      throw ArgumentError('Phòng đã đủ sức chứa.');
    }
    if (!approve && reason.trim().isEmpty) {
      throw ArgumentError('Nhập lý do từ chối.');
    }
    member.status = approve
        ? LeaseMemberStatus.active
        : LeaseMemberStatus.rejected;
    member.rejectionReason = approve ? null : reason.trim();
    lease.occupantCount = lease.occupantCount > membersForLease(lease.id).length
        ? lease.occupantCount
        : membersForLease(lease.id).length;
    lease.services = List.unmodifiable(
      lease.services.map((service) {
        if (!service.basis.toLowerCase().contains('người')) return service;
        final quantity = lease.occupantCount;
        return LandlordLeaseService(
          serviceId: service.serviceId,
          name: service.name,
          unit: service.unit,
          basis: service.basis,
          price: service.price,
          quantity: quantity,
          amount: service.price * quantity,
        );
      }),
    );
    if (lease.services.isNotEmpty) {
      lease.serviceFee = lease.services.fold<int>(
        0,
        (total, service) => total + service.amount,
      );
    }
    notifyListeners();
  }

  final _incidents = <LandlordIncident>[
    LandlordIncident(
      id: 'incident-ac',
      leaseId: 'HD-2026-0302',
      reporterId: TenantSession.tenantId,
      title: 'Máy lạnh không lạnh',
      room: 'A.302',
      reporter: 'Minh Anh',
      category: 'Điện lạnh',
      description: 'Máy lạnh chạy nhưng không ra hơi lạnh từ tối qua.',
      date: '04/10/2026',
      urgent: true,
    ),
    LandlordIncident(
      id: 'incident-water',
      leaseId: 'HD-2026-0101',
      reporterId: 'tenant-khoa',
      title: 'Vòi nước rò rỉ',
      room: 'A.101',
      reporter: 'Lê Văn Khoa',
      category: 'Nước',
      description: 'Vòi trong nhà vệ sinh bị rỉ nước liên tục.',
      date: '02/10/2026',
      status: IncidentStatus.inProgress,
    ),
    LandlordIncident(
      id: 'incident-light',
      leaseId: 'HD-2026-0105',
      reporterId: 'tenant-bao',
      title: 'Bóng đèn hành lang hỏng',
      room: 'B.105',
      reporter: 'Phạm Quốc Bảo',
      category: 'Điện',
      description: 'Bóng đèn trước cửa phòng không sáng.',
      date: '28/09/2026',
      status: IncidentStatus.resolved,
    ),
    LandlordIncident(
      id: 'incident-bathroom',
      leaseId: 'HD-2026-0302',
      reporterId: TenantSession.tenantId,
      title: 'Bóng đèn nhà tắm hỏng',
      room: 'A.302',
      reporter: 'Minh Anh',
      category: 'Điện',
      description: 'Bóng đèn không sáng.',
      date: '20/09/2026',
      status: IncidentStatus.resolved,
    ),
  ];
  int _nextIncident = 1;
  List<LandlordIncident> get incidents => List.unmodifiable(_incidents);
  List<LandlordIncident> incidentsForTenant(String tenantId) =>
      List.unmodifiable(
        _incidents.where((incident) => incident.reporterId == tenantId),
      );

  void createIncident({
    required String tenantId,
    required String title,
    required String category,
    required String description,
  }) {
    final lease = currentLeaseForTenant(tenantId);
    if (lease == null) {
      throw ArgumentError('Bạn chưa có hợp đồng đang hiệu lực.');
    }
    if (title.trim().isEmpty || description.trim().isEmpty) {
      throw ArgumentError('Vui lòng nhập tiêu đề và mô tả.');
    }
    final reporter = membersForLease(lease.id)
        .firstWhere((member) => member.tenantId == tenantId);
    _incidents.insert(
      0,
      LandlordIncident(
        id: rentalRecordId('incident'),
        leaseId: lease.id,
        reporterId: tenantId,
        title: title.trim(),
        room: lease.room,
        reporter: reporter.name,
        category: category,
        description: description.trim(),
        date: landlordDate(DateTime.now()),
      ),
    );
    notifyListeners();
  }

  void updateIncident(
    LandlordIncident incident,
    IncidentStatus status, {
    String? tenantId,
  }) {
    if (!_incidents.contains(incident)) {
      throw ArgumentError('Sự cố không tồn tại.');
    }
    if (tenantId != null &&
        (incident.reporterId != tenantId ||
            incident.status != IncidentStatus.resolved ||
            ![IncidentStatus.newly, IncidentStatus.closed].contains(status))) {
      throw ArgumentError(
        'Chỉ người báo được xác nhận hoặc mở lại sự cố đã xử lý.',
      );
    }
    incident.status = status;
    notifyListeners();
  }

  final _services = <LandlordService>[
    LandlordService(
      id: 'electricity',
      name: 'Điện',
      unit: 'kWh',
      basis: 'Theo chỉ số',
      price: 4000,
    ),

    LandlordService(
      id: 'water',
      name: 'Nước',
      unit: 'm³',
      basis: 'Theo chỉ số',
      price: 15000,
    ),
    LandlordService(
      id: 'internet',
      name: 'Internet',
      unit: 'phòng',
      basis: 'Theo phòng',
      price: 100000,
    ),
    LandlordService(
      id: 'vehicle',
      name: 'Gửi xe máy',
      unit: 'cái',
      basis: 'Theo cái / xe',
      price: 80000,
    ),

    LandlordService(
      id: 'cleaning',
      name: 'Vệ sinh',
      unit: 'người',
      basis: 'Theo người',
      price: 20000,
    ),
  ];
  int _nextService = 1;
  List<LandlordService> get services => List.unmodifiable(_services);
  LandlordService? serviceById(String id) {
    for (final service in _services) {
      if (service.id == id && service.active) return service;
    }
    return null;
  }

  void saveService({
    LandlordService? existing,
    required String name,
    required String unit,
    required String basis,
    required int price,
  }) {
    if (name.trim().isEmpty || unit.trim().isEmpty || price < 0) {
      throw ArgumentError('Vui lòng nhập đầy đủ và đúng đơn giá.');
    }
    if (existing == null) {
      _services.add(
        LandlordService(
          id: 'service-${_nextService++}',
          name: name.trim(),
          unit: unit.trim(),
          basis: basis,
          price: price,
        ),
      );
    } else {
      existing
        ..name = name.trim()
        ..unit = unit.trim()
        ..basis = basis
        ..price = price;
    }
    notifyListeners();
  }

  void setServiceActive(LandlordService service, bool active) {
    service.active = active;
    notifyListeners();
  }

  void deleteService(LandlordService service) {
    _services.remove(service);
    for (var index = 0; index < _roomTypes.length; index++) {
      final type = _roomTypes[index];
      if (!type.serviceIds.contains(service.id)) continue;
      _roomTypes[index] = LandlordRoomType(
        id: type.id,
        name: type.name,
        monthlyRent: type.monthlyRent,
        serviceIds: List.unmodifiable(
          type.serviceIds.where((id) => id != service.id),
        ),
        servicePrices: Map.unmodifiable(
          Map<String, int>.from(type.servicePrices)..remove(service.id),
        ),
        photos: type.photos,
      );
    }
    notifyListeners();
  }

  final _readings = <LandlordMeterReading>[
    LandlordMeterReading(
      room: 'A.101',
      period: DateTime(2026, 10),
      oldElectric: 1250,
      oldWater: 320,
      newElectric: 1362,
      newWater: 328,
    ),
    LandlordMeterReading(
      room: '102',
      period: DateTime(2026, 10),
      oldElectric: 980,
      oldWater: 210,
    ),
    LandlordMeterReading(
      room: 'A.302',
      period: DateTime(2026, 10),
      oldElectric: 2104,
      oldWater: 455,
      newElectric: 2230,
      newWater: 462,
    ),
    LandlordMeterReading(
      room: 'B.105',
      period: DateTime(2026, 10),
      oldElectric: 640,
      oldWater: 150,
    ),
  ];
  List<LandlordMeterReading> readingsForPeriod(DateTime period) =>
      List.unmodifiable(
        _readings.where(
          (reading) =>
              reading.period.year == period.year &&
              reading.period.month == period.month,
        ),
      );
  LandlordMeterReading? readingForRoom(String room, DateTime period) {
    for (final reading in readingsForPeriod(period)) {
      if (canonicalRoom(reading.room) == canonicalRoom(room)) return reading;
    }
    return null;
  }

  void saveReading(LandlordMeterReading reading, int electric, int water) {
    if (!_readings.contains(reading) ||
        electric < reading.oldElectric ||
        water < reading.oldWater) {
      throw ArgumentError('Chỉ số mới không được nhỏ hơn chỉ số cũ.');
    }
    reading
      ..newElectric = electric
      ..newWater = water;
    notifyListeners();
  }
}
