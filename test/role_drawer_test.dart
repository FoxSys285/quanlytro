import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/role_layout.dart';

void main() {
  for (final role in AppRole.values) {
    for (final size in [const Size(390, 640), const Size(1280, 800)]) {
      testWidgets('Drawer keeps selection and scroll for $role at $size', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final destinations = List.generate(
          30,
          (index) => RoleDestination(
            id: index == 29 ? 'notifications' : 'page-$index',
            label: 'Chức năng $index',
            icon: Icons.home_outlined,
            group: 'Nhóm ${index ~/ 5}',
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: RoleLayoutShell(
              role: role,
              displayName: 'Người dùng',
              contextLabel: 'Nhà trọ',
              appName: 'Nhà trọ',
              accentColor: Colors.blue,
              destinations: destinations,
              initialDestinationId: 'page-0',
              tabs: const [
                RoleTab(
                  label: 'Đầu tiên',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  destinationId: 'page-0',
                ),
              ],
              pageBuilder: (_, destination) =>
                  Center(child: Text('Trang ${destination.id}')),
            ),
          ),
        );

        Future<void> openDrawer() async {
          await tester.tap(find.byTooltip('Mở danh mục chức năng'));
          await tester.pumpAndSettle();
        }

        Finder tile(int index) => find.descendant(
          of: find.byType(Drawer),
          matching: find.widgetWithText(ListTile, 'Chức năng $index'),
        );
        ScrollPosition position() => tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byType(Drawer),
                matching: find.byType(Scrollable),
              ),
            )
            .position;

        await openDrawer();
        await tester.ensureVisible(tile(22));
        await tester.pumpAndSettle();
        final offset = position().pixels;
        final selectedY = tester.getTopLeft(tile(22)).dy;
        expect(offset, greaterThan(0));
        await tester.tap(tile(22));
        await tester.pumpAndSettle();
        expect(find.text('Trang page-22'), findsOneWidget);
        await openDrawer();
        expect(tile(22).hitTestable(), findsOneWidget);
        expect(tester.widget<ListTile>(tile(22)).selected, isTrue);
        expect(position().pixels, closeTo(offset, 1));
        expect(tester.getTopLeft(tile(22)).dy, closeTo(selectedY, 1));

        // Closing without choosing another item also keeps the selected item visible.
        tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
        await tester.pumpAndSettle();
        await openDrawer();
        expect(position().pixels, closeTo(offset, 1));
        tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
        await tester.pumpAndSettle();

        // A destination selected outside the drawer must be revealed on reopening.
        await tester.tap(find.byTooltip('Thông báo'));
        await tester.pumpAndSettle();
        await openDrawer();
        expect(tile(29).hitTestable(), findsOneWidget);
        expect(tester.widget<ListTile>(tile(29)).selected, isTrue);
        tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Đầu tiên'));
        await tester.pumpAndSettle();
        await openDrawer();
        expect(tile(0).hitTestable(), findsOneWidget);
        expect(tester.widget<ListTile>(tile(0)).selected, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
