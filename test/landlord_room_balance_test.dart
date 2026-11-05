import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_room_balance.dart';
import 'package:quanlytro/pages/landlord/rooms/models/landlord_room.dart';

import 'support/landlord_redesign_fixture.dart';

void main() {
  final month = DateTime(2026, 11);
  const room = LandlordRoom(
    code: '101',
    floor: 1,
    roomTypeId: 'studio',
    area: 20,
    capacity: 2,
  );
  LandlordInvoice bill({
    int paid = 0,
    bool cancelled = false,
    DateTime? period,
  }) => LandlordInvoice(
    id: 'bill',
    leaseId: 'lease',
    room: 'A.101',
    tenantName: 'Người thuê',
    period: period ?? month,
    dueDate: DateTime(2026, 11, 10),
    charges: const [LandlordInvoiceCharge(name: 'Tiền phòng', amount: 3000000)],
    paidAmount: paid,
    cancelled: cancelled,
  );

  test('Partial payments remain unpaid; full payment is green', () {
    final invoice = bill(paid: 1000000);
    final balance = LandlordRoomBalance(
      details: const LandlordRoomDetails(room: room),
      invoices: [invoice],
      period: month,
    );
    expect(balance.state, RoomPaymentState.unpaid);
    expect(balance.remaining, 2000000);
    invoice.paidAmount = 3000000;
    expect(balance.state, RoomPaymentState.paid);
    expect(balance.remaining, 0);
  });
  test('Paid current month retains unpaid debt from earlier months', () {
    final balance = LandlordRoomBalance(
      details: const LandlordRoomDetails(room: room),
      invoices: [
        bill(paid: 3000000),
        bill(period: DateTime(2026, 10)),
      ],
      period: month,
    );
    expect(balance.state, RoomPaymentState.unpaid);
    expect(balance.remaining, 3000000);
    expect(balance.monthlyPaid, 3000000);
  });
  test('No invoice does not count as paid', () {
    final balance = LandlordRoomBalance(
      details: const LandlordRoomDetails(room: room),
      invoices: [],
      period: month,
    );
    expect(balance.state, RoomPaymentState.vacant);
  });
  test(
    'Room aliases group correctly and cancelled or future bills do not count',
    () {
      final store = landlordRedesignFixture();
      addTearDown(store.dispose);
      final now = DateTime.now();
      final paidRoom = landlordRoomBalances(
        store,
        now,
      ).firstWhere((b) => b.details.room.code == '101');
      expect(paidRoom.state, RoomPaymentState.paid);
      final invoice = store.invoices.firstWhere((i) => i.room == 'A.101');
      invoice.cancelled = true;
      expect(
        landlordRoomBalances(
          store,
          now,
        ).firstWhere((b) => b.details.room.code == '101').state,
        RoomPaymentState.unbilled,
      );
      final before = DateTime(now.year, now.month - 1);
      expect(
        landlordRoomBalances(store, before).every((b) => b.remaining == 0),
        isTrue,
      );
    },
  );
}
