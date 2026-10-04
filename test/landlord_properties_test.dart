import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_properties_page.dart';
import 'package:quanlytro/pages/landlord/properties/components/landlord_property_card.dart';

void main() {
  testWidgets('Landlord menu opens shared discovery listings', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhà trọ'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordPropertiesPage), findsOneWidget);
    expect(find.byType(LandlordPropertyCard), findsNWidgets(21));
    expect(find.text('Mây House · Studio đầy đủ nội thất'), findsOneWidget);
    expect(find.text('Phòng gác An Nhiên 10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Search, filters and details at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LandlordPropertiesPage()),
      ));
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Studio'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng gác lửng Nhà Nâu'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Mây House');
      await tester.pumpAndSettle();
      expect(find.text('1 kết quả'), findsOneWidget);
      await tester.ensureVisible(find.text('Xem chi tiết'));
      await tester.tap(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Giá thuê: 3.800.000 đ/tháng'), findsOneWidget);
      expect(find.text('Có máy lạnh'), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'khong-co-nha-tro-nay');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy nhà trọ phù hợp.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
