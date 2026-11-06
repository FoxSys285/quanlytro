import '../landlord_demo_store.dart';
import '../rooms/models/landlord_room.dart';
import 'landlord_finance_models.dart';

enum RoomPaymentState { unpaid, pendingReview, paid, unbilled, vacant }

/// A room with no current lease stays vacant; its old bills remain in history.
/// An active room remains in debt until all non-cancelled bills are settled.
class LandlordRoomBalance {
  LandlordRoomBalance({
    required this.details,
    required this.invoices,
    required this.period,
    this.payments = const [],
  });
  final LandlordRoomDetails details;
  final List<LandlordInvoice> invoices;
  final DateTime period;
  final List<LandlordPayment> payments;
  List<LandlordInvoice> get monthlyInvoices => invoices
      .where(
        (i) => i.period.year == period.year && i.period.month == period.month,
      )
      .toList();
  int get remaining => invoices.fold(0, (sum, i) => sum + i.remaining);
  int get monthlyTotal => monthlyInvoices.fold(0, (sum, i) => sum + i.total);
  int get monthlyPaid =>
      monthlyInvoices.fold(0, (sum, i) => sum + i.paidAmount);
  Set<String> get _invoiceIds => invoices.map((invoice) => invoice.id).toSet();
  LandlordPayment? get pendingPayment => payments
      .where(
        (payment) =>
            _invoiceIds.contains(payment.invoiceId) &&
            payment.status == LandlordPaymentStatus.pending,
      )
      .firstOrNull;
  LandlordPayment? get latestReviewedPayment => payments
      .where(
        (payment) =>
            monthlyInvoices.any((invoice) => invoice.id == payment.invoiceId) &&
            payment.status == LandlordPaymentStatus.approved,
      )
      .firstOrNull;
  RoomPaymentState get state {
    if (details.lease == null) return RoomPaymentState.vacant;
    if (pendingPayment != null) return RoomPaymentState.pendingReview;
    if (remaining > 0) return RoomPaymentState.unpaid;
    if (monthlyInvoices.isNotEmpty) return RoomPaymentState.paid;
    return RoomPaymentState.unbilled;
  }

  String get label => switch (state) {
    RoomPaymentState.unpaid => 'Chưa đóng tiền',
    RoomPaymentState.pendingReview => 'Đang chờ duyệt',
    RoomPaymentState.paid => 'Đã đóng tiền',
    RoomPaymentState.unbilled => 'Chưa lập phiếu thu',
    RoomPaymentState.vacant => 'Phòng trống',
  };
}

List<LandlordRoomBalance> landlordRoomBalances(
  LandlordDemoStore store,
  DateTime period,
) {
  final nextMonth = DateTime(period.year, period.month + 1);
  final aliases = <String, String>{};
  for (final room in store.catalog) {
    final canonical = (room.leaseRoomCode ?? room.code).trim().toUpperCase();
    aliases.putIfAbsent(room.code.trim().toUpperCase(), () => canonical);
    if (room.leaseRoomCode != null) {
      aliases.putIfAbsent(
        room.leaseRoomCode!.trim().toUpperCase(),
        () => canonical,
      );
    }
  }
  String canonical(String code) {
    final clean = code.trim().toUpperCase();
    return aliases[clean] ?? clean;
  }

  final grouped = <String, List<LandlordInvoice>>{};
  for (final invoice in store.invoices) {
    if (invoice.cancelled || !invoice.period.isBefore(nextMonth)) continue;
    grouped.putIfAbsent(canonical(invoice.room), () => []).add(invoice);
  }
  for (final invoices in grouped.values) {
    invoices.sort((a, b) => b.period.compareTo(a.period));
  }
  return [
    for (final details in store.roomDetails)
      LandlordRoomBalance(
        details: details,
        period: period,
        invoices: grouped[canonical(details.room.code)] ?? const [],
        payments: store.payments,
      ),
  ];
}
