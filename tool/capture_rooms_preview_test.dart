import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/rooms/landlord_rooms_page.dart';

void main() {
  testWidgets('Capture local widget preview with the imported photo albums', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RentalPortfolio.instance = RentalPortfolio.seeded()..select('property-5');
    LandlordDemoStore.instance = RentalPortfolio.instance.active;
    final key = GlobalKey();
    await tester.runAsync(() async {
      final textFont = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File('.dart_tool/previews/Roboto.ttf').readAsBytes(),
            ),
          ),
        );
      await textFont.load();
      final iconFont = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await iconFont.load();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF16836F),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          ),
          home: const LandlordLayout(),
        ),
      ),
    );
    await tester.tap(find.text('Phòng'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final type in RentalPortfolio.instance.active.roomTypes) {
        for (final photo in type.photos) {
          await precacheImage(AssetImage(photo.assetPath), key.currentContext!);
        }
      }
    });
    await tester.pumpAndSettle();
    final scroll = find
        .descendant(
          of: find.byType(LandlordRoomsPage),
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    await tester.drag(scroll, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('.dart_tool/previews').create(recursive: true);
      await File('.dart_tool/previews/rooms_api_photos.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
