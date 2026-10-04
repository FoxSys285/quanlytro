import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_properties_page.dart';

void main() {
  testWidgets('Landlord owns a single property', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Nhà trọ')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LandlordPropertiesPage), findsOneWidget);
    expect(find.text('Nhà Nâu'), findsNothing);
    expect(find.text('Danh sách nhà trọ'), findsNothing);
    expect(find.text('Thông tin nhà trọ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Property edit and retained data at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = LandlordDemoStore.demo();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordPropertiesPage(store: store)),
        ),
      );
      expect(find.text('Mây House'), findsOneWidget);
      expect(find.text('0900000000'), findsOneWidget);
      await tester.ensureVisible(find.text('Chỉnh sửa thông tin'));
      await tester.tap(find.text('Chỉnh sửa thông tin'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.at(0));
      await tester.enterText(fields.at(0), 'Mây House mới');
      await tester.ensureVisible(fields.at(3));
      await tester.enterText(fields.at(3), 'abc');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại không hợp lệ.'), findsOneWidget);
      expect(store.property.name, 'Mây House');
      await tester.ensureVisible(fields.at(3));
      await tester.enterText(fields.at(3), '0912345678');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Mây House mới'), findsOneWidget);
      expect(find.text('0912345678'), findsOneWidget);
      expect(store.property.id, 'may');
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordPropertiesPage(store: store)),
        ),
      );
      expect(find.text('Mây House mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
