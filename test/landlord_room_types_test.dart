import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/room_types/landlord_room_types_page.dart';

void main() {
  testWidgets('Landlord menu opens room types', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Loại phòng'));
    await tester.tap(find.text('Loại phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomTypesPage), findsOneWidget);
    expect(find.text('Phòng có ban công'), findsOneWidget);
    expect(find.text('Phòng lớn cho 5 người'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Room type details and edit at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LandlordRoomTypesPage())),
      );
      await tester.enterText(find.byType(TextField), 'ban công');
      await tester.pumpAndSettle();
      expect(find.text('1 loại phòng'), findsOneWidget);
      await tester.tap(find.text('Xem phòng'));
      await tester.pumpAndSettle();
      expect(find.text('Mây House · Studio đầy đủ nội thất'), findsOneWidget);
      expect(find.text('Phòng gác lửng Nhà Nâu'), findsNothing);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '0');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập số nguyên lớn hơn 0.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), '3');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Tối đa 3 người'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '5 người');
      await tester.pumpAndSettle();
      expect(find.text('0 phòng phù hợp'), findsOneWidget);
      expect(find.text('Tối đa 5 người'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
