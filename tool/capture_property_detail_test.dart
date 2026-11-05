import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/landlord_navigation.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';
import 'package:quanlytro/pages/shared/media/room_photo.dart';

void main() {
  testWidgets('Capture property detail and its refreshed management tabs', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final previous = RentalPortfolio.instance;
    final portfolio = RentalPortfolio([]);
    final store = portfolio.add(
      const LandlordProperty(
        id: 'preview-kiki',
        name: 'Kiki House',
        address: '140 Lê Trọng Tấn',
        ownerName: 'Trần Nguyên',
        phone: '0912345678',
        description: '',
      ),
      floors: 3,
      roomsPerFloor: 5,
    );
    final data = store.toMap();
    final firstType = (data['roomTypes'] as List).first;
    firstType['photos'] = [RoomPhoto.studio.toMap()];
    data['roomTypes'] = [firstType];
    for (final room in data['rooms'] as List) {
      room['roomTypeId'] = firstType['id'];
    }
    store.restore(data);
    RentalPortfolio.instance = portfolio;
    addTearDown(() {
      RentalPortfolio.instance = previous;
      portfolio.dispose();
      store.dispose();
    });
    final key = GlobalKey();
    await tester.runAsync(() async {
      final font = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File(
                'D:/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
              ).readAsBytes(),
            ),
          ),
        );
      await font.load();
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
          home: LandlordLayout(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(LandlordBottomNavigation),
        matching: find.text('Nhà trọ'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Xem phòng'));
    await tester.tap(find.byTooltip('Xem phòng'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        const ResizeImage(
          AssetImage('assets/images/room_types/interior.webp'),
          width: 600,
        ),
        key.currentContext!,
      );
      for (final photo in store.roomTypes.first.photos) {
        if (photo.assetPath.isNotEmpty) {
          await precacheImage(
            ResizeImage(AssetImage(photo.assetPath), width: 480),
            key.currentContext!,
          );
        }
      }
    });
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts/landlord_workspace').create(recursive: true);
        await File('artifacts/landlord_workspace/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('property_details');
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await capture('property_rooms');
    await tester.ensureVisible(find.text('Loại phòng (1)'));
    await tester.tap(find.text('Loại phòng (1)'));
    await tester.pumpAndSettle();
    await capture('property_room_types');
    debugDisableShadows = true;
  });
}
