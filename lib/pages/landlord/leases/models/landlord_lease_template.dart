class LandlordLeaseTemplate {
  const LandlordLeaseTemplate({
    required this.id,
    required this.name,
    required this.landlordName,
    required this.landlordPermanentAddress,
    required this.landlordCitizenId,
    required this.landlordContact,
    required this.landlordBirthDate,
    required this.landlordCitizenIssueDate,
    required this.landlordCitizenIssuePlace,
    required this.electricityPrice,
    required this.waterPrice,
    required this.waterType,
    required this.cashPaymentEnabled,
    required this.cashPaymentLocation,
    required this.bankTransferEnabled,
    required this.bankName,
    required this.bankAccountNumber,
    required this.responsibilityA,
    required this.responsibilityB,
    required this.commonResponsibilities,
  });

  final String id;
  final String name;
  final String landlordName;
  final String landlordPermanentAddress;
  final String landlordCitizenId;
  final String landlordContact;
  final DateTime? landlordBirthDate;
  final DateTime? landlordCitizenIssueDate;
  final String landlordCitizenIssuePlace;
  final int electricityPrice;
  final int waterPrice;
  final String waterType;
  final bool cashPaymentEnabled;
  final String cashPaymentLocation;
  final bool bankTransferEnabled;
  final String bankName;
  final String bankAccountNumber;
  final String responsibilityA;
  final String responsibilityB;
  final String commonResponsibilities;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'landlordName': landlordName,
    'landlordPermanentAddress': landlordPermanentAddress,
    'landlordCitizenId': landlordCitizenId,
    'landlordContact': landlordContact,
    'landlordBirthDate': landlordBirthDate?.toIso8601String(),
    'landlordCitizenIssueDate': landlordCitizenIssueDate?.toIso8601String(),
    'landlordCitizenIssuePlace': landlordCitizenIssuePlace,
    'electricityPrice': electricityPrice,
    'waterPrice': waterPrice,
    'waterType': waterType,
    'cashPaymentEnabled': cashPaymentEnabled,
    'cashPaymentLocation': cashPaymentLocation,
    'bankTransferEnabled': bankTransferEnabled,
    'bankName': bankName,
    'bankAccountNumber': bankAccountNumber,
    'responsibilityA': responsibilityA,
    'responsibilityB': responsibilityB,
    'commonResponsibilities': commonResponsibilities,
  };

  factory LandlordLeaseTemplate.fromMap(Map<String, dynamic> map) =>
      LandlordLeaseTemplate(
        id: map['id'] as String,
        name: map['name'] as String,
        landlordName: map['landlordName'] as String? ?? '',
        landlordPermanentAddress:
            map['landlordPermanentAddress'] as String? ?? '',
        landlordCitizenId: map['landlordCitizenId'] as String? ?? '',
        landlordContact: map['landlordContact'] as String? ?? '',
        landlordBirthDate: map['landlordBirthDate'] == null
            ? null
            : DateTime.parse(map['landlordBirthDate'] as String),
        landlordCitizenIssueDate: map['landlordCitizenIssueDate'] == null
            ? null
            : DateTime.parse(map['landlordCitizenIssueDate'] as String),
        landlordCitizenIssuePlace:
            map['landlordCitizenIssuePlace'] as String? ?? '',
        electricityPrice: map['electricityPrice'] as int? ?? 3500,
        waterPrice: map['waterPrice'] as int? ?? 15000,
        waterType: map['waterType'] as String? ?? 'Theo m³',
        cashPaymentEnabled: map['cashPaymentEnabled'] as bool? ?? true,
        cashPaymentLocation: map['cashPaymentLocation'] as String? ?? '',
        bankTransferEnabled: map['bankTransferEnabled'] as bool? ?? false,
        bankName: map['bankName'] as String? ?? '',
        bankAccountNumber: map['bankAccountNumber'] as String? ?? '',
        responsibilityA: map['responsibilityA'] as String? ?? '',
        responsibilityB: map['responsibilityB'] as String? ?? '',
        commonResponsibilities: map['commonResponsibilities'] as String? ?? '',
      );
}
