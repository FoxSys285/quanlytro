enum LandlordLeaseStatus { active, draft, terminated }

class LandlordLease {
  LandlordLease({
    required this.id,
    required this.room,
    required this.tenantName,
    required this.phone,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.termMonths,
    required this.dueDay,
    this.tenantId = '',
    this.propertyId = 'may',
    this.landlordName = '',
    this.landlordPermanentAddress = '',
    this.landlordCitizenId = '',
    this.landlordContact = '',
    this.tenantBirthYear = '',
    this.tenantCitizenId = '',
    this.tenantCitizenIssueDate,
    this.tenantPermanentAddress = '',
    this.electricityPrice = 3500,
    this.waterPrice = 15000,
    this.waterType = 'Theo m³',
    this.vehicleFee = 0,
    this.serviceFee = 0,
    this.cashPaymentEnabled = true,
    this.cashPaymentLocation = '',
    this.bankTransferEnabled = true,
    this.bankName = '',
    this.bankAccountNumber = '',
    this.occupantCount = 1,
    this.status = LandlordLeaseStatus.active,
    this.note = '',
  });

  final String id;
  final String tenantId;
  final String propertyId;
  String room;
  String tenantName;
  String phone;
  DateTime startDate;
  DateTime endDate;
  int monthlyRent;
  int deposit;
  int termMonths;
  int dueDay;
  String landlordName;
  String landlordPermanentAddress;
  String landlordCitizenId;
  String landlordContact;
  String tenantBirthYear;
  String tenantCitizenId;
  DateTime? tenantCitizenIssueDate;
  String tenantPermanentAddress;
  int electricityPrice;
  int waterPrice;
  String waterType;
  int vehicleFee;
  int serviceFee;
  bool cashPaymentEnabled;
  String cashPaymentLocation;
  bool bankTransferEnabled;
  String bankName;
  String bankAccountNumber;
  int occupantCount;
  LandlordLeaseStatus status;
  String note;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isCurrent =>
      status == LandlordLeaseStatus.active &&
      !DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).isAfter(_today) &&
      !DateTime(endDate.year, endDate.month, endDate.day).isBefore(_today);

  bool get isUpcoming =>
      status == LandlordLeaseStatus.active &&
      DateTime(startDate.year, startDate.month, startDate.day).isAfter(_today);

  bool get isExpired =>
      status == LandlordLeaseStatus.active &&
      DateTime(endDate.year, endDate.month, endDate.day).isBefore(_today);

  bool get isExpiringSoon {
    if (!isCurrent) return false;
    final lastDay = DateTime(endDate.year, endDate.month, endDate.day);
    return lastDay.difference(_today).inDays <= 45;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'tenantId': tenantId,
    'propertyId': propertyId,
    'room': room,
    'tenantName': tenantName,
    'phone': phone,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'monthlyRent': monthlyRent,
    'deposit': deposit,
    'termMonths': termMonths,
    'dueDay': dueDay,
    'landlordName': landlordName,
    'landlordPermanentAddress': landlordPermanentAddress,
    'landlordCitizenId': landlordCitizenId,
    'landlordContact': landlordContact,
    'tenantBirthYear': tenantBirthYear,
    'tenantCitizenId': tenantCitizenId,
    'tenantCitizenIssueDate': tenantCitizenIssueDate?.toIso8601String(),
    'tenantPermanentAddress': tenantPermanentAddress,
    'electricityPrice': electricityPrice,
    'waterPrice': waterPrice,
    'waterType': waterType,
    'vehicleFee': vehicleFee,
    'serviceFee': serviceFee,
    'cashPaymentEnabled': cashPaymentEnabled,
    'cashPaymentLocation': cashPaymentLocation,
    'bankTransferEnabled': bankTransferEnabled,
    'bankName': bankName,
    'bankAccountNumber': bankAccountNumber,
    'occupantCount': occupantCount,
    'status': status.name,
    'note': note,
  };

  factory LandlordLease.fromMap(Map<String, dynamic> map) => LandlordLease(
    id: map['id'] as String,
    tenantId: map['tenantId'] as String,
    propertyId: map['propertyId'] as String,
    room: map['room'] as String,
    tenantName: map['tenantName'] as String,
    phone: map['phone'] as String,
    startDate: DateTime.parse(map['startDate'] as String),
    endDate: DateTime.parse(map['endDate'] as String),
    monthlyRent: map['monthlyRent'] as int,
    deposit: map['deposit'] as int,
    termMonths: map['termMonths'] as int,
    dueDay: map['dueDay'] as int,
    landlordName: map['landlordName'] as String,
    landlordPermanentAddress: map['landlordPermanentAddress'] as String,
    landlordCitizenId: map['landlordCitizenId'] as String,
    landlordContact: map['landlordContact'] as String,
    tenantBirthYear: map['tenantBirthYear'] as String,
    tenantCitizenId: map['tenantCitizenId'] as String,
    tenantCitizenIssueDate: map['tenantCitizenIssueDate'] == null
        ? null
        : DateTime.parse(map['tenantCitizenIssueDate'] as String),
    tenantPermanentAddress: map['tenantPermanentAddress'] as String,
    electricityPrice: map['electricityPrice'] as int,
    waterPrice: map['waterPrice'] as int,
    waterType: map['waterType'] as String,
    vehicleFee: map['vehicleFee'] as int,
    serviceFee: map['serviceFee'] as int,
    cashPaymentEnabled: map['cashPaymentEnabled'] as bool,
    cashPaymentLocation: map['cashPaymentLocation'] as String,
    bankTransferEnabled: map['bankTransferEnabled'] as bool,
    bankName: map['bankName'] as String,
    bankAccountNumber: map['bankAccountNumber'] as String,
    occupantCount: map['occupantCount'] as int,
    status: LandlordLeaseStatus.values.byName(map['status'] as String),
    note: map['note'] as String,
  );
}

