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
  }) => store.forRoom(
    propertyId: propertyId,
    roomId: roomId,
    roomName: roomName,
    landlordName: 'Chủ trọ',
    propertyName: 'Nhà trọ',
    tenantId: tenantId,
    tenantName: 'Người thuê',
  );

  test(
    'Room chats reuse history and stay scoped to property, room and tenant',
    () {
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
      expect(open(propertyId: 'another-property'), isNot(same(source)));
      expect(open(tenantId: 'another-tenant'), isNot(same(source)));
      expect(open(roomId: '102'), isNot(same(source)));
      expect(store.conversations, hasLength(4));
      expect(store.forProperty('may'), hasLength(3));
      expect(store.forTenant('another-tenant'), hasLength(1));

      final adapter = TenantConversation.forSource(source);
      expect(TenantConversation.forSource(source), same(adapter));
      final restored = ConversationStore(rental: rental)
        ..restore(store.toMap());
      addTearDown(restored.dispose);
      final restoredSource = restored.conversations.firstWhere(
        (c) => c.id == source.id,
      );
      expect(restoredSource.messages.single.text, 'Hỏi về phòng');
      expect(
        TenantConversation.forSource(restoredSource).source,
        same(restoredSource),
      );
      expect(
        TenantConversation.forSource(restoredSource),
        isNot(same(adapter)),
      );
    },
  );

  test('Room action reuses a viewing conversation for the same tenant and property', () {
    final viewing = store.getOrCreate(
      LandlordConversation(
        id: 'viewing:may:tenant-demo:may:101',
        propertyId: 'may',
        tenantId: 'tenant-demo',
        tenantName: 'Người thuê',
        room: 'Phòng 101',
        messages: [],
      ),
    );
    expect(open(), same(viewing));
    expect(open(tenantId: 'another-tenant'), isNot(same(viewing)));
    expect(open(propertyId: 'another-property'), isNot(same(viewing)));
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
