class TenantPaymentRecord {
  const TenantPaymentRecord({
    required this.month,
    required this.date,
    required this.amount,
    required this.method,
    required this.reference,
    required this.status,
  });
  final String month;
  final String date;
  final int amount;
  final String method;
  final String reference;
  final String status;
}