class LandlordInvoiceCharge {
  const LandlordInvoiceCharge({required this.name, required this.amount});

  final String name;
  final int amount;

  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};

  factory LandlordInvoiceCharge.fromMap(Map<String, dynamic> map) =>
      LandlordInvoiceCharge(
        name: map['name'] as String,
        amount: map['amount'] as int,
      );
}

enum LandlordInvoiceStatus { unpaid, partial, paid, overdue, cancelled }

extension LandlordInvoiceStatusLabel on LandlordInvoiceStatus {
  String get label => switch (this) {
    LandlordInvoiceStatus.unpaid => 'Chưa thanh toán',
    LandlordInvoiceStatus.partial => 'Thanh toán một phần',
    LandlordInvoiceStatus.paid => 'Đã thanh toán',
    LandlordInvoiceStatus.overdue => 'Quá hạn',
    LandlordInvoiceStatus.cancelled => 'Đã hủy',
  };
}

class LandlordInvoice {
  LandlordInvoice({
    required this.id,
    required this.leaseId,
    required this.room,
    required this.tenantName,
    required this.period,
    required this.dueDate,
    required this.charges,
    this.paidAmount = 0,
    this.cancelled = false,
  });

  final String id;
  final String leaseId;
  final String room;
  final String tenantName;
  final DateTime period;
  DateTime dueDate;
  final List<LandlordInvoiceCharge> charges;
  int paidAmount;
  bool cancelled;

  int get total => charges.fold(0, (sum, charge) => sum + charge.amount);
  int get remaining {
    final amount = total - paidAmount;
    if (amount < 0) return 0;
    return amount;
  }

  LandlordInvoiceStatus get status {
    if (cancelled) return LandlordInvoiceStatus.cancelled;
    if (paidAmount >= total) return LandlordInvoiceStatus.paid;
    if (paidAmount > 0) return LandlordInvoiceStatus.partial;
    final endOfDueDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
    );
    if (DateTime.now().isAfter(endOfDueDate)) {
      return LandlordInvoiceStatus.overdue;
    }
    return LandlordInvoiceStatus.unpaid;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'leaseId': leaseId,
    'room': room,
    'tenantName': tenantName,
    'period': period.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'charges': charges.map((item) => item.toMap()).toList(),
    'paidAmount': paidAmount,
    'cancelled': cancelled,
  };

  factory LandlordInvoice.fromMap(Map<String, dynamic> map) => LandlordInvoice(
    id: map['id'] as String,
    leaseId: map['leaseId'] as String,
    room: map['room'] as String,
    tenantName: map['tenantName'] as String,
    period: DateTime.parse(map['period'] as String),
    dueDate: DateTime.parse(map['dueDate'] as String),
    charges: (map['charges'] as List)
        .map(
          (item) => LandlordInvoiceCharge.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
    paidAmount: map['paidAmount'] as int,
    cancelled: map['cancelled'] as bool,
  );
}

