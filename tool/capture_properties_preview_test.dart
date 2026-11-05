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

void main() {
  testWidgets('Capture redesigned landlord property screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final original = RentalPortfolio.instance;
    final portfolio = RentalPortfolio([]);
    portfolio.add(
      const LandlordProperty(
        id: 'preview',
        name: 'Nhà trọ An Nhiên',
        address: '25 Nguyễn Gia Trí, Bình Thạnh, TP. Hồ Chí Minh',
        ownerName: 'Trần Nguyên',
        phone: '0912345678',
        description: '',
      ),
      floors: 3,
      roomsPerFloor: 5,
    );
    RentalPortfolio.instance = portfolio;
    addTearDown(() {
      RentalPortfolio.instance = original;
      portfolio.dispose();
    });
    final boundaryKey = GlobalKey();
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
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
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LandlordLayout(displayName: 'Trần Nguyên'),
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
    await tester.runAsync(() async {
      for (final asset in [
        'assets/images/landlord_property_house.png',
        'assets/images/room_types/interior.webp',
      ]) {
        await precacheImage(AssetImage(asset), boundaryKey.currentContext!);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final capture = await boundary.toImage(pixelRatio: 2);
      final bytes = await capture.toByteData(format: ui.ImageByteFormat.png);
      await Directory('.dart_tool/previews').create(recursive: true);
      await File('.dart_tool/previews/landlord_properties_redesign.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      capture.dispose();
    });
    debugDisableShadows = true;
  });
}
