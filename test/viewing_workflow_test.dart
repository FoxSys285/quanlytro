import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/landlord/conversations/landlord_chat_page.dart';
import 'package:quanlytro/pages/landlord/viewings/data/viewing_conversation_store.dart';
import 'package:quanlytro/pages/landlord/viewings/landlord_viewings_page.dart';
import 'package:quanlytro/pages/shared/viewings/components/viewing_status_badge.dart';
import 'package:quanlytro/pages/shared/viewings/models/room_viewing.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';
import 'package:quanlytro/pages/tenant/viewings/components/tenant_viewing_card.dart';
import 'package:quanlytro/pages/tenant/viewings/tenant_viewings_page.dart';

void main() {
  test(
    'Store scopes records and prevents reopening a cancelled appointment',
    () {
      final store = ViewingStore.demo(referenceDate: DateTime(2026, 12, 31));
      addTearDown(store.dispose);
      expect(
        store.forTenant(ViewingStore.demoTenantId).map((item) => item.id),
        ['viewing-demo-1', 'viewing-demo-5', 'viewing-demo-0'],
      );
      expect(store.forTenant('another-tenant'), isEmpty);
      expect(store.forProperty('another-house'), isEmpty);
      expect(
        store.confirm('viewing-demo-1', propertyId: 'another-house'),
        isFalse,
      );
      expect(store.confirm('viewing-demo-1', propertyId: 'may'), isTrue);
      expect(store.confirm('viewing-demo-1', propertyId: 'may'), isFalse);
      expect(store.cancel('viewing-demo-1', propertyId: 'may'), isTrue);
      expect(store.confirm('viewing-demo-1', propertyId: 'may'), isFalse);
      expect(store.cancel('viewing-demo-1', propertyId: 'may'), isFalse);
    },
  );

  testWidgets('Tenant menu opens the real viewing page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TenantLayout()));
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch xem phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(TenantViewingsPage), findsOneWidget);
    expect(find.byType(TenantViewingCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'Tenant own bookings, dates, statuses and filtering at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = ViewingStore.demo(referenceDate: DateTime(2026, 12, 31));
        addTearDown(store.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TenantViewingsPage(store: store)),
          ),
        );
        final cards = tester
            .widgetList<TenantViewingCard>(find.byType(TenantViewingCard))
            .toList();
        expect(cards.map((card) => card.viewing.id), [
          'viewing-demo-1',
          'viewing-demo-5',
          'viewing-demo-0',
        ]);
        expect(
          cards.map((card) => card.viewing.status).toSet(),
          ViewingStatus.values.toSet(),
        );
        expect(find.text('Thứ Sáu, 01/01/2027'), findsNWidgets(2));
        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('09:30'), findsOneWidget);
        expect(find.text('14:30'), findsOneWidget);
        await tester.tap(find.widgetWithText(ChoiceChip, 'Đã hủy'));
        await tester.pumpAndSettle();
        expect(find.byType(TenantViewingCard), findsOneWidget);
        expect(
          tester
              .widget<TenantViewingCard>(find.byType(TenantViewingCard))
              .viewing
              .id,
          'viewing-demo-5',
        );
        await tester.enterText(find.byType(TextField), 'không tồn tại');
        await tester.pumpAndSettle();
        expect(find.text('Chưa có lịch xem phòng phù hợp.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Landlord confirm, cancel, chat and tenant status sync at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = ViewingStore.demo(referenceDate: DateTime(2026, 12, 31));
        final conversations = ViewingConversationStore();
        addTearDown(store.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LandlordViewingsPage(
                store: store,
                conversations: conversations,
              ),
            ),
          ),
        );
        final card = find.byKey(const ValueKey('viewing-demo-1'));
        final confirm = find.descendant(
          of: card,
          matching: find.widgetWithText(FilledButton, 'Xác nhận lịch'),
        );
        final cancel = find.descendant(
          of: card,
          matching: find.widgetWithText(OutlinedButton, 'Hủy lịch'),
        );
        final message = find.descendant(
          of: card,
          matching: find.widgetWithText(OutlinedButton, 'Nhắn tin'),
        );
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(
          store.records
              .firstWhere((item) => item.id == 'viewing-demo-1')
              .status,
          ViewingStatus.confirmed,
        );
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Giữ lịch'));
        await tester.pumpAndSettle();
        expect(
          store.records
              .firstWhere((item) => item.id == 'viewing-demo-1')
              .status,
          ViewingStatus.confirmed,
        );
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Hủy lịch'));
        await tester.pumpAndSettle();
        expect(
          store.records
              .firstWhere((item) => item.id == 'viewing-demo-1')
              .status,
          ViewingStatus.cancelled,
        );
        expect(tester.widget<OutlinedButton>(cancel).onPressed, isNull);
        await tester.ensureVisible(message);
        await tester.tap(message);
        await tester.pumpAndSettle();
        expect(find.byType(LandlordChatPage), findsOneWidget);
        expect(conversations.conversations.single.tenantName, 'Trần Hoàng Nam');
        await tester.enterText(
          find.byType(TextField),
          'Bạn có thể chọn lịch khác nhé.',
        );
        await tester.tap(find.byTooltip('Gửi tin nhắn'));
        await tester.pumpAndSettle();
        expect(
          conversations.conversations.single.messages.last.text,
          'Bạn có thể chọn lịch khác nhé.',
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.ensureVisible(message);
        await tester.tap(message);
        await tester.pumpAndSettle();
        expect(find.text('Bạn có thể chọn lịch khác nhé.'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TenantViewingsPage(store: store)),
          ),
        );
        await tester.pumpAndSettle();
        final tenantCard = find.byKey(const ValueKey('viewing-demo-1'));
        expect(
          tester
              .widget<ViewingStatusBadge>(
                find.descendant(
                  of: tenantCard,
                  matching: find.byType(ViewingStatusBadge),
                ),
              )
              .status,
          ViewingStatus.cancelled,
        );
        expect(find.byType(TenantViewingCard), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
