import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/landlord_navigation.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/announcements/landlord_announcements_page.dart';
import 'package:quanlytro/pages/landlord/billing/landlord_billing_page.dart';
import 'package:quanlytro/pages/landlord/conversations/landlord_danhsachtinnhan_page.dart';
import 'package:quanlytro/pages/landlord/conversations/landlord_tinnhan_page.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_cuoctrochuyen.dart';
import 'package:quanlytro/pages/landlord/dashboard/landlord_tongquan_page.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_room_balance.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_room_balance_card.dart';
import 'package:quanlytro/pages/landlord/incidents/components/landlord_incident_glass_card.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_glass.dart';
import 'package:quanlytro/pages/landlord/landlord_theme.dart';
import 'package:quanlytro/pages/landlord/rooms/components/landlord_room_button.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_room_detail_page.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_rooms_page.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';

import 'support/landlord_redesign_fixture.dart';

void main() {
  late RentalPortfolio original;
  late LandlordDemoStore rental;
  late RentalPortfolio portfolio;
  late ConversationStore oldMessages;
  late ConversationStore messages;
  setUp(() {
    original = RentalPortfolio.instance;
    oldMessages = ConversationStore.instance;
    rental = landlordRedesignFixture();
    portfolio = RentalPortfolio([rental]);
    RentalPortfolio.instance = portfolio;
    messages = ConversationStore(
      rental: rental,
      records: [
        LandlordConversation(
          id: 'redesign-test',
          tenantId: rental.leases.first.tenantId,
          tenantName: 'Người thuê kiểm thử',
          room: 'A.302',
          unread: 2,
          messages: [
            const LandlordMessage(
              text: 'Báo sự cố nước',
              time: '10:00',
              fromLandlord: false,
            ),
          ],
        ),
      ],
    );
    ConversationStore.instance = messages;
  });
  tearDown(() {
    RentalPortfolio.instance = original;
    ConversationStore.instance = oldMessages;
    messages.dispose();
    portfolio.dispose();
    rental.dispose();
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets('Four redesigned pages render at $width, dark=$dark', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final page in [
          const LandlordTongQuanPage(),
          const LandlordBillingPage(),
          const LandlordDanhSachTinNhanPage(),
          LandlordRoomDetailPage(store: rental, roomCode: 'A.302'),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: landlordTheme(dark: dark),
              home: Scaffold(body: page),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} at $width',
          );
        }
      });
    }
  }

  testWidgets('Dashboard shows the moved summary, incidents and unpaid rooms', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LandlordTongQuanPage())),
    );
    await tester.pumpAndSettle();
    final overview = tester.widget<PropertyPortfolioSummary>(
      find.byType(PropertyPortfolioSummary),
    );
    expect(overview.rooms, rental.catalog.length);
    expect(overview.properties, 1);
    expect(find.byType(LandlordIncidentGlassCard), findsWidgets);
    final unpaid = tester.widgetList<LandlordRoomBalanceCard>(
      find.byType(LandlordRoomBalanceCard),
    );
    expect(unpaid, isNotEmpty);
    expect(
      unpaid.every((card) => card.balance.state == RoomPaymentState.unpaid),
      isTrue,
    );
    final card = find.byType(LandlordIncidentGlassCard).first;
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Cập nhật trạng thái'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Đang xử lý'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Finance lists every room, filters paid rooms and opens bills', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LandlordBillingPage())),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(LandlordRoomBalanceCard),
      findsNWidgets(rental.catalog.length),
    );
    final cards = tester
        .widgetList<LandlordRoomBalanceCard>(
          find.byType(LandlordRoomBalanceCard),
        )
        .toList();
    expect(cards.any((c) => c.balance.state == RoomPaymentState.paid), isTrue);
    expect(
      cards.any((c) => c.balance.state == RoomPaymentState.unpaid),
      isTrue,
    );
    final search = find.byType(LandlordGlassSearch);
    await tester.ensureVisible(search);
    await tester.enterText(
      find.descendant(of: search, matching: find.byType(TextField)),
      '101',
    );
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomBalanceCard), findsOneWidget);
    expect(
      tester
          .widget<LandlordRoomBalanceCard>(find.byType(LandlordRoomBalanceCard))
          .balance
          .state,
      RoomPaymentState.paid,
    );
    await tester.ensureVisible(find.byType(LandlordRoomBalanceCard));
    await tester.tap(find.byType(LandlordRoomBalanceCard));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Đã đóng tiền'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Inbox search, unread state, send and return preserve the conversation',
    (tester) async {
      final record = messages
          .forProperty('may')
          .firstWhere((c) => c.id == 'redesign-test');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LandlordDanhSachTinNhanPage())),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'không tìm thấy');
      await tester.pumpAndSettle();
      expect(find.text('Không có cuộc trò chuyện phù hợp.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Người thuê kiểm thử');
      await tester.pumpAndSettle();
      final conversationTitle = find.descendant(
        of: find.byType(LandlordGlassCard),
        matching: find.text('Người thuê kiểm thử'),
      );
      await tester.ensureVisible(conversationTitle);
      await tester.tap(conversationTitle);
      await tester.pumpAndSettle();
      expect(find.byType(LandlordTinNhanPage), findsOneWidget);
      expect(record.unread, 0);
      await tester.enterText(find.byType(TextField), 'Chủ trọ đã tiếp nhận.');
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(record.messages.last.text, 'Chủ trọ đã tiếp nhận.');
      expect(record.messages.last.fromLandlord, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LandlordDanhSachTinNhanPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Finance updates a room after payment approval', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LandlordBillingPage())),
    );
    await tester.pumpAndSettle();
    LandlordRoomBalance roomBalance() => tester
        .widgetList<LandlordRoomBalanceCard>(
          find.byType(LandlordRoomBalanceCard),
        )
        .firstWhere((card) => card.balance.details.room.code == 'A.302')
        .balance;
    expect(roomBalance().state, RoomPaymentState.unpaid);
    rental.approvePayment(
      rental.payments.first,
      rental.payments.first.reportedAmount,
    );
    await tester.pumpAndSettle();
    expect(roomBalance().state, RoomPaymentState.paid);
    expect(roomBalance().remaining, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unbilled room opens invoice editor for its own lease', (
    tester,
  ) async {
    rental.invoices.firstWhere((i) => i.room == 'A.101').cancelled = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LandlordBillingPage(initialRoom: '101')),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.byType(LandlordRoomBalanceCard);
    expect(
      tester.widget<LandlordRoomBalanceCard>(card).balance.state,
      RoomPaymentState.unbilled,
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lập hóa đơn cho phòng này'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final leaseField = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(
      leaseField.initialValue,
      rental.leases.firstWhere((l) => l.room == 'A.101').id,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Renaming a room returns to its list and preserves the new code',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LandlordRoomDetailPage(store: rental, roomCode: '102'),
                  ),
                ),
                child: const Text('Mở phòng'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở phòng'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Chỉnh sửa phòng'));
      await tester.tap(find.text('Chỉnh sửa phòng'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '102-MOI');
      await tester.tap(find.text('Lưu phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomDetailPage), findsNothing);
      expect(rental.catalog.any((room) => room.code == '102-MOI'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Theme switch remains available from the drawer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.pumpAndSettle();
    final before = Theme.of(tester.element(find.byType(LandlordTongQuanPage)))
        .brightness;
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    final tooltip = before == Brightness.dark
        ? 'Chuyển sang giao diện sáng'
        : 'Chuyển sang giao diện tối';
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Drawer))).brightness,
      isNot(before),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Room click opens a full page with back, notifications and one navigation bar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
      await tester.pumpAndSettle();
      RoleLayoutShell.navigateTo(
        tester.element(find.byType(LandlordTongQuanPage)),
        'rooms',
      );
      await tester.pumpAndSettle();
      final room = find.byType(LandlordRoomButton).first;
      await tester.ensureVisible(room);
      await tester.tap(room);
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomDetailPage), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byTooltip('Quay lại'), findsOneWidget);
      expect(find.byType(LandlordBottomNavigation), findsOneWidget);
      await tester.tap(find.byTooltip('Thông báo'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordAnnouncementsPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomDetailPage), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordRoomsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
