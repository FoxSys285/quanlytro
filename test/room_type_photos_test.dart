import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/room_types/components/room_type_editor.dart';
import 'package:quanlytro/pages/landlord/room_types/models/landlord_room_type.dart';
import 'package:quanlytro/pages/landlord/room_types/services/room_type_photo_picker.dart';
import 'package:quanlytro/pages/landlord/rooms/models/landlord_room.dart';
import 'package:quanlytro/pages/shared/media/room_photo.dart';
import 'package:quanlytro/pages/shared/media/room_photo_gallery.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Uint8List> _uploadBytes(WidgetTester tester) async =>
    (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(16, 16);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }))!;

Future<void> _openEditor(
  WidgetTester tester,
  LandlordDemoStore store, {
  required RoomTypePhotoPicker picker,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => RoomTypeEditor(
                store: store,
                type: store.roomTypes.first,
                pickPhotos: picker,
              ),
            ),
            child: const Text('Mở album'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở album'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'Room type album survives SQLite reopen and updates every related listing',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'room-type-photos-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/photos.db';
      final portfolio = RentalPortfolio.seeded();
      addTearDown(portfolio.dispose);
      final store = portfolio.active;
      final upload = RoomPhoto(
        name: 'phong-moi.jpg',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      store.saveRoomType(
        'Studio mới',
        id: 'studio',
        monthlyRent: 3100000,
        photos: [upload, RoomPhoto.balcony],
      );
      // Leaving photos unspecified while changing rent must retain the album.
      store.saveRoomType('Studio mới', id: 'studio', monthlyRent: 3200000);
      final repository = await SqliteRentalRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      await repository.saveAll({'portfolio': portfolio.toMap()});
      await repository.close();
      final reopened = await SqliteRentalRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      addTearDown(reopened.close);
      final restored = RentalPortfolio.fromMap(
        (await reopened.readAll())['portfolio']!,
      );
      addTearDown(restored.dispose);
      final restoredStore = restored.active;
      final album = restoredStore.roomTypes.first.photos;
      expect(album.map((photo) => photo.name), [
        'phong-moi.jpg',
        RoomPhoto.balcony.name,
      ]);
      expect(album.first.bytes, upload.bytes);
      expect(
        restored.stores[1].roomTypes.first.photos.first.url,
        RoomPhoto.demoForPropertyType('studio', 1).first.url,
      );
      final listings = TenantRoomDemoData.forStore(
        restoredStore,
        includeExternal: false,
      ).where((room) => room.roomType == 'Studio mới').toList();
      expect(listings, isNotEmpty);
      for (final listing in listings) {
        expect(listing.gallery, same(album));
        expect(listing.gallery.first.bytes, upload.bytes);
      }
      final changed = restoredStore.roomDetails
          .firstWhere(
            (room) =>
                room.room.roomTypeId == 'studio' &&
                room.status == LandlordRoomStatus.vacant,
          )
          .room;
      restoredStore.saveRoom(
        LandlordRoom(
          code: changed.code,
          floor: changed.floor,
          roomTypeId: 'balcony',
          area: changed.area,
          capacity: changed.capacity,
        ),
        existingCode: changed.code,
      );
      final changedListing =
          TenantRoomDemoData.forStore(
            restoredStore,
            includeExternal: false,
          ).firstWhere(
            (room) =>
                room.roomCode == restoredStore.canonicalRoom(changed.code),
          );
      expect(
        changedListing.gallery.first.url,
        RoomPhoto.demoForPropertyType('balcony', 0).first.url,
      );
      restoredStore.saveRoomType(
        'Studio mới',
        id: 'studio',
        monthlyRent: 3200000,
        photos: [],
      );
      final empty = RentalPortfolio.fromMap(
        jsonDecode(jsonEncode(restored.toMap())) as Map<String, dynamic>,
      );
      addTearDown(empty.dispose);
      expect(empty.active.roomTypes.first.photos, isEmpty);
      expect(
        TenantRoomDemoData.forStore(empty.active, includeExternal: false)
            .where((room) => room.roomType == 'Studio mới')
            .every((room) => room.gallery.isEmpty),
        isTrue,
      );
    },
  );

  test('Legacy data gains illustrative albums without overriding explicitly empty albums', () {
    final legacy = {'id': 'studio', 'name': 'Studio', 'monthlyRent': 3000000};
    expect(
      LandlordRoomType.fromMap(legacy).photos.first.url,
      RoomPhoto.studio.url,
    );
    expect(LandlordRoomType.fromMap({...legacy, 'photos': []}).photos, isEmpty);
    final store = LandlordDemoStore.demo();
    addTearDown(store.dispose);
    expect(
      () => store.saveRoomType(
        'Studio',
        id: 'studio',
        monthlyRent: 3000000,
        photos: List.filled(13, RoomPhoto.studio),
      ),
      throwsArgumentError,
    );
    expect(store.roomTypes.first.photos, hasLength(1));
  });

  test('Previously saved sample albums migrate without changing user photos or their order', () {
    final saved = LandlordRoomType.fromMap({
      'id': 'studio',
      'name': 'Studio riêng',
      'monthlyRent': 3500000,
      'photos': [
        {
          'name': 'Ảnh bìa cũ',
          'assetPath': 'assets/images/room_types/balcony.jpg',
        },
        {
          'name': 'Ảnh tải lên',
          'bytes': base64Encode([1, 2, 3]),
          'assetPath': 'assets/images/room_types/studio.jpg',
        },
        {'name': 'Ảnh riêng', 'url': 'https://example.com/my-room.jpg'},
        {'name': 'Asset riêng', 'assetPath': 'assets/custom/photo.jpg'},
        for (final type in ['studio', 'loft', 'group'])
          {'name': type, 'assetPath': 'assets/images/room_types/$type.jpg'},
      ],
    });
    expect(saved.name, 'Studio riêng');
    expect(saved.photos.first.url, RoomPhoto.balcony.url);
    expect(saved.photos.first.assetPath, RoomPhoto.balcony.assetPath);
    expect(saved.photos.first.isIllustration, isTrue);
    expect(saved.photos[1].bytes, [1, 2, 3]);
    expect(saved.photos[1].url, isEmpty);
    expect(saved.photos[2].url, 'https://example.com/my-room.jpg');
    expect(saved.photos[2].isIllustration, isFalse);
    expect(saved.photos[3].assetPath, 'assets/custom/photo.jpg');
    expect(saved.photos.skip(4).map((photo) => photo.url), [
      RoomPhoto.studio.url,
      RoomPhoto.loft.url,
      RoomPhoto.group.url,
    ]);
    final reopened = LandlordRoomType.fromMap(
      jsonDecode(jsonEncode(saved.toMap())) as Map<String, dynamic>,
    );
    expect(reopened.toMap(), saved.toMap());
  });

  for (final width in [360.0, 1280.0]) {
    testWidgets(
      'Select multiple photos, change cover, cancel and remove at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = LandlordDemoStore.demo();
        addTearDown(store.dispose);
        final bytes = await _uploadBytes(tester);
        final uploads = [
          RoomPhoto(name: 'ban-cong.jpg', bytes: bytes),
          RoomPhoto(name: 'goc-phong.jpg', bytes: bytes),
        ];
        await _openEditor(
          tester,
          store,
          picker: (remaining) async {
            expect(remaining, 11);
            return uploads;
          },
        );
        await tester.ensureVisible(find.text('Chọn nhiều ảnh'));
        await tester.tap(find.text('Chọn nhiều ảnh'));
        await tester.pumpAndSettle();
        expect(find.text('3/12'), findsOneWidget);
        expect(store.roomTypes.first.photos, hasLength(1));
        await tester.ensureVisible(find.text('Đặt làm bìa').last);
        await tester.tap(find.text('Đặt làm bìa').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(store.roomTypes.first.photos.first.name, 'goc-phong.jpg');
        final before = store.roomTypes.first.photos;
        await tester.tap(find.text('Mở album'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Xóa ảnh 1'));
        await tester.tap(find.byTooltip('Xóa ảnh 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
        expect(store.roomTypes.first.photos, same(before));
        await tester.tap(find.text('Mở album'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await tester.ensureVisible(find.byTooltip('Xóa ảnh 1'));
          await tester.tap(find.byTooltip('Xóa ảnh 1'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(store.roomTypes.first.photos, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Picker failure keeps the current album and allows retry', (
    tester,
  ) async {
    final store = LandlordDemoStore.demo();
    addTearDown(store.dispose);
    var attempts = 0;
    await _openEditor(
      tester,
      store,
      picker: (_) async {
        if (attempts++ == 0) throw const FormatException('Ảnh không hợp lệ.');
        return [RoomPhoto.balcony];
      },
    );
    await tester.ensureVisible(find.text('Chọn nhiều ảnh'));
    await tester.tap(find.text('Chọn nhiều ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Ảnh không hợp lệ.'), findsOneWidget);
    expect(store.roomTypes.first.photos, hasLength(1));
    await tester.tap(find.text('Chọn nhiều ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('2/12'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.roomTypes.first.photos, hasLength(2));
  });

  testWidgets(
    'Gallery changes photos, opens fullscreen and handles missing images',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoomPhotoGallery(
              photos: [RoomPhoto.studio, RoomPhoto.balcony],
              label: 'Studio',
              interactive: true,
            ),
          ),
        ),
      );
      expect(find.text('1/2'), findsOneWidget);
      await tester.tap(find.byTooltip('Ảnh tiếp theo'));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      await tester.tap(find.byType(RoomPhotoImage).last);
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoomPhotoGallery(photos: [], label: 'Trống'),
          ),
        ),
      );
      expect(find.text('Chưa có ảnh loại phòng'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomPhotoGallery(
              photos: [
                RoomPhoto(name: 'Lỗi', bytes: Uint8List.fromList([0, 1, 2])),
              ],
              label: 'Lỗi',
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không tải được ảnh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
