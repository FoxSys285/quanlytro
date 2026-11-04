import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/landlord/announcements/models/landlord_announcement.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';
import 'package:quanlytro/pages/tenant/announcements/components/tenant_announcement_card.dart';
import 'package:quanlytro/pages/tenant/announcements/tenant_announcements_page.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_danhsachtinnhan_page.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_tinnhan_page.dart';
import 'package:quanlytro/pages/tenant/conversations/models/tenant_cuoctrochuyen.dart';

void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('Announcement filters, details and read state at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rental = LandlordDemoStore.demo();
      final viewings = ViewingStore([]);
      final store = AnnouncementStore(rental: rental, viewings: viewings);
      addTearDown(store.dispose);
      addTearDown(viewings.dispose);
      addTearDown(rental.dispose);
      for (final item in store.forTenant(TenantSession.tenantId)) {
        store.markTenantRead(item.id, TenantSession.tenantId);
      }
      const title =
          'Thông báo quan trọng về thời gian thanh toán và điều chỉnh lịch kiểm tra phòng';
      final content = List.filled(
        12,
        'Vui lòng kiểm tra thông tin thanh toán và liên hệ chủ trọ khi cần hỗ trợ.',
      ).join('\n');
      store.send(
        LandlordAnnouncement(
          id: 'draft',
          propertyId: rental.property.id,
          title: title,
          content: content,
          category: AnnouncementCategory.finance,
          priority: AnnouncementPriority.high,
          createdAt: DateTime(2026, 11, 4),
          recipients: const ['A.302'],
        ),
      );
      final announcement = store.sent.last;
      Widget app({String tenantId = TenantSession.tenantId}) => MaterialApp(
        home: Scaffold(
          body: TenantAnnouncementsPage(store: store, tenantId: tenantId),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chưa đọc (1)'));
      await tester.pumpAndSettle();
      expect(find.byType(TenantAnnouncementCard), findsOneWidget);
      expect(find.text('Quan trọng'), findsOneWidget);
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(content), findsOneWidget);
      expect(store.isRead(announcement.id, TenantSession.tenantId), isTrue);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đã đọc hết thông báo'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
      await tester.pumpAndSettle();
      expect(
        find.byType(TenantAnnouncementCard),
        findsNWidgets(store.forTenant(TenantSession.tenantId).length),
      );
      expect(
        tester
            .widget<TenantAnnouncementCard>(
              find.byKey(ValueKey(announcement.id)),
            )
            .isRead,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(tenantId: 'tenant-without-notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có thông báo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Unread chat filter, suggestions and keyboard preserve message sending',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final conversations = TenantConversation.demoConversations;
      final originalUnread = conversations.map((item) => item.unread).toList();
      final target = conversations.first.source!;
      final originalMessages = target.messages.toList();
      final originalLandlordUnread = target.unread;
      addTearDown(() {
        for (var i = 0; i < conversations.length; i++) {
          conversations[i].unread = originalUnread[i];
        }
        target.messages
          ..clear()
          ..addAll(originalMessages);
        target.unread = originalLandlordUnread;
      });
      for (final item in conversations) {
        item.unread = 0;
      }
      conversations.first.unread = 2;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TenantDanhSachTinNhanPage())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chưa đọc (1)'));
      await tester.pumpAndSettle();
      expect(find.text(conversations.first.landlordName), findsOneWidget);
      await tester.ensureVisible(find.text(conversations.first.landlordName));
      await tester.tap(find.text(conversations.first.landlordName));
      await tester.pumpAndSettle();
      expect(target.tenantUnread, 0);
      await tester.tap(find.byTooltip('Tin nhắn gợi ý'));
      await tester.pumpAndSettle();
      const suggestion = 'Tôi đã thanh toán, nhờ chủ trọ kiểm tra giúp.';
      await tester.ensureVisible(find.text(suggestion));
      await tester.tap(find.text(suggestion));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        suggestion,
      );
      expect(target.messages.length, originalMessages.length);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byTooltip('Gửi tin nhắn')).bottom,
        lessThanOrEqualTo(380),
      );
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(target.messages.last.text, suggestion);
      ConversationStore.instance.send(
        target,
        text: 'Chủ trọ đã nhận thông tin.',
        time: '10:30',
        fromLandlord: true,
      );
      await tester.pumpAndSettle();
      expect(target.tenantUnread, 0);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thông tin cuộc trò chuyện'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Bạn đã đọc hết tin nhắn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Navigation badges update when a conversation is read', (
    tester,
  ) async {
    final conversations = TenantConversation.demoConversations;
    final originalUnread = conversations.map((item) => item.unread).toList();
    addTearDown(() {
      for (var i = 0; i < conversations.length; i++) {
        conversations[i].unread = originalUnread[i];
      }
    });
    for (final item in conversations) {
      item.unread = 0;
    }
    conversations.first.unread = 2;
    await tester.pumpWidget(const MaterialApp(home: TenantLayout()));
    await tester.tap(find.byIcon(Icons.forum_outlined));
    await tester.pumpAndSettle();
    final badge = find.byKey(
      const ValueKey('tenant-conversations-unread-badge'),
    );
    expect(
      find.descendant(of: badge, matching: find.text('2')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text(conversations.first.landlordName));
    await tester.tap(find.text(conversations.first.landlordName));
    await tester.pumpAndSettle();
    expect(find.byType(TenantTinNhanPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(badge, findsNothing);
    final notifications = AnnouncementStore.instance
        .forTenant(TenantSession.currentTenantId)
        .where(
          (item) => !AnnouncementStore.instance.isRead(
            item.id,
            TenantSession.currentTenantId,
          ),
        )
        .length;
    final notificationBadge = find.byKey(
      const ValueKey('tenant-announcements-unread-badge'),
    );
    if (notifications > 0) {
      expect(
        find.descendant(
          of: notificationBadge,
          matching: find.text('$notifications'),
        ),
        findsOneWidget,
      );
    } else {
      expect(notificationBadge, findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
