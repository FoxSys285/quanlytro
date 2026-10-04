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
      await tester.tap(find.text('Thêm loại phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), ' studio ');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Tên loại phòng đã tồn tại.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Phòng đơn');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng đơn'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Sửa Phòng đơn'));
      await tester.tap(find.byTooltip('Sửa Phòng đơn'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Phòng đơn có cửa sổ');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng đơn'), findsNothing);
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
