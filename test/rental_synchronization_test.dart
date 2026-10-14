import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/announcements/models/landlord_announcement.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_conversation.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/incidents/landlord_incidents_page.dart';
import 'package:quanlytro/pages/landlord/incidents/models/landlord_incident.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/shared/rental/lease_member.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';
import 'package:quanlytro/pages/tenant/announcements/tenant_announcements_page.dart';
import 'package:quanlytro/pages/tenant/conversations/models/tenant_conversation.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/incidents/tenant_incidents_page.dart';
import 'package:quanlytro/pages/tenant/invoices/tenant_invoice_detail_page.dart';
import 'package:quanlytro/pages/tenant/leases/tenant_home_page.dart';
import 'package:quanlytro/pages/tenant/leases/components/tenant_lease_overview_card.dart';
import 'package:quanlytro/pages/tenant/members/tenant_members_page.dart';

LandlordDemoStore createStore() {
  final store = LandlordDemoStore.demo();
  final now = DateTime.now();
  for (final lease in store.leases) {
    lease.startDate = now.subtract(const Duration(days: 30));
    lease.endDate = now.add(const Duration(days: 365));
  }
  return store;
}

void saveLease(
  LandlordDemoStore store,
  LandlordLease source, {
  LandlordLease? existing,
  String? room,
  int? rent,
  int? occupants,
  String? name,
  String? phone,
  DateTime? start,
  DateTime? end,
}) => store.saveLease(
  existing: existing,
  room: room ?? source.room,
  landlordName: source.landlordName,
  landlordPermanentAddress: source.landlordPermanentAddress,
  landlordCitizenId: source.landlordCitizenId,
  landlordContact: source.landlordContact,
  tenantName: name ?? source.tenantName,
  tenantBirthYear: source.tenantBirthYear,
  tenantCitizenId: source.tenantCitizenId,
  tenantCitizenIssueDate: source.tenantCitizenIssueDate,
  tenantPermanentAddress: source.tenantPermanentAddress,
  phone: phone ?? source.phone,
  startDate: start ?? source.startDate,
  endDate: end ?? source.endDate,
  monthlyRent: rent ?? source.monthlyRent,
  deposit: source.deposit,
  termMonths: source.termMonths,
  electricityPrice: source.electricityPrice,
  waterPrice: source.waterPrice,
  waterType: source.waterType,
  vehicleFee: source.vehicleFee,
  serviceFee: source.serviceFee,
  dueDay: source.dueDay,
  cashPaymentEnabled: source.cashPaymentEnabled,
  cashPaymentLocation: source.cashPaymentLocation,
  bankTransferEnabled: source.bankTransferEnabled,
  bankName: source.bankName,
  bankAccountNumber: source.bankAccountNumber,
  occupantCount: occupants ?? source.occupantCount,
  note: source.note,
  status: LandlordLeaseStatus.active,
);

LandlordInvoice newInvoice(LandlordDemoStore store) {
  final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
  final now = DateTime.now();
  return store.createInvoice(
    lease: lease,
    period: DateTime(now.year + 1, 1),
    dueDate: DateTime(now.year + 1, 1, 10),
    charges: const [
      LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: 3500000),
      LandlordInvoiceCharge(name: 'Điện · 10 kWh', amount: 35000),
    ],
  );
}

