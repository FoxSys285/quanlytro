import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/layouts/admin_layout.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/admin/admin_page_router.dart';
import 'package:quanlytro/pages/admin/admin_demo_data.dart';
import 'package:quanlytro/pages/admin/admin_commission_page.dart';
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
      await tester.pumpWidget(const MaterialApp(home: AdminLayout()));
      await tester.pumpAndSettle();
      expect(find.text('Toàn cảnh nền tảng'), findsOneWidget);
      await tester.ensureVisible(find.text('Mở đối soát'));
      await tester.tap(find.text('Mở đối soát'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cơ sở tính:'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField).first, 'tenant@tro.local');
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == 'tenant@tro.local'),
      findsOneWidget,
    );
    expect(find.text('landlord@tro.local'), findsNothing);
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Khóa tài khoản'),
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
    await tester.enterText(find.byType(TextField).first, 'tenant@tro.local');
    await tester.pumpAndSettle();
    final lock = find.widgetWithText(OutlinedButton, 'Khóa tài khoản');
    await tester.ensureVisible(lock);
    await tester.tap(lock);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();
    expect(LocalAuth.instance.isDisabled(AppRole.tenant), isTrue);
    final unlock = find.widgetWithText(OutlinedButton, 'Mở khóa');
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
    'Admin photo review supports feedback, large text and reduced motion',
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
      final property = find.text('Mây House').first;
      await tester.ensureVisible(property);
      await tester.tap(property);
      await tester.pumpAndSettle();
      expect(find.text('Mở danh sách xác minh'), findsOneWidget);
      expect(feedback.any((c) => c.method == 'HapticFeedback.vibrate'), isTrue);
      expect(feedback.any((c) => c.method == 'SystemSound.play'), isTrue);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Mở danh sách xác minh'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Xác minh nhà trọ'), findsWidgets);
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
    for (final width in [390.0]) {
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
      const prefix = 'phone-widget';
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
      AdminDemoData.instance.enabled = true;
      AdminDemoData.instance.notifyListeners();
      await tester.pumpAndSettle();
      await capture(key, '$prefix-demo-commissions');
      final house = find.text('Mây House').first;
      await tester.ensureVisible(house);
      await tester.pumpAndSettle();
      await capture(key, '$prefix-demo-commission-list');
      await tester.tap(house);
      await tester.pumpAndSettle();
      await capture(key, '$prefix-demo-commission-expanded');
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
        await capture(key, '$prefix-demo-$id');
        expect(tester.takeException(), isNull);
      }
      AdminDemoData.instance.enabled = false;
    }
  });

  testWidgets(
    'Demo tenant list paginates, opens details and persists a contact edit',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(
        () => LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026'),
      );
      final demo = AdminDemoData.instance..enabled = true;
      addTearDown(() async {
        demo.enabled = false;
        await LocalAuth.instance.signOut();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => buildAdminPage(
                context,
                const RoleDestination(
                  id: 'users',
                  label: 'Người dùng',
                  icon: Icons.people,
                  group: 'admin',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final membersTab = find.descendant(
        of: find.byType(SegmentedButton<String>),
        matching: find.text('Người thuê'),
      );
      await tester.ensureVisible(membersTab);
      await tester.tap(membersTab);
      await tester.pumpAndSettle();
      final member = demo.portfolio.stores.first.members.first;
      final name = find.text(member.name).first;
      await tester.ensureVisible(name);
      await tester.tap(name);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sửa hồ sơ mẫu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Người thuê đã sửa');
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '0987654321');
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();
      expect(
        demo.portfolio.stores.first.members.first.name,
        'Người thuê đã sửa',
      );
      expect(demo.portfolio.stores.first.members.first.phone, '0987654321');
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
    },
  );

  testWidgets('Admin navigation opens users, commissions and the more drawer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AdminLayout()));
    await tester.pumpAndSettle();
    Finder destination(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
    await tester.tap(destination('Người dùng'));
    await tester.pumpAndSettle();
    expect(find.text('Người dùng & tài khoản'), findsOneWidget);
    await tester.tap(destination('Hoa hồng'));
    await tester.pumpAndSettle();
    expect(find.text('Cơ sở tính:'), findsOneWidget);
    await tester.tap(destination('Thêm'));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsOneWidget);
    await tester.tap(find.text('Hoạt động ứng dụng').last);
    await tester.pumpAndSettle();
    expect(find.text('Phạm vi thống kê'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loading another demo anchor selects its commission month', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final demo = AdminDemoData.instance;
    final before = demo.toMap();
    addTearDown(() => demo.restore(before));
    demo.restore({...before, 'enabled': true, 'anchor': '2026-11-04T00:00:00'});
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const Scaffold(body: AdminCommissionPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tháng 10/2026'), findsOneWidget);
    demo.restore({...demo.toMap(), 'anchor': '2026-02-04T00:00:00'});
    await tester.pumpAndSettle();
    expect(find.text('Tháng 01/2026'), findsOneWidget);
    expect(find.text('Tháng 10/2026'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
