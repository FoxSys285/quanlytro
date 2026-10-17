import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_details_sheet.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(360, 640),
    const Size(1280, 800),
  ]) {
    testWidgets('Booking stays visible above system navigation at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      var booked = false;
      final room = TenantRoomDemoData.allListings.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Khám phá',
                ),
                NavigationDestination(icon: Icon(Icons.home), label: 'Chỗ ở'),
              ],
            ),
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  useSafeArea: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => TenantRoomDetailsSheet(
                    room: room,
                    isFavorite: false,
                    onFavoriteToggle: () {},
                    onBook: () => booked = true,
                  ),
                ),
                child: const Text('Chi tiết'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Chi tiết'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Đặt lịch xem phòng');
      expect(button.hitTestable(), findsOneWidget);
      final before = tester.getRect(button);
      expect(before.bottom, lessThanOrEqualTo(size.height - 34));
      await tester.drag(
        find.descendant(
          of: find.byType(TenantRoomDetailsSheet),
          matching: find.byType(ListView),
        ),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(button), before);
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(booked, isTrue);
      expect(find.byType(TenantRoomDetailsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
