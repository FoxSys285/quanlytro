import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/auth/change_password_page.dart';
import 'package:quanlytro/pages/shared/notifications/notification_settings_page.dart';
import 'package:quanlytro/pages/shared/profile/account_profile_page.dart';
import 'package:quanlytro/pages/shared/profile/account_store.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_card.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_favorites_page.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_favorites_store.dart';
import 'package:quanlytro/pages/tenant/incidents/tenant_baosuco_page.dart';
import 'package:quanlytro/pages/tenant/members/tenant_members_page.dart';
import 'package:quanlytro/pages/tenant/tenant_detail_ui.dart';
import 'package:quanlytro/pages/tenant/tenant_feature_ui.dart';
import 'package:quanlytro/pages/tenant/tenant_settings_page.dart';
import 'package:quanlytro/pages/tenant/viewings/components/tenant_viewing_request_sheet.dart';
import 'package:quanlytro/pages/tenant/viewings/models/tenant_viewing_request.dart';
import 'package:quanlytro/pages/tenant/viewings/tenant_viewings_page.dart';

void restoreFavorites(Set<String> saved) {
  TenantFavoritesStore.roomNames
    ..clear()
    ..addAll(saved);
  TenantFavoritesStore.changes.value++;
}

Future<void> loadPreviewFonts(WidgetTester tester) => tester.runAsync(() async {
  await (FontLoader('PreviewFont')..addFont(
        Future.value(
          ByteData.sublistView(
            File('C:/Windows/Fonts/arial.ttf').readAsBytesSync(),
          ),
        ),
      ))
      .load();
  await (FontLoader('MaterialIcons')..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              'D:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      ))
      .load();
});

Future<void> capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  final context = boundaryKey.currentContext!;
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toList();
  await tester.runAsync(() async {
    for (final provider in providers) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = context.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('.dart_tool/previews').create(recursive: true);
    await File('.dart_tool/previews/tenant_$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('All tenant utility pages fit at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rental = LandlordDemoStore.demo();
      final accounts = AccountStore(rental: rental);
      final viewings = ViewingStore.demo(referenceDate: DateTime.now());
      addTearDown(accounts.dispose);
      addTearDown(viewings.dispose);
      addTearDown(rental.dispose);
      final saved = Set<String>.of(TenantFavoritesStore.roomNames);
      addTearDown(() => restoreFavorites(saved));
      for (final room in TenantRoomDemoData.allListings.take(2)) {
        TenantFavoritesStore.remember(room);
        if (!TenantFavoritesStore.contains(room.id)) {
          TenantFavoritesStore.toggle(room.id);
        }
      }
      final preview =
          Platform.environment['CAPTURE_TENANT_FEATURES'] == 'true' &&
          width == 390;
      if (preview) await loadPreviewFonts(tester);
      final pages = <String, Widget>{
        'favorites': const TenantFavoritesPage(),
        'settings': const TenantSettingsPage(),
        'profile': AccountProfilePage(role: AppRole.tenant, store: accounts),
        'password': const ChangePasswordPage(role: AppRole.tenant),
        'notification_settings': NotificationSettingsPage(
          role: AppRole.tenant,
          store: accounts,
        ),
        'incidents': TenantBaoSuCoPage(store: rental),
        'viewings': TenantViewingsPage(store: viewings),
        'members': TenantMembersPage(store: rental),
      };
      const titles = {
        'profile': 'Hồ sơ cá nhân',
        'password': 'Đổi mật khẩu',
        'notification_settings': 'Thông báo ứng dụng',
        'incidents': 'Báo cáo sự cố',
        'viewings': 'Lịch xem phòng',
        'members': 'Thành viên phòng',
      };
      for (final entry in pages.entries) {
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: preview ? 'PreviewFont' : null,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(width == 320 ? 1.15 : 1),
                ),
                child: child!,
              ),
              home: entry.key == 'favorites' || entry.key == 'settings'
                  ? entry.value
                  : TenantSubpageScaffold(
                      title: titles[entry.key]!,
                      child: entry.value,
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(TenantFeatureFrame),
          findsOneWidget,
          reason: entry.key,
        );
        expect(
          find.byKey(const ValueKey('tenant-appbar-notifications')),
          findsOneWidget,
          reason: entry.key,
        );
        expect(tester.takeException(), isNull, reason: entry.key);
        if (preview) await capture(tester, boundaryKey, entry.key);
        if (entry.key == 'profile' && preview) {
          await tester.ensureVisible(find.text('Chỉnh sửa hồ sơ'));
          await tester.tap(find.text('Chỉnh sửa hồ sơ'));
          await tester.pumpAndSettle();
          await capture(tester, boundaryKey, 'profile_form');
        }
        if (entry.key == 'members' && preview) {
          await tester.ensureVisible(find.text('Yêu cầu thêm thành viên'));
          await tester.tap(find.text('Yêu cầu thêm thành viên'));
          await tester.pumpAndSettle();
          await capture(tester, boundaryKey, 'member_form');
        }
        if (entry.key == 'incidents' && preview) {
          await tester.tap(find.text('Tạo yêu cầu mới'));
          await tester.pumpAndSettle();
          await capture(tester, boundaryKey, 'incident_form');
        }
        expect(tester.takeException(), isNull, reason: entry.key);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets(
    'Favorites react to external removal and clear updates subscribers',
    (tester) async {
      final saved = Set<String>.of(TenantFavoritesStore.roomNames);
      addTearDown(() => restoreFavorites(saved));
      TenantFavoritesStore.clear();
      final rooms = TenantRoomDemoData.allListings.take(2).toList();
      for (final room in rooms) {
        TenantFavoritesStore.remember(room);
        TenantFavoritesStore.toggle(room.id);
      }
      await tester.pumpWidget(const MaterialApp(home: TenantFavoritesPage()));
      await tester.pumpAndSettle();
      expect(find.byType(TenantRoomCard), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'khong tim thay');
      await tester.pumpAndSettle();
      expect(find.byType(TenantRoomCard), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      TenantFavoritesStore.toggle(rooms.first.id);
      await tester.pumpAndSettle();
      expect(find.byType(TenantRoomCard), findsOneWidget);
      final version = TenantFavoritesStore.changes.value;
      await tester.ensureVisible(find.text('Xóa tất cả'));
      await tester.tap(find.text('Xóa tất cả'));
      await tester.pumpAndSettle();
      expect(TenantFavoritesStore.changes.value, version + 1);
      expect(find.byType(TenantRoomCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0]) {
    testWidgets('Viewing form validates and submits above keyboard at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final preview =
          Platform.environment['CAPTURE_TENANT_FEATURES'] == 'true' &&
          width == 390;
      if (preview) await loadPreviewFonts(tester);
      TenantViewingRequest? result;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: preview ? 'PreviewFont' : null,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<TenantViewingRequest>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => TenantViewingRequestSheet(
                        room: TenantRoomDemoData.allListings.first,
                      ),
                    );
                  },
                  child: const Text('Mở form'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở form'));
      await tester.pumpAndSettle();
      if (preview) await capture(tester, boundaryKey, 'viewing_form');
      await tester.ensureVisible(find.text('Gửi yêu cầu đặt lịch'));
      await tester.tap(find.text('Gửi yêu cầu đặt lịch'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập họ tên để chủ trọ liên hệ.'), findsOneWidget);
      expect(result, isNull);
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.first);
      await tester.enterText(fields.first, 'Nguyễn An');
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), '0901234567');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gửi yêu cầu đặt lịch'));
      await tester.tap(find.text('Gửi yêu cầu đặt lịch'));
      await tester.pumpAndSettle();
      expect(result?.customerName, 'Nguyễn An');
      expect(result?.phone, '0901234567');
      expect(result!.startsAt.isAfter(DateTime.now()), isTrue);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Member form validates and submits a pending request', (
    tester,
  ) async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final lease = rental.currentLeaseForTenant(TenantSession.tenantId)!;
    final before = rental.membersForLease(lease.id).length;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TenantMembersPage(store: rental)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Yêu cầu thêm thành viên'));
    await tester.tap(find.text('Yêu cầu thêm thành viên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập họ tên thành viên.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Bạn ở cùng');
    await tester.enterText(find.byType(TextFormField).last, '0905556666');
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(rental.members.any((member) => member.name == 'Bạn ở cùng'), isTrue);
    expect(
      rental.membersForLease(lease.id).length,
      before,
      reason: 'Owner approval is required before becoming a room member',
    );
    expect(tester.takeException(), isNull);
  });
}
