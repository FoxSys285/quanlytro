import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/services/landlord_dichvubanggia_page.dart';

void main() {
  testWidgets(
    'Service dialog validates, applies templates, edits, deletes and reloads',
    (tester) async {
      final previous = RentalPortfolio.instance;
      final portfolio = RentalPortfolio.seeded();
      RentalPortfolio.instance = portfolio;
      addTearDown(() {
        RentalPortfolio.instance = previous;
        portfolio.dispose();
      });
      final store = portfolio.active;

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LandlordDichVuBangGiaPage())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm dịch vụ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên dịch vụ.'), findsOneWidget);
      expect(find.text('Nhập đơn vị dịch vụ.'), findsOneWidget);
      expect(find.text('Nhập đơn giá là số nguyên không âm.'), findsOneWidget);
      expect(find.byType(EditableText), findsNWidgets(3));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Internet'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Internet',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '120000');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theo người').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      var service = store.services.singleWhere(
        (item) => item.id == 'service-1',
      );
      expect(service.name, 'Internet');
      expect(service.unit, 'phòng');
      expect(service.basis, 'Theo người');
      expect(service.price, 120000);
      final restored = RentalPortfolio.fromMap(portfolio.toMap());
      addTearDown(restored.dispose);
      expect(
        restored.active.services
            .singleWhere((item) => item.id == service.id)
            .price,
        120000,
      );

      await tester.ensureVisible(find.text('Internet').last);
      await tester.tap(find.text('Internet').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Wi-Fi');
      await tester.enterText(find.byType(TextFormField).at(1), 'căn');
      await tester.enterText(find.byType(TextFormField).at(2), '130000');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cố định').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      service = store.services.singleWhere((item) => item.id == service.id);
      expect(
        (service.name, service.unit, service.basis, service.price),
        ('Wi-Fi', 'căn', 'Cố định', 130000),
      );

      final restoredAfterEdit = RentalPortfolio.fromMap(portfolio.toMap());
      addTearDown(restoredAfterEdit.dispose);
      expect(
        restoredAfterEdit.active.services
            .singleWhere((item) => item.id == service.id)
            .name,
        'Wi-Fi',
      );
      await tester.tap(find.text('Wi-Fi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(store.services.any((item) => item.id == service.id), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Service dialog can close by back while editing without lifecycle errors',
    (tester) async {
      final previous = RentalPortfolio.instance;
      final portfolio = RentalPortfolio.seeded();
      RentalPortfolio.instance = portfolio;
      addTearDown(() {
        RentalPortfolio.instance = previous;
        portfolio.dispose();
      });
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LandlordDichVuBangGiaPage())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm dịch vụ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Draft');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LandlordDichVuBangGiaPage), findsOneWidget);
      expect(find.text('Thêm dịch vụ'), findsOneWidget);
      expect(
        portfolio.active.services.any((service) => service.name == 'Draft'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Switching active property updates service prices page', (
    tester,
  ) async {
    final previous = RentalPortfolio.instance;
    final portfolio = RentalPortfolio.seeded();
    RentalPortfolio.instance = portfolio;
    addTearDown(() {
      RentalPortfolio.instance = previous;
      portfolio.dispose();
    });
    portfolio.stores[1].saveService(
      name: 'Dịch vụ riêng nhà 2',
      unit: 'phòng',
      basis: 'Theo phòng',
      price: 55000,
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LandlordDichVuBangGiaPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dịch vụ riêng nhà 2'), findsNothing);

    portfolio.select(portfolio.stores[1].property.id);
    await tester.pumpAndSettle();
    expect(find.text('Dịch vụ riêng nhà 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
