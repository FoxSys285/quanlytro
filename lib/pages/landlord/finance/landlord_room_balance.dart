import '../landlord_demo_store.dart';
import '../rooms/models/landlord_room.dart';
import 'landlord_finance_models.dart';

enum RoomPaymentState { unpaid, paid, unbilled, vacant }

/// A room stays in debt until every non-cancelled bill up to this month is paid.
/// A room without a bill must never appear as paid merely because its debt is zero.
class LandlordRoomBalance {
  LandlordRoomBalance({
    required this.details,
    required this.invoices,
    required this.period,
  });
  final LandlordRoomDetails details;
  final List<LandlordInvoice> invoices;
  final DateTime period;
  List<LandlordInvoice> get monthlyInvoices => invoices
      .where(
        (i) => i.period.year == period.year && i.period.month == period.month,
      )
      .toList();
  int get remaining => invoices.fold(0, (sum, i) => sum + i.remaining);
  int get monthlyTotal => monthlyInvoices.fold(0, (sum, i) => sum + i.total);
  int get monthlyPaid =>
      monthlyInvoices.fold(0, (sum, i) => sum + i.paidAmount);
  RoomPaymentState get state {
    if (remaining > 0) return RoomPaymentState.unpaid;
    if (monthlyInvoices.isNotEmpty) return RoomPaymentState.paid;
    if (details.lease != null) return RoomPaymentState.unbilled;
    return RoomPaymentState.vacant;
  }

  String get label => switch (state) {
    RoomPaymentState.unpaid => 'Chưa đóng tiền',
    RoomPaymentState.paid => 'Đã đóng tiền',
    RoomPaymentState.unbilled => 'Chưa lập hóa đơn',
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
      ),
  ];
}
