import '../pages/landlord/finance/landlord_finance_models.dart';
import '../pages/landlord/landlord_demo_store.dart';

/// Chỉ tính phần tiền phòng trong khoản thu đã duyệt; loại điện, nước, dịch vụ.
int commissionRentCollected(LandlordDemoStore store, DateTime month) {
  var total = 0;
  for (final payment in store.payments) {
    // Khoản báo trả muộn được tính khi duyệt thu, tránh rơi vào kỳ đã chốt.
    final receivedAt = payment.reviewedAt ?? payment.paidAt;
    if (payment.status != LandlordPaymentStatus.approved ||
        receivedAt.year != month.year ||
        receivedAt.month != month.month) {
      continue;
    }
    final invoice = store.invoiceById(payment.invoiceId);
    if (invoice == null || invoice.cancelled || invoice.total <= 0) continue;
    final rent = invoice.charges
        .where(
          (c) => const [
            'tiền phòng',
            'tiền thuê phòng',
          ].contains(c.name.trim().toLowerCase()),
        )
        .fold<int>(0, (sum, c) => sum + c.amount);
    // Thanh toán từng phần: phân bổ theo tỷ trọng tiền phòng trên hóa đơn.
    total +=
        ((payment.approvedAmount ?? 0) * rent + invoice.total ~/ 2) ~/
        invoice.total;
  }
  return total;
}

class CommissionStatement {
  CommissionStatement({
    required this.propertyId,
    required this.propertyName,
    required this.month,
    required this.rentCollected,
    required this.rateBasisPoints,
    required this.createdAt,
    List<Map<String, dynamic>>? receipts,
  }) : _receipts = receipts ?? [];

  final String propertyId;
  final String propertyName;
  final DateTime month;
  final int rentCollected;
  final int rateBasisPoints;
  final DateTime createdAt;
  final List<Map<String, dynamic>> _receipts;
  String get id => '$propertyId:${month.year}-${month.month}';
  int get due => (rentCollected * rateBasisPoints + 5000) ~/ 10000;
  int get received => _receipts.fold(0, (sum, r) => sum + (r['amount'] as int));
  int get remaining => due - received;
  List<Map<String, dynamic>> get receipts => List.unmodifiable(
    _receipts.map((r) => Map<String, dynamic>.unmodifiable(r)),
  );

  void receive(int amount, String reference, DateTime now) {
    if (amount <= 0 || amount > remaining || reference.trim().isEmpty) {
      throw ArgumentError(
        'Nhập số tiền trong phạm vi còn phải thu và mã chứng từ.',
      );
    }
    if (_receipts.any((r) => r['reference'] == reference.trim())) {
      throw ArgumentError('Mã chứng từ đã được ghi nhận trong kỳ này.');
    }
    _receipts.add({
      'amount': amount,
      'reference': reference.trim(),
      'at': now.toIso8601String(),
    });
  }

  Map<String, dynamic> toMap() => {
    'propertyId': propertyId,
    'propertyName': propertyName,
    'month': month.toIso8601String(),
    'rentCollected': rentCollected,
    'rateBasisPoints': rateBasisPoints,
    'createdAt': createdAt.toIso8601String(),
    'receipts': _receipts,
  };
  factory CommissionStatement.fromMap(Map<String, dynamic> map) =>
      CommissionStatement(
        propertyId: map['propertyId'] as String,
        propertyName: map['propertyName'] as String,
        month: DateTime.parse(map['month'] as String),
        rentCollected: map['rentCollected'] as int,
        rateBasisPoints: map['rateBasisPoints'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
        receipts: (map['receipts'] as List? ?? const [])
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList(),
      );
}
