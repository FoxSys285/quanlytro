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
}

class LandlordInvoiceCharge {
  const LandlordInvoiceCharge({required this.name, required this.amount});

  final String name;
  final int amount;
}

enum LandlordInvoiceStatus { unpaid, partial, paid, overdue, cancelled }

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
    if (DateTime.now().isAfter(endOfDueDate))
      return LandlordInvoiceStatus.overdue;
    return LandlordInvoiceStatus.unpaid;
  }
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
}

String landlordDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String landlordMonth(DateTime date) =>
    'Tháng ${date.month.toString().padLeft(2, '0')}/${date.year}';