void main() {
  late LandlordDemoStore store;
  setUp(() => store = createStore());
  tearDown(() => store.dispose());

  test('Tenant identity links lease, members and invoices without using room or name', () {
    final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
    expect(lease.id, 'HD-2026-0302');
    expect(
      store.invoicesForTenant(TenantSession.tenantId).single.leaseId,
      lease.id,
    );
    expect(store.membersForLease(lease.id).map((member) => member.name), [
      'Minh Anh',
      'Trần Thu Hà',
    ]);
    saveLease(
      store,
      lease,
      existing: lease,
      name: 'Minh Anh mới',
      phone: '0909999999',
    );
    expect(store.currentLeaseForTenant(TenantSession.tenantId), same(lease));
    expect(store.membersForLease(lease.id).first.name, 'Minh Anh mới');
    expect(store.invoicesForTenant('tenant-other'), isEmpty);
    expect(store.incidentsForTenant('tenant-other'), isEmpty);
  });

  test('Submitting, rejecting, resubmitting and approving partial payments sync balances', () {
    final invoice = newInvoice(store);
    final payment = store.submitPayment(
      tenantId: TenantSession.tenantId,
      invoiceId: invoice.id,
      amount: 1000000,
      reference: 'REF-1',
      method: 'Chuyển khoản',
      proofBytes: [1, 2, 3],
      proofName: 'proof.png',
    );
    expect(store.paymentsForTenant(TenantSession.tenantId), contains(payment));
    expect(invoice.paidAmount, 0);
    expect(invoice.remaining, 3535000);
    expect(payment.proofName, 'proof.png');
    expect(payment.paymentAccountId, store.defaultPaymentAccount!.id);
    expect(
      () => store.submitPayment(
        tenantId: TenantSession.tenantId,
        invoiceId: invoice.id,
        amount: 1000000,
        reference: 'duplicate',
        method: 'Chuyển khoản',
      ),
      throwsArgumentError,
    );
    expect(() => store.cancelInvoice(invoice), throwsArgumentError);
    store.rejectPayment(payment, 'Chưa nhận được tiền');
    expect(payment.rejectionReason, 'Chưa nhận được tiền');
    expect(invoice.paidAmount, 0);
    final replacement = store.submitPayment(
      tenantId: TenantSession.tenantId,
      invoiceId: invoice.id,
      amount: 1000000,
      reference: 'REF-2',
      method: 'Chuyển khoản',
    );
    store.approvePayment(replacement, 800000);
    expect(invoice.status, LandlordInvoiceStatus.partial);
    expect(invoice.remaining, 2735000);
    expect(replacement.reviewedAt, isNotNull);
    expect(
      () => store.approvePayment(replacement, 800000),
      throwsArgumentError,
    );
    expect(invoice.paidAmount, 800000);
    final finalPayment = store.submitPayment(
      tenantId: TenantSession.tenantId,
      invoiceId: invoice.id,
      amount: invoice.remaining,
      reference: 'REF-3',
      method: 'Tiền mặt',
    );
    store.approvePayment(finalPayment, invoice.remaining);
    expect(invoice.status, LandlordInvoiceStatus.paid);
    expect(invoice.remaining, 0);
    expect(
      () => store.submitPayment(
        tenantId: TenantSession.tenantId,
        invoiceId: invoice.id,
        amount: 1,
        reference: 'REF-4',
        method: 'Tiền mặt',
      ),
      throwsArgumentError,
    );
  });

  test('Tenant cannot pay another lease, cancel a paid invoice, or use disabled methods', () {
    final invoice = newInvoice(store);
    expect(
      () => store.submitPayment(
        tenantId: 'tenant-khoa',
        invoiceId: invoice.id,
        amount: 100,
        reference: 'wrong-tenant',
        method: 'Chuyển khoản',
      ),
      throwsArgumentError,
    );
    store.currentLeaseForTenant(TenantSession.tenantId)!.cashPaymentEnabled =
        false;
    expect(
      () => store.submitPayment(
        tenantId: TenantSession.tenantId,
        invoiceId: invoice.id,
        amount: 100,
        reference: 'cash',
        method: 'Tiền mặt',
      ),
      throwsArgumentError,
    );
    final payment = store.submitPayment(
      tenantId: TenantSession.tenantId,
      invoiceId: invoice.id,
      amount: 100,
      reference: 'bank',
      method: 'Chuyển khoản',
    );
    expect(() => store.approvePayment(payment, 101), throwsArgumentError);
    store.approvePayment(payment, 100);
    expect(() => store.cancelInvoice(invoice), throwsArgumentError);
  });

  test(
    'Issued invoices keep their charges after changing rent and service prices',
    () {
      final invoice = newInvoice(store);
      final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
      saveLease(store, lease, existing: lease, rent: 4000000);
      store.saveService(
        existing: store.serviceById('electricity'),
        name: 'Điện',
        unit: 'kWh',
        basis: 'Theo chỉ số',
        price: 4500,
      );
      expect(invoice.total, 3535000);
      expect(invoice.charges.last.amount, 35000);
      expect(lease.electricityPrice, 3500);
      final duplicatePeriod = invoice.period;
      expect(
        () => store.createInvoice(
          lease: lease,
          period: duplicatePeriod,
          dueDate: invoice.dueDate,
          charges: invoice.charges,
        ),
        throwsArgumentError,
      );
      store.cancelInvoice(invoice);
      final reissued = store.createInvoice(
        lease: lease,
        period: duplicatePeriod,
        dueDate: invoice.dueDate,
        charges: invoice.charges,
      );
      expect(reissued.id, isNot(invoice.id));
      expect(
        store.invoicesForTenant(TenantSession.tenantId),
        contains(invoice),
      );
    },
  );

  test(
    'Approving members updates occupancy and rejection remains available',
    () {
      final member = store.members.firstWhere(
        (member) => member.status == LeaseMemberStatus.pending,
      );
      final lease = store.leaseById(member.leaseId)!;
      store.reviewMember(member, approve: true);
      expect(store.membersForLease(lease.id).length, 2);
      expect(lease.occupantCount, 2);
      expect(store.currentLeaseForTenant(member.tenantId), same(lease));
      expect(
        () => store.reviewMember(member, approve: true),
        throwsArgumentError,
      );
      expect(
        () => saveLease(store, lease, existing: lease, occupants: 3),
        throwsArgumentError,
      );
    },
  );

  test('Member decisions check capacity and require rejection reason', () {
    final member = store.members.firstWhere(
      (member) => member.status == LeaseMemberStatus.pending,
    );
    final lease = store.leaseById(member.leaseId)!;
    // A.302 already has two approved occupants. Moving the request there fills
    // the remaining capacity only after approval; existing occupants cannot be erased.
    expect(
      () => saveLease(store, lease, existing: lease, room: 'A.302'),
      throwsArgumentError,
    );
    expect(
      () => store.reviewMember(member, approve: false),
      throwsArgumentError,
    );
    store.reviewMember(
      member,
      approve: false,
      reason: 'Chưa bổ sung thông tin',
    );
    expect(member.status, LeaseMemberStatus.rejected);
    expect(member.rejectionReason, 'Chưa bổ sung thông tin');
    expect(store.members, contains(member));
    expect(lease.occupantCount, 1);
  });

  test('Tenant incident and landlord progress share the same record', () {
    store.createIncident(
      tenantId: TenantSession.tenantId,
      title: 'Hỏng khóa',
      category: 'Khác',
      description: 'Khóa bị kẹt',
    );
    final incident = store.incidents.first;
    expect(
      store.incidentsForTenant(TenantSession.tenantId),
      contains(incident),
    );
    expect(incident.room, 'A.302');
    store.updateIncident(incident, IncidentStatus.inProgress);
    expect(
      store.incidentsForTenant(TenantSession.tenantId).first.status,
      IncidentStatus.inProgress,
    );
    expect(
      () => store.updateIncident(
        incident,
        IncidentStatus.closed,
        tenantId: TenantSession.tenantId,
      ),
      throwsArgumentError,
    );
    store.updateIncident(incident, IncidentStatus.resolved);
    expect(
      () => store.updateIncident(
        incident,
        IncidentStatus.closed,
        tenantId: 'tenant-other',
      ),
      throwsArgumentError,
    );
    store.updateIncident(
      incident,
      IncidentStatus.newly,
      tenantId: TenantSession.tenantId,
    );
    store.updateIncident(incident, IncidentStatus.resolved);
    store.updateIncident(
      incident,
      IncidentStatus.closed,
      tenantId: TenantSession.tenantId,
    );
    expect(incident.status, IncidentStatus.closed);
  });

  test('Room type and property edits update listings with stable favorite identities', () {
    final before = TenantRoomDemoData.forStore(store)
        .firstWhere((room) => room.roomCode == '102');
    store.saveRoomType('Ban công mới', monthlyRent: 4200000, id: 'balcony');
    store.updateProperty(
      LandlordProperty(
        id: 'may',
        name: 'Mây mới',
        address: 'Địa chỉ mới',
        ownerName: 'Chủ trọ mới',
        phone: '0912345678',
        description: 'Mô tả mới',
        city: 'Hà Nội',
        ward: 'Phường mới',
      ),
    );
    final after = TenantRoomDemoData.forStore(store)
        .firstWhere((room) => room.roomCode == '102');
    expect(after.id, before.id);
    expect(after.propertyId, 'may');
    expect(after.price, 4200000);
    expect(after.address, 'Địa chỉ mới');
    expect(after.city, 'Hà Nội');
    expect(after.ward, 'Phường mới');
    expect(after.description, 'Mô tả mới');
    expect(
      TenantRoomDemoData.forStore(store)
          .where((room) => room.roomCode == 'A.302'),
      isEmpty,
    );
    store.endLease(store.currentLeaseForTenant(TenantSession.tenantId)!);
    expect(
      TenantRoomDemoData.forStore(store)
          .where((room) => room.roomCode == 'A.302'),
      hasLength(1),
    );
  });

  test('Announcements snapshot recipient identity, normalize aliases and persist per-user reads', () {
    final viewings = ViewingStore([]);
    final announcements = AnnouncementStore(rental: store, viewings: viewings);
    addTearDown(announcements.dispose);
    addTearDown(viewings.dispose);
    announcements.send(
      LandlordAnnouncement(
        id: 'draft',
        propertyId: 'may',
        title: 'Nhắc riêng',
        content: 'Phòng 101',
        category: AnnouncementCategory.operations,
        createdAt: DateTime.now(),
        recipients: const ['101'],
      ),
    );
    final sent = announcements.sent.last;
    expect(announcements.forTenant('tenant-khoa'), contains(sent));
    expect(
      announcements.forTenant(TenantSession.tenantId),
      isNot(contains(sent)),
    );
    announcements.markTenantRead(sent.id, 'tenant-khoa');
    expect(announcements.isRead(sent.id, 'tenant-khoa'), isTrue);
    expect(
      () => announcements.markTenantRead(sent.id, TenantSession.tenantId),
      throwsArgumentError,
    );
    store.endLease(store.leaseById('HD-2026-0101')!);
    expect(announcements.forTenant('tenant-khoa'), contains(sent));
    expect(announcements.forTenant('new-tenant'), isEmpty);
    final payment = store.payments.first;
    expect(
      announcements.inbox.any((item) => item.id == 'payment:${payment.id}'),
      isTrue,
    );
    store.rejectPayment(payment, 'Chưa đối soát được');
    expect(
      announcements.inbox.any((item) => item.id == 'payment:${payment.id}'),
      isFalse,
    );
  });

  test(
    'Meter readings are scoped by period and never rewrite existing invoices',
    () {
      final reading = store.readingForRoom('A.302', DateTime(2026, 10))!;
      expect(reading.electricUsage, 126);
      expect(store.readingForRoom('A.302', DateTime(2026, 9)), isNull);
      expect(store.readingForRoom('101', DateTime(2026, 10)), isNotNull);
      final invoice = store.invoicesForTenant(TenantSession.tenantId).single;
      final oldTotal = invoice.total;
      expect(
        () => store.saveReading(
          reading,
          reading.oldElectric - 1,
          reading.oldWater,
        ),
        throwsArgumentError,
      );
      store.saveReading(
        reading,
        reading.oldElectric + 200,
        reading.oldWater + 8,
      );
      expect(reading.electricUsage, 200);
      expect(invoice.total, oldTotal);
    },
  );

  test('Both chat projections use one message stream with independent unread counts', () {
    final source = LandlordConversation(
      id: 'chat',
      tenantId: TenantSession.tenantId,
      leaseId: 'HD-2026-0302',
      tenantName: 'Minh Anh',
      room: 'A.302',
      messages: [],
    );
    final conversations = ConversationStore(records: [source], rental: store);
    addTearDown(conversations.dispose);
    final tenant = TenantConversation.shared(source);
    conversations.send(
      source,
      text: 'Chào chủ trọ',
      time: '10:00',
      fromLandlord: false,
      tenantId: TenantSession.tenantId,
    );
    expect(tenant.messages.last.text, 'Chào chủ trọ');
    expect(tenant.messages.last.fromTenant, isTrue);
    expect(source.unread, 1);
    expect(tenant.unread, 0);
    conversations.markRead(source, landlord: true);
    conversations.send(
      source,
      text: 'Chào bạn',
      time: '10:01',
      fromLandlord: true,
    );
    expect(tenant.messages.last.fromTenant, isFalse);
    expect(tenant.unread, 1);
    conversations.markRead(source, landlord: false);
    expect(source.unread, 0);
    expect(tenant.unread, 0);
    expect(
      () => conversations.send(
        source,
        text: 'Sai người',
        time: '10:02',
        fromLandlord: false,
        tenantId: 'another-tenant',
      ),
      throwsArgumentError,
    );
    saveLease(
      store,
      store.leaseById('HD-2026-0302')!,
      existing: store.leaseById('HD-2026-0302'),
      name: 'Tên mới',
    );
    expect(source.tenantName, 'Tên mới');
  });

  test('Unknown rooms and overlapping future contracts are rejected; renewal retains identity', () {
    final source = store.currentLeaseForTenant(TenantSession.tenantId)!;
    expect(
      () => saveLease(store, source, room: 'ghost', occupants: 1),
      throwsArgumentError,
    );
    final now = DateTime.now();
    saveLease(
      store,
      source,
      room: '102',
      occupants: 1,
      start: now.add(const Duration(days: 400)),
      end: now.add(const Duration(days: 500)),
    );
    final newLease = store.leases.last;
    expect(newLease.tenantId, source.tenantId);
    expect(
      () => saveLease(
        store,
        source,
        room: '102',
        occupants: 1,
        start: now.add(const Duration(days: 450)),
        end: now.add(const Duration(days: 550)),
      ),
      throwsArgumentError,
    );
    expect(
      store.leases.map((lease) => lease.id).toSet().length,
      store.leases.length,
    );
  });

  test('Default bank account changes payment destination while preserving contract snapshot', () {
    final invoice = newInvoice(store);
    final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
    final originalBankNumber = lease.bankAccountNumber;
    final alternative = store.paymentAccounts.last;
    store.setPaymentAccountActive(alternative, true);
    store.setDefaultPaymentAccount(alternative);
    final payment = store.submitPayment(
      tenantId: TenantSession.tenantId,
      invoiceId: invoice.id,
      amount: 1000000,
      reference: 'new-bank',
      method: 'Chuyển khoản',
    );
    expect(payment.paymentAccountId, alternative.id);
    expect(store.defaultPaymentAccount!.accountNumber, '6688990011');
    expect(lease.bankAccountNumber, originalBankNumber);
  });

  test('Viewing uses a stable room ID and rejects rooms rented while request form was open', () {
    final viewings = ViewingStore([], rental: store);
    addTearDown(viewings.dispose);
    final room = TenantRoomDemoData.forStore(store)
        .firstWhere((room) => room.roomCode == '102');
    final time = DateTime.now().add(const Duration(days: 2));
    void request(String name) => viewings.createRequest(
      propertyId: room.propertyId,
      roomId: room.id,
      tenantId: TenantSession.tenantId,
      roomName: name,
      address: room.address,
      startsAt: time,
      customerName: TenantSession.name,
      phone: TenantSession.phone,
      personalNeeds: 'Xem phòng',
      attendeeCount: 1,
    );
    request(room.name);
    expect(() => request('Tên tin đăng đã đổi'), throwsArgumentError);
    final otherTenant = store.leaseById('HD-2026-0101')!;
    store.endLease(otherTenant);
    saveLease(store, otherTenant, room: '102');
    expect(() => request(room.name), throwsArgumentError);
    expect(viewings.records, hasLength(1));
  });

  test('Invoices outside lease term are rejected', () {
    final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
    expect(
      () => store.createInvoice(
        lease: lease,
        period: DateTime(lease.endDate.year + 1, lease.endDate.month),
        dueDate: DateTime(lease.endDate.year + 1, lease.endDate.month, 10),
        charges: const [
          LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: 3500000),
        ],
      ),
      throwsArgumentError,
    );
  });

  testWidgets(
    'Tenant sees pending member decision and rejection reason from landlord',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantMembersPage(store: store, tenantId: 'tenant-bao'),
          ),
        ),
      );
      expect(find.text('Võ Ngọc Lan'), findsOneWidget);
      expect(find.text('Chờ chủ trọ duyệt'), findsOneWidget);
      final member = store.members.firstWhere(
        (member) => member.status == LeaseMemberStatus.pending,
      );
      store.reviewMember(
        member,
        approve: false,
        reason: 'Cần xác nhận thông tin',
      );
      await tester.pump();
      expect(find.text('Đã từ chối'), findsOneWidget);
      expect(find.text('Lý do: Cần xác nhận thông tin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'Lease view reacts to landlord edits and termination at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TenantHomePage(store: store)),
          ),
        );
        expect(find.text('HD-2026-0302'), findsOneWidget);
        expect(
          find.descendant(
            of: find.widgetWithText(TenantLeaseOverviewCard, 'Tiền thuê'),
            matching: find.text('3.500.000 đ'),
          ),
          findsOneWidget,
        );
        expect(find.text('Trần Thu Hà'), findsOneWidget);
        final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
        saveLease(store, lease, existing: lease, rent: 4200000);
        await tester.pump();
        expect(find.text('4.200.000 đ'), findsOneWidget);
        store.endLease(lease);
        await tester.pump();
        expect(find.text('Chưa có hợp đồng đang hiệu lực'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Invoice detail submits payment and reflects landlord review at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final invoice = newInvoice(store);
        await tester.pumpWidget(
          MaterialApp(
            home: TenantInvoiceDetailPage(invoiceId: invoice.id, store: store),
          ),
        );
        expect(find.text('Điện · 10 kWh'), findsOneWidget);
        expect(find.text('35.000 đ'), findsOneWidget);
        final pay = find.widgetWithText(FilledButton, 'Thanh toán hóa đơn');
        await tester.ensureVisible(pay);
        await tester.tap(pay);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).last, 'UI-REF');
        final submit = find.widgetWithText(FilledButton, 'Gửi thanh toán');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        final payment = store.payments.first;
        expect(payment.reference, 'UI-REF');
        expect(invoice.paidAmount, 0);
        expect(find.text('Chờ chủ trọ duyệt'), findsOneWidget);
        store.approvePayment(payment, payment.reportedAmount);
        await tester.pumpAndSettle();
        expect(find.text('Đã thanh toán'), findsOneWidget);
        expect(find.text('0 đ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Landlord incident status reaches tenant and tenant confirmation reaches landlord at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LandlordIncidentsPage(store: store)),
          ),
        );
        await tester.tap(find.text('Máy lạnh không lạnh'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.widgetWithText(ChoiceChip, 'Đã xử lý'),
          ),
        );
        await tester.pumpAndSettle();
        final incident = store.incidents.firstWhere(
          (incident) => incident.id == 'incident-ac',
        );
        expect(incident.status, IncidentStatus.resolved);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TenantIncidentsPage(store: store)),
          ),
        );
        final confirm = find.widgetWithText(FilledButton, 'Xác nhận').first;
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(incident.status, IncidentStatus.closed);
        expect(find.text('Đã đóng'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Tenant receives landlord announcement and read state survives remount at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final viewings = ViewingStore([]);
        final announcements = AnnouncementStore(
          rental: store,
          viewings: viewings,
        );
        addTearDown(announcements.dispose);
        addTearDown(viewings.dispose);
        announcements.send(
          LandlordAnnouncement(
            id: 'draft',
            propertyId: 'may',
            title: 'Thông báo riêng A.302',
            content: 'Kiểm tra phòng chiều nay',
            category: AnnouncementCategory.operations,
            createdAt: DateTime.now(),
            recipients: const ['A.302'],
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TenantAnnouncementsPage(store: announcements)),
          ),
        );
        await tester.tap(find.text('Thông báo riêng A.302'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đóng'));
        await tester.pumpAndSettle();
        expect(
          announcements.isRead(
            announcements.sent.last.id,
            TenantSession.tenantId,
          ),
          isTrue,
        );
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TenantAnnouncementsPage(store: announcements)),
          ),
        );
        await tester.tap(find.widgetWithText(ChoiceChip, 'Chưa đọc (4)'));
        await tester.pumpAndSettle();
        expect(find.text('Thông báo riêng A.302'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
