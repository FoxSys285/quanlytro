import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';
import 'package:quanlytro/pages/landlord/rooms/models/landlord_room.dart';
import 'package:quanlytro/pages/shared/media/room_photo.dart';
import 'package:quanlytro/pages/shared/viewings/models/room_viewing.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';

void main() {
  test(
    'Demo supplement is repeatable, diverse and preserves custom images',
    () {
      final portfolio = RentalPortfolio.seeded();
      addTearDown(portfolio.dispose);
      final before = jsonEncode(portfolio.toMap());
      portfolio.supplementDemoActivity();
      expect(jsonEncode(portfolio.toMap()), before);
      expect(
        portfolio.stores.map((s) => s.property.imageUrl).toSet(),
        hasLength(10),
      );
      expect(
        portfolio.stores.map((s) => s.property.description).toSet(),
        hasLength(10),
      );
      expect(
        portfolio.stores.map((s) => s.roomTypes.first.monthlyRent).toSet(),
        hasLength(10),
      );
      for (final store in portfolio.stores) {
        expect(store.property.amenities, isNotEmpty);
        expect(store.leases.any((l) => l.isExpiringSoon), isTrue);
        expect(
          store.invoices.map((v) => v.status),
          containsAll([
            LandlordInvoiceStatus.partial,
            LandlordInvoiceStatus.overdue,
          ]),
        );
        expect(
          store.payments.map((p) => p.status),
          containsAll(LandlordPaymentStatus.values),
        );
        for (final type in store.roomTypes) {
          expect(type.photos.length, inInclusiveRange(2, 4));
          for (final photo in type.photos) {
            expect(File(photo.assetPath).existsSync(), isTrue);
          }
        }
        for (final invoice in store.invoices) {
          final lease = store.leaseById(invoice.leaseId)!;
          expect(invoice.room, lease.room);
          expect(invoice.paidAmount, inInclusiveRange(0, invoice.total));
        }
        for (final payment in store.payments) {
          final invoice = store.invoiceById(payment.invoiceId)!;
          expect(payment.room, invoice.room);
          if (payment.status == LandlordPaymentStatus.approved) {
            expect(
              payment.approvedAmount,
              lessThanOrEqualTo(invoice.paidAmount),
            );
          }
        }
      }
      final store = portfolio.stores.first;
      store.updateProperty(
        LandlordProperty.fromMap({
          ...store.property.toMap(),
          'imageUrl': 'https://example.com/my-room.jpg',
          'imageBytes': [1, 2, 3],
          'amenities': ['Tiện ích riêng'],
        }),
      );
      portfolio.supplementDemoActivity();
      expect(store.property.imageBytes, Uint8List.fromList([1, 2, 3]));
      expect(store.property.imageUrl, 'https://example.com/my-room.jpg');
      expect(store.property.amenities, ['Tiện ích riêng']);
      final legacy = store.property.toMap()..remove('amenities');
      expect(LandlordProperty.fromMap(legacy).amenities, isEmpty);
      final photos = Directory('assets/images/room_types')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.webp'));
      expect(photos.length, greaterThanOrEqualTo(18));
      expect(
        photos.fold<int>(0, (sum, f) => sum + f.lengthSync()),
        lessThan(1024 * 1024),
      );
      expect(RoomPhoto.demoForType('studio'), hasLength(2));
    },
  );

  test(
    'Find → confirm viewing → lease → invoice → proof → approve persists',
    () {
      final portfolio = RentalPortfolio.seeded();
      addTearDown(portfolio.dispose);
      final store = portfolio.stores[2];
      final listing = TenantRoomDemoData.forStore(store).first;
      final viewings = ViewingStore([], rental: store);
      addTearDown(viewings.dispose);
      const tenantId = 'demo-full-workflow-tenant';
      final now = DateTime.now();
      final viewing = viewings.createRequest(
        propertyId: store.property.id,
        tenantId: tenantId,
        roomId: listing.id,
        roomName: listing.name,
        address: listing.address,
        startsAt: now.add(const Duration(days: 1)),
        customerName: 'Lê Minh Chi',
        phone: '0900000088',
        personalNeeds: 'Cần phòng yên tĩnh.',
        attendeeCount: 1,
      );
      expect(
        viewings.confirm(viewing.id, propertyId: store.property.id),
        isTrue,
      );
      expect(
        viewings.forTenant(tenantId).single.status,
        ViewingStatus.confirmed,
      );
      final source = store.leases.first;
      store.saveLease(
        room: listing.roomCode!,
        tenantId: tenantId,
        landlordName: source.landlordName,
        landlordPermanentAddress: source.landlordPermanentAddress,
        landlordCitizenId: source.landlordCitizenId,
        landlordContact: source.landlordContact,
        tenantName: viewing.customerName,
        tenantBirthYear: '2004',
        tenantCitizenId: '079000000088',
        tenantCitizenIssueDate: DateTime(2022, 1, 1),
        tenantPermanentAddress: 'TP. Hồ Chí Minh',
        phone: viewing.phone,
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year + 1, now.month, now.day),
        monthlyRent: listing.price,
        deposit: listing.price,
        termMonths: 12,
        electricityPrice: 4000,
        waterPrice: 15000,
        waterType: 'Theo m³',
        vehicleFee: 80000,
        serviceFee: 100000,
        dueDay: 10,
        cashPaymentEnabled: true,
        cashPaymentLocation: store.property.address,
        bankTransferEnabled: true,
        bankName: 'Vietcombank',
        bankAccountNumber: '0123456789',
        occupantCount: 1,
        note: 'Kiểm chứng luồng đầy đủ',
        status: LandlordLeaseStatus.active,
      );
      final lease = store.currentLeaseForTenant(tenantId)!;
      expect(lease.propertyId, listing.propertyId);
      expect(
        store.roomDetails
            .firstWhere((r) => r.room.code == listing.roomCode)
            .status,
        LandlordRoomStatus.occupied,
      );
      expect(
        TenantRoomDemoData.forStore(store).any((r) => r.id == listing.id),
        isFalse,
      );
      final invoice = store.createInvoice(
        lease: lease,
        period: DateTime(now.year, now.month),
        dueDate: now.add(const Duration(days: 7)),
        charges: [
          LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: listing.price),
          const LandlordInvoiceCharge(name: 'Internet', amount: 100000),
        ],
      );
      final proof = File('assets/images/room_types/studio.webp')
          .readAsBytesSync();
      final payment = store.submitPayment(
        tenantId: tenantId,
        invoiceId: invoice.id,
        amount: invoice.total,
        reference: 'DEMO-FULL-FLOW',
        method: 'Chuyển khoản',
        proofBytes: proof,
        proofName: 'minh-chung-mau.webp',
      );
      expect(payment.status, LandlordPaymentStatus.pending);
      expect(invoice.paidAmount, 0);
      store.approvePayment(payment, payment.reportedAmount);
      expect(invoice.status, LandlordInvoiceStatus.paid);
      expect(invoice.remaining, 0);
      final restored = RentalPortfolio.fromMap(
        jsonDecode(jsonEncode(portfolio.toMap())),
      );
      addTearDown(restored.dispose);
      final saved = restored.byId(store.property.id)!;
      expect(saved.currentLeaseForTenant(tenantId)!.id, lease.id);
      expect(
        saved.invoicesForTenant(tenantId).single.status,
        LandlordInvoiceStatus.paid,
      );
      final savedPayment = saved.payments.firstWhere((p) => p.id == payment.id);
      expect(savedPayment.status, LandlordPaymentStatus.approved);
      expect(savedPayment.proofBytes, proof);
      expect(savedPayment.invoiceId, invoice.id);
    },
  );
}
