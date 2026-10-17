import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/members/landlord_nguoithue_page.dart';
import 'package:quanlytro/pages/landlord/properties/services/property_image_picker.dart';
import 'package:quanlytro/pages/landlord/room_types/landlord_room_types_page.dart';
import 'package:quanlytro/pages/landlord/room_types/models/landlord_room_type.dart';
import 'package:quanlytro/pages/shared/rental/lease_member.dart';
import 'package:quanlytro/pages/shared/rental/room_image_gallery.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/leases/tenant_home_page.dart';

final _bytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=',
);

LandlordDemoStore _store() {
  final store = LandlordDemoStore.demo();
  for (final lease in store.leases) {
    lease.startDate = DateTime.now().subtract(const Duration(days: 30));
    lease.endDate = DateTime.now().add(const Duration(days: 365));
  }
  return store;
}

void main() {
  test('Room photos follow the room type and survive price-only edits', () {
    final store = _store();
    addTearDown(store.dispose);
    final photos = [RoomTypeImage(name: 'balcony.png', bytes: _bytes)];
    store.saveRoomType(
      'Ban công',
      id: 'balcony',
      monthlyRent: 3600000,
      images: photos,
    );
    photos.clear();
    store.saveRoomType('Ban công mới', id: 'balcony', monthlyRent: 3700000);
    final rooms = TenantRoomDemoData.forStore(store);
    final balcony = rooms.firstWhere((room) => room.roomCode == '102');
    expect(balcony.images.single.name, 'balcony.png');
    expect(balcony.imageBytes, _bytes);
    expect(balcony.price, 3700000);
    expect(rooms.firstWhere((room) => room.roomCode == '201').images, isEmpty);
    expect(
      store.roomDetails
          .firstWhere((room) => room.room.code == 'A.302')
          .type!
          .images
          .single
          .name,
      'balcony.png',
    );
    store.saveRoomType(
      'Ban công mới',
      id: 'balcony',
      monthlyRent: 3700000,
      images: [],
    );
    expect(
      TenantRoomDemoData.forStore(store)
          .firstWhere((room) => room.roomCode == '102')
          .imageBytes,
      isNull,
    );
  });

  test('Member requests enforce identity, duplicates, dates and capacity', () {
    final store = _store();
    addTearDown(store.dispose);
    LeaseMember request(
      String phone, {
      String tenantId = TenantSession.tenantId,
      DateTime? date,
    }) => store.requestMember(
      tenantId: tenantId,
      name: 'Người mới',
      phone: phone,
      joinedAt: date ?? DateTime.now(),
    );
    expect(
      () => request('0905555555', tenantId: 'unknown'),
      throwsArgumentError,
    );
    expect(() => request('123'), throwsArgumentError);
    expect(
      () => request(
        '0905555555',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      throwsArgumentError,
    );
    expect(
      () => request(
        '0905555555',
        date: DateTime.now().add(const Duration(days: 400)),
      ),
      throwsArgumentError,
    );
    final member = request('0905555555');
    final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
    expect(member.status, LeaseMemberStatus.pending);
    expect(lease.occupantCount, 2);
    expect(() => request('0905555555'), throwsArgumentError);
    final second = request('0906666666');
    expect(() => request('0907777777'), throwsArgumentError);
    store.reviewMember(member, approve: true);
    expect(lease.occupantCount, 3);
    expect(
      () => store.reviewMember(second, approve: false),
      throwsArgumentError,
    );
    store.reviewMember(second, approve: false, reason: 'Cần bổ sung thông tin');
    expect(lease.occupantCount, 3);
    expect(request('0907777777').status, LeaseMemberStatus.pending);
    store.endLease(lease);
    expect(() => request('0908888888'), throwsArgumentError);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'Upload, cover selection, cancel and gallery navigation at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = _store();
        addTearDown(store.dispose);
        var next = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LandlordRoomTypesPage(
                store: store,
                imagePicker: () async => SelectedPropertyImage(
                  bytes: _bytes,
                  name: 'photo-${++next}.png',
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byTooltip('Sửa Studio'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 2; i++) {
          await tester.ensureVisible(find.text('Thêm ảnh'));
          await tester.tap(find.text('Thêm ảnh'));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Đặt làm bìa'));
        await tester.tap(find.text('Đặt làm bìa'));
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(store.roomTypes.first.images.map((image) => image.name), [
          'photo-2.png',
          'photo-1.png',
        ]);
        final gallery = find.byType(RoomImageGallery).first;
        await tester.ensureVisible(gallery);
        await tester.tap(
          find.descendant(
            of: gallery,
            matching: find.byTooltip('Ảnh tiếp theo'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('2 / 2'), findsOneWidget);
        await tester.tapAt(tester.getCenter(gallery));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsWidgets);
        await tester.tap(find.byTooltip('Đóng ảnh'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Sửa Studio'));
        await tester.tap(find.byTooltip('Sửa Studio'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Xóa ảnh 1'));
        await tester.tap(find.byTooltip('Xóa ảnh 1'));
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
        expect(store.roomTypes.first.images.length, 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tenant submits and landlord approves or rejects at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = _store();
      addTearDown(store.dispose);
      Future<void> home() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TenantHomePage(store: store)),
        ),
      );
      await home();
      await tester.ensureVisible(find.text('Thêm thành viên'));
      await tester.tap(find.text('Thêm thành viên'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập họ tên thành viên.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Nguyễn An');
      await tester.enterText(find.byType(TextFormField).last, '0905555555');
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(
        store.members.firstWhere((member) => member.name == 'Nguyễn An').status,
        LeaseMemberStatus.pending,
      );
      await tester.ensureVisible(find.text('Chờ chủ trọ duyệt'));
      expect(find.text('Chờ chủ trọ duyệt'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordNguoiThuePage(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0905555555');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Duyệt'));
      await tester.tap(find.text('Duyệt'));
      await tester.pumpAndSettle();
      expect(
        store.currentLeaseForTenant(TenantSession.tenantId)!.occupantCount,
        3,
      );
      await tester.tap(find.text('Đã duyệt'));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn An'), findsOneWidget);
      final rejected = store.requestMember(
        tenantId: TenantSession.tenantId,
        name: 'Nguyễn Bình',
        phone: '0906666666',
        joinedAt: DateTime.now(),
      );
      await tester.enterText(find.byType(TextField), '0906666666');
      await tester.tap(find.text('Chờ duyệt'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Từ chối'));
      await tester.tap(find.text('Từ chối'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Cần bổ sung hồ sơ');
      await tester.tap(find.widgetWithText(FilledButton, 'Từ chối'));
      await tester.pumpAndSettle();
      expect(rejected.status, LeaseMemberStatus.rejected);
      await home();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lý do: Cần bổ sung hồ sơ'));
      expect(find.text('Nguyễn An'), findsOneWidget);
      expect(find.text('Lý do: Cần bổ sung hồ sơ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
