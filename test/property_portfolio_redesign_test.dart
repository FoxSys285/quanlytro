import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/landlord_navigation.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_theme.dart';
import 'package:quanlytro/pages/landlord/properties/components/property_portfolio_visuals.dart';
import 'package:quanlytro/pages/landlord/properties/components/landlord_property_editor.dart';
import 'package:quanlytro/pages/landlord/properties/property_portfolio_page.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_property_detail_page.dart';

void main() {
  late RentalPortfolio original;
  late RentalPortfolio portfolio;
  setUp(() {
    original = RentalPortfolio.instance;
    portfolio = RentalPortfolio([LandlordDemoStore.demo()]);
    RentalPortfolio.instance = portfolio;
  });
  tearDown(() {
    RentalPortfolio.instance = original;
    portfolio.dispose();
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Portfolio fits $width with dark=$dark after overview moved to dashboard',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: landlordTheme(dark: dark),
              home: const Scaffold(
                body: PropertyPortfolioPage(profileName: 'Trần Nguyên'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Trần Nguyên'), findsOneWidget);
          expect(find.byType(PropertyPortfolioSummary), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Search, filter reset and property drill down stay functional', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PropertyPortfolioPage())),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'không tồn tại');
    await tester.pump();
    expect(find.text('Không tìm thấy nhà trọ phù hợp.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nguyễn Gia Trí');
    await tester.pump();
    expect(find.text('Mây House'), findsOneWidget);
    await tester.tap(find.byTooltip('Lọc nhà trọ'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Còn phòng'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);
    await tester.ensureVisible(find.byTooltip('Xem phòng'));
    await tester.tap(find.byTooltip('Xem phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordPropertyDetailPage), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại danh sách nhà trọ'));
    await tester.pumpAndSettle();
    expect(find.text('Danh sách nhà trọ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty portfolio can open the create form', (tester) async {
    portfolio.dispose();
    portfolio = RentalPortfolio([]);
    RentalPortfolio.instance = portfolio;
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PropertyPortfolioPage())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PropertyPortfolioSummary), findsNothing);
    await tester.ensureVisible(find.text('Thêm nhà trọ'));
    await tester.tap(find.text('Thêm nhà trọ'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordPropertyEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Property tab has one profile header and opens settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LandlordLayout(displayName: 'Trần Nguyên')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(LandlordBottomNavigation),
        matching: find.text('Nhà trọ'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PropertyProfileHeader), findsOneWidget);
    expect(find.text('Trần Nguyên'), findsOneWidget);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Danh sách nhà trọ'), findsNothing);
    expect(find.byType(LandlordBottomNavigation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
