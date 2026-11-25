import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/conversations/landlord_danhsachtinnhan_page.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_cuoctrochuyen.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/tenant/conversations/models/tenant_cuoctrochuyen.dart';

void main() {
  late LandlordDemoStore rental;
  late ConversationStore store;

  setUp(() {
    rental = LandlordDemoStore.demo();
    store = ConversationStore(rental: rental);
  });
  tearDown(() {
    store.dispose();
    rental.dispose();
  });

  LandlordConversation open({
    String propertyId = 'may',
    String roomId = '101',
    String roomName = 'Phòng 101',
    String tenantId = 'tenant-demo',
    String ownerUid = 'owner-a',
  }) => store.forRoom(
    propertyId: propertyId,
    roomId: roomId,
    roomName: roomName,
    landlordName: 'Chủ trọ',
    propertyName: 'Nhà trọ',
    tenantId: tenantId,
    tenantName: 'Người thuê',
    ownerUid: ownerUid,
  );

  test('one owner and tenant share a thread across rooms while other owners stay separate', () {
    final source = open();
    expect(source.messages, isEmpty);
    store.send(
      source,
      text: 'Hỏi về phòng',
      time: '10:00',
      fromLandlord: false,
    );
    expect(open(roomName: 'Tên phòng mới'), same(source));
    expect(source.messages.single.text, 'Hỏi về phòng');
    expect(open(propertyId: 'another-property'), same(source));
    expect(open(roomId: '102'), same(source));
    expect(open(tenantId: 'another-tenant'), isNot(same(source)));
    expect(
      open(propertyId: 'another-property', ownerUid: 'owner-b'),
      isNot(same(source)),
    );
    expect(store.conversations, hasLength(3));
    expect(store.forProperty('may'), contains(source));
    expect(store.forProperty('another-property'), contains(source));
    expect(store.forTenant('another-tenant'), hasLength(1));

    final adapter = TenantConversation.forSource(source);
    expect(TenantConversation.forSource(source), same(adapter));
    final restored = ConversationStore(rental: rental)..restore(store.toMap());
    addTearDown(restored.dispose);
    final restoredSource = restored.conversations.firstWhere(
      (c) => c.id == source.id,
    );
    expect(restoredSource.messages.single.text, 'Hỏi về phòng');
    expect(
      TenantConversation.forSource(restoredSource).source,
      same(restoredSource),
    );
    expect(TenantConversation.forSource(restoredSource), isNot(same(adapter)));
  });

  test(
    'Room action reuses a viewing conversation for the same owner and tenant',
    () {
      final viewing = store.getOrCreate(
        LandlordConversation(
          id: 'viewing:may:tenant-demo:may:101',
          propertyId: 'may',
          ownerUid: 'owner-a',
          tenantId: 'tenant-demo',
          tenantName: 'Người thuê',
          room: 'Phòng 101',
          messages: [],
        ),
      );
      expect(open(), same(viewing));
      expect(open(tenantId: 'another-tenant'), isNot(same(viewing)));
      expect(open(propertyId: 'another-property'), same(viewing));
    },
  );

  test('legacy duplicate threads merge by owner and tenant without duplicate messages', () {
    final restored = ConversationStore(rental: rental);
    addTearDown(restored.dispose);
    restored.restore({
      'records': [
        LandlordConversation(
          id: 'room:may:tenant-demo:101',
          propertyId: 'may',
          ownerUid: 'owner-a',
          tenantId: 'tenant-demo',
          tenantName: 'Người thuê',
          landlordName: 'Chủ trọ',
          propertyName: 'Nhà A',
          room: '101',
          unread: 2,
          messages: [
            LandlordMessage(
              id: 'same-message',
              text: 'Chào chủ trọ',
              time: '10:00',
              fromLandlord: false,
              createdAt: DateTime.utc(2026, 1, 1, 3),
            ),
          ],
        ).toMap(),
        LandlordConversation(
          id: 'viewing:other:tenant-demo:102',
          propertyId: 'other',
          ownerUid: 'owner-a',
          tenantId: 'tenant-demo',
          tenantName: 'Người thuê',
          landlordName: 'Chủ trọ',
          propertyName: 'Nhà B',
          room: '102',
          unread: 3,
          messages: [
            LandlordMessage(
              id: 'same-message',
              text: 'Chào chủ trọ',
              time: '10:00',
              fromLandlord: false,
              createdAt: DateTime.utc(2026, 1, 1, 3),
            ),
            LandlordMessage(
              id: 'second-message',
              text: 'Còn phòng 102 không?',
              time: '10:15',
              fromLandlord: false,
              createdAt: DateTime.utc(2026, 1, 1, 3, 15),
            ),
          ],
        ).toMap(),
      ],
    });
    expect(restored.conversations, hasLength(1));
    final thread = restored.conversations.single;
    expect(thread.id, ConversationStore.canonicalId('owner-a', 'tenant-demo'));
    expect(thread.messages.map((message) => message.id), [
      'same-message',
      'second-message',
    ]);
    expect(thread.unread, 3);
  });

  testWidgets(
    'Landlord inbox renders a room conversation before its first message',
    (tester) async {
      final previous = ConversationStore.instance;
      ConversationStore.instance = store;
      addTearDown(() => ConversationStore.instance = previous);
      open(propertyId: LandlordDemoStore.activeInstance.property.id);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LandlordDanhSachTinNhanPage())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa có tin nhắn'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
