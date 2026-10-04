import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
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
    expect(find.text('Xem phòng'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Room type add, rename and delete at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = LandlordDemoStore.demo();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordRoomTypesPage(store: store)),
        ),
      );
      expect(find.byType(ListTile), findsNWidgets(4));
      expect(find.text('3.000.000 đ/tháng'), findsOneWidget);
      expect(find.text('3.500.000 đ/tháng'), findsOneWidget);
      expect(find.text('2.800.000 đ/tháng'), findsOneWidget);
      expect(find.text('5.000.000 đ/tháng'), findsOneWidget);
      await tester.tap(find.text('Thêm loại phòng'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), ' studio ');
      await tester.enterText(fields.at(1), '2400000');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Tên loại phòng đã tồn tại.'), findsOneWidget);
      await tester.enterText(fields.at(0), 'Phòng đơn');
      await tester.enterText(fields.at(1), '0');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập giá thuê lớn hơn 0.'), findsOneWidget);
      expect(store.roomTypes.length, 4);
      await tester.enterText(fields.at(1), '2400000');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng đơn'), findsOneWidget);
      expect(find.text('2.400.000 đ/tháng'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Sửa Phòng đơn'));
      await tester.tap(find.byTooltip('Sửa Phòng đơn'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        '2400000',
      );
      await tester.enterText(fields.at(0), 'Phòng đơn có cửa sổ');
      await tester.enterText(fields.at(1), '2600000');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng đơn'), findsNothing);
      expect(find.text('2.600.000 đ/tháng'), findsOneWidget);
      expect(store.roomTypes.last.monthlyRent, 2600000);
      await tester.ensureVisible(find.byTooltip('Xóa Phòng đơn có cửa sổ'));
      await tester.tap(find.byTooltip('Xóa Phòng đơn có cửa sổ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng đơn có cửa sổ'), findsOneWidget);
      await tester.tap(find.byTooltip('Xóa Phòng đơn có cửa sổ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng đơn có cửa sổ'), findsNothing);
      expect(store.roomTypes.length, 4);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordRoomTypesPage(store: store)),
        ),
      );
      expect(find.byType(ListTile), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  }
}
