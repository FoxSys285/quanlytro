import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/tenant/conversations/components/tenant_conversation_card.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_danhsachtinnhan_page.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_tinnhan_page.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_details_page.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_details_sheet.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/tenant_page_router.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets(
      'Room chat shares history and design with the bottom tab at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final originalStore = ConversationStore.instance;
        final rental = LandlordDemoStore.demo();
        final store = ConversationStore(rental: rental);
        ConversationStore.instance = store;
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          ConversationStore.instance = originalStore;
          store.dispose();
          rental.dispose();
        });
        final room = TenantRoomDemoData.forStore(
          rental,
          includeExternal: false,
        ).first;
        await tester.pumpWidget(
          MaterialApp(
            home: TenantLayout(
              pageBuilder: (context, destination) {
                if (destination.id != 'discovery') {
                  return buildTenantPage(context, destination);
                }
                return Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => TenantRoomDetailsPage(
                          room: room,
                          onBook: () {},
                          isFavorite: false,
                          onFavoriteToggle: () {},
                        ),
                      ),
                    ),
                    child: const Text('Xem phòng'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xem phòng'));
        await tester.pumpAndSettle();
        final label = find.text('Nhắn tin');
        final paragraph = tester.renderObject<RenderParagraph>(label);
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 8),
        );
        expect(boxes.map((box) => box.top).toSet(), hasLength(1));
        await tester.tap(find.widgetWithText(OutlinedButton, 'Nhắn tin'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TenantTinNhanPage), findsOneWidget);
        expect(find.byType(TenantDanhSachTinNhanPage), findsNothing);
        final source = store.conversations.single;
        final adapter = tester
            .widget<TenantTinNhanPage>(find.byType(TenantTinNhanPage))
            .conversation;
        expect(source.propertyId, room.propertyId);
        expect(source.tenantId, TenantSession.currentTenantId);
        expect(source.landlordName, rental.property.ownerName);
        expect(source.room, room.name);
        expect(source.messages, isEmpty);
        expect(find.text('Bắt đầu cuộc trò chuyện'), findsOneWidget);
        const message = 'Chào chủ trọ, phòng này còn trống không ạ?';
        await tester.enterText(find.byType(TextField), message);
        await tester.pump();
        await tester.tap(find.byTooltip('Gửi tin nhắn'));
        await tester.pumpAndSettle();
        expect(source.messages.single.text, message);
        expect(source.unread, 1);
        store.send(
          source,
          text: 'Phòng còn trống nhé.',
          time: '10:30',
          fromLandlord: true,
        );
        await tester.pumpAndSettle();
        expect(find.text('Phòng còn trống nhé.'), findsOneWidget);
        expect(source.tenantUnread, 0);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(TenantRoomDetailsPage), findsOneWidget);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Nhắn tin'));
        await tester.pumpAndSettle();
        expect(store.conversations.single, same(source));
        expect(find.text(message), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.forum_outlined));
        await tester.pumpAndSettle();
        final card = find.byType(TenantConversationCard);
        expect(
          tester.widget<TenantConversationCard>(card).conversation.source,
          same(source),
        );
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TenantTinNhanPage>(find.byType(TenantTinNhanPage))
              .conversation,
          same(adapter),
        );
        expect(find.text(message), findsOneWidget);
        expect(find.text('Phòng còn trống nhé.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in [
    const Size(390, 844),
    const Size(360, 640),
    const Size(1280, 800),
  ]) {
    testWidgets('Booking stays visible above system navigation at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      var booked = false;
      final room = TenantRoomDemoData.allListings.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Khám phá',
                ),
                NavigationDestination(icon: Icon(Icons.home), label: 'Chỗ ở'),
              ],
            ),
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  useSafeArea: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => TenantRoomDetailsSheet(
                    room: room,
                    isFavorite: false,
                    onFavoriteToggle: () {},
                    onBook: () => booked = true,
                  ),
                ),
                child: const Text('Chi tiết'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Chi tiết'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Đặt lịch xem phòng');
      expect(button.hitTestable(), findsOneWidget);
      final before = tester.getRect(button);
      expect(before.bottom, lessThanOrEqualTo(size.height - 34));
      await tester.drag(
        find.descendant(
          of: find.byType(TenantRoomDetailsSheet),
          matching: find.byType(ListView),
        ),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(button), before);
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(booked, isTrue);
      expect(find.byType(TenantRoomDetailsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
