import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/layouts/admin_layout.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/admin/admin_page_router.dart';
import 'package:quanlytro/pages/admin/admin_users_page.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';

void main() {
  setUpAll(() async {
    await LocalAuth.instance.initialize();
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Admin pages and navigation fit $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      RentalPortfolio.instance = RentalPortfolio.seeded();
      // Không mở SQLite/Firebase trong kiểm tra giao diện.
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.3 : 1)),
            child: child!,
          ),
          home: const AdminLayout(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tổng quan hệ thống'), findsOneWidget);
      expect(find.text('Yêu cầu hỗ trợ'), findsWidgets);
      RoleLayoutShell.navigateTo(
        tester.element(find.text('Tổng quan hệ thống')),
        'statistics',
      );
      await tester.pumpAndSettle();
      expect(find.text('Gói dịch vụ & thanh toán'), findsWidgets);
      expect(tester.takeException(), isNull);
      for (final id in [
        'users',
        'activity',
        'property_verification',
        'moderation',
        'audit_logs',
        'settings',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.3 : 1)),
              child: child!,
            ),
            home: Scaffold(
              body: KeyedSubtree(
                key: ValueKey(id),
                child: Builder(
                  builder: (context) => buildAdminPage(
                    context,
                    RoleDestination(
                      id: id,
                      label: id,
                      icon: Icons.home,
                      group: 'admin',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$id at $width');
      }
    });
  }

  testWidgets('Account search filters login accounts, preview cannot lock', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildAdminPage(
              context,
              const RoleDestination(
                id: 'users',
                label: 'Tài khoản',
                icon: Icons.people,
                group: 'admin',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Người thuê'));
    await tester.pumpAndSettle();
    expect(find.text('tenant@tro.local'), findsOneWidget);
    expect(find.text('landlord@tro.local'), findsNothing);
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Khóa tài khoản'),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Admin confirms account lock and unlock from the user screen', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildAdminPage(
              context,
              const RoleDestination(
                id: 'users',
                label: 'Tài khoản',
                icon: Icons.people,
                group: 'admin',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Người thuê'));
    await tester.pumpAndSettle();
    final lock = find.byTooltip('Khóa tài khoản');
    await tester.ensureVisible(lock);
    await tester.tap(lock);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();
    expect(LocalAuth.instance.isDisabled(AppRole.tenant), isTrue);
    final unlock = find.byTooltip('Mở khóa tài khoản');
    await tester.ensureVisible(unlock);
    await tester.tap(unlock);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();
    expect(LocalAuth.instance.isDisabled(AppRole.tenant), isFalse);
    await LocalAuth.instance.signOut();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Admin verification page supports large text, reduced motion and feedback',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      RentalPortfolio.instance = RentalPortfolio.seeded();
      final feedback = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          feedback.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: const AdminLayout(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher).first)
            .duration,
        Duration.zero,
      );
      RoleLayoutShell.navigateTo(
        tester.element(find.text('Tổng quan hệ thống')),
        'property_verification',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
      await tester.pumpAndSettle();
      expect(find.text('Xác minh nhà trọ'), findsWidgets);
      expect(find.text('Mây House'), findsOneWidget);
      expect(feedback.any((c) => c.method == 'HapticFeedback.vibrate'), isTrue);
      expect(find.text('THÔNG TIN CÒN THIẾU'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Capture admin preview without database or network writes', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('ADMIN_PREVIEW')) return;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RentalPortfolio.instance = RentalPortfolio.seeded();
    const liveSnapshot = String.fromEnvironment('ADMIN_LIVE_SNAPSHOT');
    if (liveSnapshot.isNotEmpty) {
      await tester.runAsync(() async {
        final portfolioRaw = jsonDecode(
          await File('$liveSnapshot/portfolio.json').readAsString(),
        ) as Map;
        RentalPortfolio.instance = RentalPortfolio.fromMap(
          Map<String, dynamic>.from(
            jsonDecode(
              portfolioRaw['fields']['payload']['stringValue'] as String,
            ) as Map,
          ),
        );
        final adminRaw = jsonDecode(
          await File('$liveSnapshot/admin-after.json').readAsString(),
        ) as Map;
        AdminStore.instance.restore(
          Map<String, dynamic>.from(
            jsonDecode(adminRaw['fields']['payload']['stringValue'] as String)
                as Map,
          ),
        );
      });
    }
    await tester.runAsync(() async {
      final font = File('.dart_tool/previews/Roboto.ttf');
      if (await font.exists()) {
        await (FontLoader('Roboto')..addFont(
              Future.value(ByteData.sublistView(await font.readAsBytes())),
            ))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    Future<void> capture(GlobalKey key, String name) => tester.runAsync(
      () async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await Directory('.impeccable/review').create(recursive: true);
        await File('.impeccable/review/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      },
    );
    for (final width in [390.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 900);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
            home: const AdminLayout(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final store in RentalPortfolio.instance.stores) {
          if (store.property.imageUrl.startsWith('assets/')) {
            await precacheImage(
              AssetImage(store.property.imageUrl),
              key.currentContext!,
            );
          }
        }
        await precacheImage(
          const AssetImage('assets/images/room_types/interior.webp'),
          key.currentContext!,
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final prefix = width < 600 ? 'phone-widget' : 'desktop-widget';
      await capture(key, prefix);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/admin_preview').create(recursive: true);
        await File('build/admin_preview/admin_${width.toInt()}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.text('Mây House').first);
      await tester.pumpAndSettle();
      await capture(key, '$prefix-property-sheet');
      Navigator.of(tester.element(find.text('Mở danh sách xác minh'))).pop();
      await tester.pumpAndSettle();
      for (final id in ['users', 'property_verification', 'commissions']) {
        RoleLayoutShell.navigateTo(
          tester.element(find.byType(Scaffold).first),
          id,
        );
        await tester.pumpAndSettle();
        await capture(key, '$prefix-$id');
      }
      await tester.pumpAndSettle();
      await capture(key, '$prefix-live-commissions');
      final house = find.text('Mây House').first;
      await tester.ensureVisible(house);
      await tester.pumpAndSettle();
      await capture(key, '$prefix-live-commission-list');
      await tester.tap(house);
      await tester.pumpAndSettle();
      await capture(key, '$prefix-live-commission-expanded');
      for (final id in ['users', 'activity']) {
        RoleLayoutShell.navigateTo(
          tester.element(find.byType(Scaffold).first),
          id,
        );
        await tester.pumpAndSettle();
        if (id == 'users') {
          final membersTab = find.descendant(
            of: find.byType(SegmentedButton<String>),
            matching: find.text('Người thuê'),
          );
          await tester.ensureVisible(membersTab);
          await tester.tap(membersTab);
          await tester.pumpAndSettle();
        }
        await capture(key, '$prefix-live-$id');
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Tenant list edits shared records without a demo switch', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026'),
    );
    addTearDown(() => LocalAuth.instance.signOut());
    RentalPortfolio.instance = RentalPortfolio.seeded();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: const AdminUsersPage())),
    );
    await tester.pumpAndSettle();
    final membersTab = find.descendant(
      of: find.byType(SegmentedButton<String>),
      matching: find.text('Người thuê'),
    );
    await tester.ensureVisible(membersTab);
    await tester.tap(membersTab);
    await tester.pumpAndSettle();
    final member = RentalPortfolio.instance.stores.first.members.first;
    final name = find.text(member.name).first;
    await tester.ensureVisible(name);
    await tester.tap(name);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa hồ sơ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Người thuê đã sửa');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0987654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    expect(
      RentalPortfolio.instance.stores.first.members.first.name,
      'Người thuê đã sửa',
    );
    expect(
      RentalPortfolio.instance.stores.first.members.first.phone,
      '0987654321',
    );
    expect(find.text('Người thuê đã sửa'), findsOneWidget);
    final next = find.byTooltip('Trang tiếp theo');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.textContaining('13–24 /'), findsOneWidget);
    expect(find.text('Người thuê đã sửa'), findsNothing);
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'không tồn tại xyz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tìm thấy hồ sơ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin navigation opens accounts, packages and the more drawer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AdminLayout()));
    await tester.pumpAndSettle();
    RoleLayoutShell.navigateTo(
      tester.element(find.text('Tổng quan hệ thống')),
      'users',
    );
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản người dùng'), findsWidgets);
    RoleLayoutShell.navigateTo(
      tester.element(find.text('Tài khoản người dùng').first),
      'statistics',
    );
    await tester.pumpAndSettle();
    expect(find.text('Gói dịch vụ & thanh toán'), findsWidgets);
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Nhật ký hoạt động'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhật ký hoạt động'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
