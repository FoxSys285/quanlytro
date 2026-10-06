import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/tenant/conversations/models/tenant_conversation.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_conversation_page.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_conversations_page.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('Tenant conversation list, search and chat at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final conversations = TenantConversation.demoConversations;
      final originalUnread = conversations.map((item) => item.unread).toList();
      final originalLengths = conversations
          .map((item) => item.messages.length)
          .toList();
      addTearDown(() {
        for (var i = 0; i < conversations.length; i++) {
          conversations[i].unread = originalUnread[i];
          conversations[i].messages.length = originalLengths[i];
        }
      });

      await tester.pumpWidget(const MaterialApp(home: TenantLayout()));
      await tester.tap(find.byIcon(Icons.forum_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(TenantConversationsPage), findsOneWidget);
      expect(find.byType(TenantLandlordConversationPage), findsNothing);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Trần Thị Mai'), findsOneWidget);
      expect(find.text('Lê Minh Hùng'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'không tồn tại');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy cuộc trò chuyện'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  HOA MAI  ');
      await tester.pumpAndSettle();
      expect(find.text('Trần Thị Mai'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsNothing);
      await tester.tap(find.text('Trần Thị Mai'));
      await tester.pumpAndSettle();
      expect(find.byType(TenantLandlordConversationPage), findsOneWidget);
      expect(find.text('Trần Thị Mai'), findsOneWidget);
      expect(conversations[1].unread, 0);
      expect(find.text('Bạn báo cô giờ đến để cô mở cửa nhé.'), findsOneWidget);

      final originalCount = conversations[1].messages.length;
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(conversations[1].messages.length, originalCount);
      await tester.enterText(
        find.byType(TextField),
        '  Em đến lúc 15 giờ ạ.  ',
      );
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(conversations[1].messages.last.text, 'Em đến lúc 15 giờ ạ.');
      expect(conversations[0].messages.length, originalLengths[0]);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Bạn: Em đến lúc 15 giờ ạ.'), findsOneWidget);

      // Leaving the tab must preserve the conversation and its sent messages.
      await tester.tap(find.byIcon(Icons.search_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.forum_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Bạn: Em đến lúc 15 giờ ạ.'), findsOneWidget);
      await tester.tap(find.text('Trần Thị Mai'));
      await tester.pumpAndSettle();
      expect(find.text('Em đến lúc 15 giờ ạ.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