enum LandlordPaymentStatus { pending, approved, rejected }

class LandlordPayment {
  LandlordPayment({
    required this.id,
    required this.invoiceId,
    required this.tenantName,
    required this.room,
    required this.reportedAmount,
    required this.paidAt,
    required this.method,
    required this.reference,
    this.status = LandlordPaymentStatus.pending,
    this.approvedAmount,
    this.rejectionReason,
    this.proofBytes,
    this.proofName,
    this.paymentAccountId,
  });

  final String id;
  final String invoiceId;
  final String tenantName;
  final String room;
  final int reportedAmount;
  final DateTime paidAt;
  final String method;
  final String reference;
  LandlordPaymentStatus status;
  int? approvedAmount;
  String? rejectionReason;
  final List<int>? proofBytes;
  final String? proofName;
  final String? paymentAccountId;
  DateTime? reviewedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'invoiceId': invoiceId,
    'tenantName': tenantName,
    'room': room,
    'reportedAmount': reportedAmount,
    'paidAt': paidAt.toIso8601String(),
    'method': method,
    'reference': reference,
    'status': status.name,
    'approvedAmount': approvedAmount,
    'rejectionReason': rejectionReason,
    'proofBytes': proofBytes,
    'proofName': proofName,
    'paymentAccountId': paymentAccountId,
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  factory LandlordPayment.fromMap(Map<String, dynamic> map) =>
      LandlordPayment(
          id: map['id'] as String,
          invoiceId: map['invoiceId'] as String,
          tenantName: map['tenantName'] as String,
          room: map['room'] as String,
          reportedAmount: map['reportedAmount'] as int,
          paidAt: DateTime.parse(map['paidAt'] as String),
          method: map['method'] as String,
          reference: map['reference'] as String,
          status: LandlordPaymentStatus.values.byName(map['status'] as String),
          approvedAmount: map['approvedAmount'] as int?,
          rejectionReason: map['rejectionReason'] as String?,
          proofBytes: map['proofBytes'] == null
              ? null
              : List<int>.from(map['proofBytes'] as List),
          proofName: map['proofName'] as String?,
          paymentAccountId: map['paymentAccountId'] as String?,
        )
        ..reviewedAt = map['reviewedAt'] == null
            ? null
            : DateTime.parse(map['reviewedAt'] as String);
}

class LandlordPaymentAccount {
  LandlordPaymentAccount({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.branch = '',
    this.isDefault = false,
    this.isActive = true,
    this.isVerified = true,
  });

  final String id;
  String bankName;
  String accountName;
  String accountNumber;
  String branch;
  bool isDefault;
  bool isActive;
  bool isVerified;

  String get maskedNumber {
    final digits = accountNumber.replaceAll(RegExp(r'\s+'), '');
    if (digits.length <= 4) return digits;
    return '${List.filled(digits.length - 4, '•').join()}${digits.substring(digits.length - 4)}';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'bankName': bankName,
    'accountName': accountName,
    'accountNumber': accountNumber,
    'branch': branch,
    'isDefault': isDefault,
    'isActive': isActive,
    'isVerified': isVerified,
  };

  factory LandlordPaymentAccount.fromMap(Map<String, dynamic> map) =>
      LandlordPaymentAccount(
        id: map['id'] as String,
        bankName: map['bankName'] as String,
        accountName: map['accountName'] as String,
        accountNumber: map['accountNumber'] as String,
        branch: map['branch'] as String,
        isDefault: map['isDefault'] as bool,
        isActive: map['isActive'] as bool,
        isVerified: map['isVerified'] as bool,
      );
}

String landlordDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String landlordMonth(DateTime date) =>
    'Tháng ${date.month.toString().padLeft(2, '0')}/${date.year}';
