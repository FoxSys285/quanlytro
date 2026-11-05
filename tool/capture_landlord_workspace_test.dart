import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/landlord_navigation.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_room_detail_page.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';

import '../test/support/landlord_redesign_fixture.dart';

void main() {
  testWidgets('Capture all redesigned landlord destinations', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final original = RentalPortfolio.instance;
    final previousMessages = ConversationStore.instance;
    final rental = landlordRedesignFixture();
    final messages = ConversationStore.demo();
    final portfolio = RentalPortfolio([rental]);
    RentalPortfolio.instance = portfolio;
    ConversationStore.instance = messages;
    addTearDown(() {
      RentalPortfolio.instance = original;
      ConversationStore.instance = previousMessages;
      messages.dispose();
      portfolio.dispose();
      rental.dispose();
    });
    final key = GlobalKey();
    await tester.runAsync(() async {
      final fonts = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File(
                'D:/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
              ).readAsBytes(),
            ),
          ),
        );
      await fonts.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LandlordLayout(displayName: 'Trần Nguyên'),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/landlord_property_house.png'),
        key.currentContext!,
      );
      for (final type in rental.roomTypes) {
        for (final photo in type.photos) {
          if (photo.assetPath.startsWith('assets/')) {
            await precacheImage(
              ResizeImage(AssetImage(photo.assetPath), width: 480),
              key.currentContext!,
            );
          }
        }
      }
    });
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull, reason: name);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final screenshot = await boundary.toImage(pixelRatio: 2);
        final data = await screenshot.toByteData(
          format: ui.ImageByteFormat.png,
        );
        await Directory('artifacts/landlord_workspace').create(recursive: true);
        await File('artifacts/landlord_workspace/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        screenshot.dispose();
      });
    }

    await capture('dashboard');
    await tester.ensureVisible(find.text('Báo cáo sự cố'));
    await tester.pumpAndSettle();
    await capture('dashboard_reports');
    RoleLayoutShell.navigateTo(
      tester.element(find.byType(Scaffold).first),
      'billing',
    );
    await tester.pumpAndSettle();
    await capture('finance');
    await tester.ensureVisible(find.text('Danh sách phòng'));
    await tester.pumpAndSettle();
    await capture('finance_rooms');
    RoleLayoutShell.navigateTo(
      tester.element(find.byType(Scaffold).first),
      'conversations',
    );
    await tester.pumpAndSettle();
    await capture('messages');
    final context = tester.element(find.byType(Scaffold).first);
    LandlordNavigation.push<void>(
      context,
      page: LandlordRoomDetailPage(store: rental, roomCode: 'A.302'),
      destinationId: 'rooms',
    );
    await tester.pumpAndSettle();
    await capture('room_details');
    debugDisableShadows = true;
  });
}
