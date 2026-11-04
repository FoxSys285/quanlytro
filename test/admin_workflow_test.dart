import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_commission.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';

LandlordDemoStore financialStore() {
  final store = LandlordDemoStore.demo();
  final map = store.toMap();
  final invoice = LandlordInvoice(
    id: 'invoice',
    leaseId: 'lease',
    room: '101',
    tenantName: 'Test',
    period: DateTime(2026, 1),
    dueDate: DateTime(2026, 1, 10),
    charges: [
      const LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: 3000000),
      const LandlordInvoiceCharge(name: 'Điện nước', amount: 1000000),
    ],
  );
  map['invoices'] = [
    invoice.toMap(),
    {...invoice.toMap(), 'id': 'cancelled', 'cancelled': true},
  ];
  LandlordPayment payment(
    String id,
    LandlordPaymentStatus status, {
    String invoiceId = 'invoice',
    DateTime? date,
  }) => LandlordPayment(
    id: id,
    invoiceId: invoiceId,
    tenantName: 'Test',
    room: '101',
    reportedAmount: 2000000,
    paidAt: date ?? DateTime(2026, 1, 5),
    method: 'Chuyển khoản',
    reference: id,
    status: status,
    approvedAmount: status == LandlordPaymentStatus.approved ? 2000000 : null,
  );
  map['payments'] = [
    payment('approved', LandlordPaymentStatus.approved).toMap(),
    payment('pending', LandlordPaymentStatus.pending).toMap(),
    payment('rejected', LandlordPaymentStatus.rejected).toMap(),
    payment(
      'cancelled',
      LandlordPaymentStatus.approved,
      invoiceId: 'cancelled',
    ).toMap(),
    payment(
      'other-month',
      LandlordPaymentStatus.approved,
      date: DateTime(2026, 2, 1),
    ).toMap(),
  ];
  store.restore(map);
  return store;
}

void main() {
  setUpAll(() async {
    await LocalAuth.instance.initialize();
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
  });
  tearDownAll(() => LocalAuth.instance.signOut());

  test('Commission counts approved rent share by payment month, excludes pending/rejected/cancelled', () {
    final store = financialStore();
    expect(commissionRentCollected(store, DateTime(2026, 1)), 1500000);
    expect(commissionRentCollected(store, DateTime(2026, 2)), 1500000);
    expect(commissionRentCollected(store, DateTime(2026, 3)), 0);
    store.payments.first.reviewedAt = DateTime(2026, 2, 2);
    expect(commissionRentCollected(store, DateTime(2026, 1)), 0);
    expect(commissionRentCollected(store, DateTime(2026, 2)), 3000000);
  });

  test('Closing freezes amount/rate, receipt validation and JSON reopen preserve balances', () {
    final store = financialStore();
    RentalPortfolio.instance = RentalPortfolio([store]);
    final admin = AdminStore();
    expect(
      () => admin.closeCommission('may', DateTime(2026, 1)),
      throwsArgumentError,
    );
    expect(() => admin.setCommissionRate('may', -1), throwsArgumentError);
    expect(() => admin.setCommissionRate('may', 10001), throwsArgumentError);
    admin.setCommissionRate('may', 500);
    final statement = admin.closeCommission('may', DateTime(2026, 1));
    expect(statement.due, 75000);
    expect(
      () => admin.closeCommission('may', DateTime(2026, 1)),
      throwsArgumentError,
    );
    expect(
      () => admin.closeCommission('may', DateTime.now()),
      throwsArgumentError,
    );
    admin.setCommissionRate('may', 1000);
    store.payments.first.approvedAmount = 100;
    expect(statement.due, 75000);
    expect(statement.rateBasisPoints, 500);
    expect(
      () => admin.receiveCommission(statement, 0, 'REF'),
      throwsArgumentError,
    );
    expect(
      () => admin.receiveCommission(statement, 80000, 'REF'),
      throwsArgumentError,
    );
    expect(
      () => admin.receiveCommission(statement, 1000, ''),
      throwsArgumentError,
    );
    admin.receiveCommission(statement, 25000, 'REF-1');
    expect(
      () => admin.receiveCommission(statement, 1000, ' REF-1 '),
      throwsArgumentError,
    );
    expect(statement.remaining, 50000);
    final restored = AdminStore()
      ..restore(
        Map<String, dynamic>.from(jsonDecode(jsonEncode(admin.toMap())) as Map),
      );
    expect(restored.statements.single.remaining, 50000);
    restored.receiveCommission(restored.statements.single, 50000, 'REF-2');
    expect(restored.statements.single.remaining, 0);
    expect(restored.logs.first['action'], contains('REF-2'));
  });

  test('Verification blocks incomplete files, becomes stale on edits, and restores safely', () {
    final store = LandlordDemoStore.demo();
    RentalPortfolio.instance = RentalPortfolio([store]);
    final admin = AdminStore();
    expect(AdminStore.verificationIssues(store), contains('Ảnh nhà trọ'));
    expect(() => admin.verify('may', true), throwsArgumentError);
    final map = store.toMap();
    (map['property'] as Map)['imageUrl'] =
        'assets/images/room_types/studio.webp';
    store.restore(map);
    expect(AdminStore.verificationIssues(store), isEmpty);
    admin.verify('may', true);
    expect(admin.isVerified('may'), isTrue);
    final restored = AdminStore()
      ..restore(
        Map<String, dynamic>.from(jsonDecode(jsonEncode(admin.toMap())) as Map),
      );
    expect(restored.isVerified('may'), isTrue);
    final edited = store.toMap();
    (edited['property'] as Map)['phone'] = '0912345678';
    store.restore(edited);
    expect(restored.isVerified('may'), isFalse);
    admin.requestSupplement('may', 'Vui lòng kiểm tra lại số điện thoại.');
    expect(admin.reviewNote('may'), contains('điện thoại'));
    expect(admin.isVerified('may'), isFalse);
  });

  test('Unauthenticated roles cannot perform admin operations', () async {
    final admin = AdminStore();
    await LocalAuth.instance.signOut();
    expect(() => admin.verify('may', true), throwsArgumentError);
    expect(() => admin.setCommissionRate('may', 500), throwsArgumentError);
    expect(
      () => admin.closeCommission('may', DateTime(2026, 1)),
      throwsArgumentError,
    );
    expect(
      () => admin.requestSupplement('may', 'Bổ sung ảnh nhà trọ.'),
      throwsArgumentError,
    );
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
    LocalAuth.instance.setForeground(false);
    expect(LocalAuth.instance.isForeground, isFalse);
    LocalAuth.instance.setForeground(true);
    expect(LocalAuth.instance.localAccounts.length, 3);
  });
}
