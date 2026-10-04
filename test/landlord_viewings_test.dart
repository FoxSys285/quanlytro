import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/viewings/components/landlord_viewing_card.dart';
import 'package:quanlytro/pages/landlord/viewings/data/landlord_viewing_demo_data.dart';
import 'package:quanlytro/pages/landlord/viewings/landlord_viewings_page.dart';

void main() {
  testWidgets('Landlord menu opens viewing schedule', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lịch xem phòng'),
      200,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Lịch xem phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordViewingsPage), findsOneWidget);
    expect(find.byType(LandlordViewingCard), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Chronological schedule and customer search at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = LandlordViewingDemoData.create(
        referenceDate: DateTime(2026, 12, 31),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordViewingsPage(viewings: data)),
        ),
      );
      final ids = tester
          .widgetList<LandlordViewingCard>(find.byType(LandlordViewingCard))
          .map((card) => card.viewing.id)
          .toList();
      expect(ids, [
        'viewing-demo-1',
        'viewing-demo-5',
        'viewing-demo-2',
        'viewing-demo-4',
        'viewing-demo-0',
        'viewing-demo-3',
      ]);
      expect(
        data.first.id,
        'viewing-demo-0',
      ); // Original data is not reordered.
      expect(find.text('Thứ Sáu, 01/01/2027'), findsOneWidget);
      expect(find.text('0900000002'), findsOneWidget);
      expect(find.text(data[1].personalNeeds), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), '0900000005');
      await tester.pumpAndSettle();
      expect(find.byType(LandlordViewingCard), findsOneWidget);
      expect(find.text('Võ Ngọc Linh'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chờ xác nhận'));
      await tester.pumpAndSettle();
      expect(find.text('Không có lịch xem phòng phù hợp.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.byType(LandlordViewingCard), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  }
}
