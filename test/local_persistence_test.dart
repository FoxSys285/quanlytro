import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';
import 'package:quanlytro/pages/landlord/rooms/models/landlord_room.dart';
import 'package:quanlytro/pages/shared/rental/lease_member.dart';
import 'package:quanlytro/pages/shared/profile/account_store.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_favorites_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('Seed has ten coherent properties and 454 rooms at requested scale', () {
    final portfolio = RentalPortfolio.seeded();
    addTearDown(portfolio.dispose);
    expect(portfolio.stores, hasLength(10));
    expect(portfolio.stores.fold<int>(0, (n, s) => n + s.catalog.length), 454);
    for (final store in portfolio.stores) {
      expect(store.roomTypes.length, inInclusiveRange(3, 4));
      final floors = store.catalog.map((r) => r.floor).toSet();
      expect(floors.length, inInclusiveRange(3, 8));
      for (final floor in floors) {
        expect(
          store.catalog.where((r) => r.floor == floor).length,
          inInclusiveRange(6, 12),
        );
      }
      expect(
        store.catalog.map((r) => store.canonicalRoom(r.code)).toSet().length,
        store.catalog.length,
      );
      for (final room in store.catalog) {
        expect(store.roomTypes.any((t) => t.id == room.roomTypeId), isTrue);
      }
      for (final lease in store.leases) {
        expect(lease.propertyId, store.property.id);
        expect(store.roomByCode(lease.room), isNotNull);
        expect(lease.isCurrent, isTrue);
        expect(lease.occupantCount, store.membersForLease(lease.id).length);
      }
      for (final invoice in store.invoices) {
        expect(store.leaseById(invoice.leaseId), isNotNull);
      }
    }
  });

  test('Rooms and catalogue changes remain isolated between properties', () {
    final portfolio = RentalPortfolio.seeded();
    addTearDown(portfolio.dispose);
    final first = portfolio.active;
    final second = portfolio.stores[1];
    portfolio.select(second.property.id);
    second.saveRoomType('Studio nâng cấp', monthlyRent: 4500000, id: 'studio');
    expect(first.roomTypes.first.name, 'Studio');
    final room = second.roomDetails
        .firstWhere((r) => r.status == LandlordRoomStatus.vacant)
        .room;
    second.saveRoom(
      LandlordRoom(
        code: room.code,
        floor: room.floor,
        roomTypeId: 'studio',
        area: 35,
        capacity: 4,
      ),
      existingCode: room.code,
    );
    expect(second.roomByCode(room.code)!.area, 35);
    expect(() => second.saveRoom(room), throwsArgumentError);
    final occupied = second.activeLeases.first.room;
    expect(() => second.deleteRoom(occupied), throwsArgumentError);
    final restored = RentalPortfolio.fromMap(
      jsonDecode(jsonEncode(portfolio.toMap())) as Map<String, dynamic>,
    );
    addTearDown(restored.dispose);
    expect(restored.active.property.id, second.property.id);
    expect(restored.toMap(), portfolio.toMap());
  });

  test('SQLite file reopen preserves images, approved payments, members and readings', () async {
    final directory = await Directory.systemTemp.createTemp(
      'quanlytro-sqlite-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/rental.db';
    final portfolio = RentalPortfolio.seeded();
    addTearDown(portfolio.dispose);
    final store = portfolio.active;
    final property = store.property.toMap();
    property['imageBytes'] = [10, 20, 30, 40];
    property['imageName'] = 'nha-tro.png';
    store.updateProperty(LandlordProperty.fromMap(property));
    final payment = store.payments.first;
    store.approvePayment(payment, payment.reportedAmount);
    store.requestMember(
      tenantId: 'tenant-demo',
      name: 'Nguyễn Hà My',
      phone: '0912345688',
    );
    final member = store.members.firstWhere((m) => m.name == 'Nguyễn Hà My');
    store.reviewMember(member, approve: true);
    final next = DateTime(DateTime.now().year, DateTime.now().month + 1);
    store.prepareReadings(next);
    final reading = store.readingsForPeriod(next).first;
    store.saveReading(reading, reading.oldElectric + 99, reading.oldWater + 5);
    var repository = await SqliteRentalRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    await repository.saveAll({'portfolio': portfolio.toMap()});
    await repository.close();
    repository = await SqliteRentalRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final saved = await repository.readAll();
    await repository.close();
    final restored = RentalPortfolio.fromMap(saved['portfolio']!);
    addTearDown(restored.dispose);
    expect(restored.toMap(), portfolio.toMap());
    expect(
      restored.active.property.imageBytes,
      Uint8List.fromList([10, 20, 30, 40]),
    );
    expect(restored.active.payments.first.reviewedAt, isNotNull);
    expect(
      restored.active.members
          .firstWhere((m) => m.name == 'Nguyễn Hà My')
          .status,
      LeaseMemberStatus.active,
    );
    expect(restored.active.readingsForPeriod(next).first.electricUsage, 99);
  });

  test('Application autosaves notifications, favorites, active property and new rooms', () async {
    final directory = await Directory.systemTemp.createTemp('quanlytro-app-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/app.db';
    var repository = await SqliteRentalRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var persistence = AppPersistence(repository);
    await persistence.initialize();
    addTearDown(() => persistence.dispose());
    final portfolio = RentalPortfolio.instance;
    final second = portfolio.stores[1];
    portfolio.select(second.property.id);
    second.saveRoom(
      const LandlordRoom(
        code: '901',
        floor: 9,
        roomTypeId: 'studio',
        area: 25,
        capacity: 2,
      ),
    );
    AccountStore.instance.setNotificationsEnabled(AppRole.tenant, false);
    TenantFavoritesStore.toggle('property-2:102');
    final announcement = AnnouncementStore.instance
        .forTenant('tenant-demo')
        .first;
    AnnouncementStore.instance.markTenantRead(announcement.id, 'tenant-demo');
    final conversation = ConversationStore.instance.conversations.first;
    ConversationStore.instance.send(
      conversation,
      text: 'Tin nhắn lưu SQLite',
      time: '10:30',
      fromLandlord: false,
    );
    final viewing = ViewingStore.instance.records.first;
    ViewingStore.instance.confirm(viewing.id, propertyId: viewing.propertyId);
    AdminStore.instance.submitTicket(
      AppRole.tenant,
      'Kiểm tra dữ liệu',
      'Cần hỗ trợ kiểm tra dữ liệu lưu trên thiết bị.',
    );
    await persistence.flush();
    final saved = await repository.readAll();
    final restored = RentalPortfolio.fromMap(saved['portfolio']!);
    addTearDown(restored.dispose);
    expect(restored.active.property.id, second.property.id);
    expect(restored.active.roomByCode('901'), isNotNull);
    expect((saved['accounts']!['notifications'] as Map)['tenant'], false);
    expect(saved['favorites']!['ids'], contains('property-2:102'));
    expect(saved['auth']!['credentials'], isNotEmpty);
    expect(persistence.error.value, isNull);
    await persistence.dispose();
    repository = await SqliteRentalRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    persistence = AppPersistence(repository);
    await persistence.initialize();
    expect(RentalPortfolio.instance.active.property.id, second.property.id);
    expect(RentalPortfolio.instance.active.catalog, hasLength(19));
    expect(RentalPortfolio.instance.stores, hasLength(10));
    expect(AccountStore.instance.notificationsEnabled(AppRole.tenant), false);
    expect(TenantFavoritesStore.contains('property-2:102'), true);
    expect(
      AnnouncementStore.instance.isRead(announcement.id, 'tenant-demo'),
      true,
    );
    expect(
      ConversationStore.instance.conversations.first.messages.last.text,
      'Tin nhắn lưu SQLite',
    );
    expect(ViewingStore.instance.records.first.status.name, 'confirmed');
    expect(AdminStore.instance.tickets.last.title, 'Kiểm tra dữ liệu');
  });
}
