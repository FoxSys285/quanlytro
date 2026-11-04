import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/payments/vietqr_service.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/tenant/invoices/components/tenant_bank_qr.dart';
import 'package:quanlytro/pages/tenant/invoices/components/tenant_invoice_dashboard_widgets.dart';
import 'package:quanlytro/pages/tenant/invoices/tenant_invoice_detail_page.dart';
import 'package:quanlytro/pages/tenant/invoices/tenant_invoices_page.dart';
import 'package:quanlytro/pages/tenant/invoices/tenant_payment_history_page.dart';
import 'package:quanlytro/pages/tenant/leases/tenant_home_page.dart';
import 'package:quanlytro/pages/tenant/tenant_detail_ui.dart';
import 'package:quanlytro/pages/tenant/tenant_page_router.dart';

import 'vietqr_service_test.dart' show bankResponse;

LandlordInvoice issue(
  LandlordDemoStore store,
  int month, {
  int amount = 2500000,
}) => store.createInvoice(
  lease: store.currentLeaseForTenant(TenantSession.tenantId)!,
  period: DateTime(2026, month),
  dueDate: DateTime(2026, month, 25),
  charges: [LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: amount)],
);

void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets(
      'Invoice dashboard fits and quick actions open real flows at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final rental = LandlordDemoStore.demo();
        addTearDown(rental.dispose);
        rental.approvePayment(
          rental.payments.first,
          rental.payments.first.reportedAmount,
        );
        final current = issue(rental, 11);
        final requested = <Uri>[];
        final client = MockClient((request) async {
          requested.add(request.url);
          return request.url.host == 'api.vietqr.io'
              ? bankResponse()
              : http.Response(
                  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100"/></svg>',
                  200,
                );
        });
        addTearDown(client.close);
        final service = VietQrService(client: client);
        await tester.pumpWidget(
          MaterialApp(
            home: TenantSubpageScaffold(
              title: 'Hóa đơn và Thanh toán',
              appBar: TenantInvoiceNavigationBar(onBack: () {}, store: rental),
              child: TenantInvoicesPage(store: rental, qrService: service),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Hóa đơn hiện tại'), findsOneWidget);
        expect(find.text('Hạn thanh toán: 25/11/2026'), findsOneWidget);
        expect(find.text('2.500.000đ'), findsOneWidget);
        expect(
          requested,
          isEmpty,
          reason: 'QR is loaded only when payment methods are opened',
        );

        await tester.ensureVisible(find.text('Xem chi tiết\nhóa đơn'));
        await tester.tap(find.text('Xem chi tiết\nhóa đơn'));
        await tester.pumpAndSettle();
        expect(find.byType(TenantInvoiceDetailPage), findsOneWidget);
        expect(find.text(current.id), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại').first);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Phương thức\nthanh toán'));
        await tester.tap(find.text('Phương thức\nthanh toán'));
        await tester.pumpAndSettle();
        expect(find.byType(TenantBankQr), findsOneWidget);
        expect(requested.last.queryParameters['amount'], '2500000');
        expect(
          requested.last.queryParameters['addInfo'],
          current.id.replaceAll('-', ' '),
        );
        Navigator.of(tester.element(find.byType(TenantBankQr))).pop();
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Lịch sử\nthanh toán'));
        await tester.tap(find.text('Lịch sử\nthanh toán'));
        await tester.pumpAndSettle();
        expect(find.byType(TenantPaymentHistoryPage), findsOneWidget);
        expect(find.text('Thành công'), findsOneWidget);
        await tester.tap(find.text('Tất cả hóa đơn'));
        await tester.pumpAndSettle();
        expect(find.text(current.id), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại').first);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Hỗ trợ\nthanh toán'));
        await tester.tap(find.text('Hỗ trợ\nthanh toán'));
        await tester.pumpAndSettle();
        expect(find.text('Hỗ trợ thanh toán'), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại').first);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('invoice-pay-now')),
        );
        await tester.tap(find.byKey(const ValueKey('invoice-pay-now')));
        await tester.pumpAndSettle();
        expect(find.text('Thanh toán hóa đơn'), findsOneWidget);
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.last, 'UI-PAYMENT-TEST');
        await tester.ensureVisible(find.text('Gửi thanh toán'));
        await tester.tap(find.text('Gửi thanh toán'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Đang chờ xác nhận'), findsOneWidget);
        expect(
          current.paidAmount,
          0,
          reason: 'Submitting a report is not confirmation',
        );
        final payment = rental.payments.firstWhere(
          (payment) => payment.invoiceId == current.id,
        );
        rental.approvePayment(payment, 1000000);
        await tester.pumpAndSettle();
        expect(find.text('1.500.000đ'), findsOneWidget);
        expect(find.text('Thanh toán ngay'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('Invoice selection and empty state follow outstanding balances', (
    tester,
  ) async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final next = issue(rental, 11);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TenantInvoicesPage(store: rental)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang chờ xác nhận'), findsOneWidget);
    await tester.ensureVisible(find.text('Còn 2 hóa đơn cần thanh toán'));
    await tester.tap(find.text('Còn 2 hóa đơn cần thanh toán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tháng 11/2026'));
    await tester.pumpAndSettle();
    expect(find.text('Hạn thanh toán: 25/11/2026'), findsOneWidget);
    expect(find.text('Thanh toán ngay'), findsOneWidget);
    rental.approvePayment(
      rental.payments.first,
      rental.payments.first.reportedAmount,
    );
    rental.cancelInvoice(next);
    await tester.pumpAndSettle();
    expect(find.text('Bạn không còn hóa đơn cần trả'), findsOneWidget);
    expect(find.byKey(const ValueKey('invoice-pay-now')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tenant without invoices sees no other tenant amounts', (
    tester,
  ) async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantInvoicesPage(store: rental, tenantId: 'tenant-missing'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có hóa đơn'), findsOneWidget);
    expect(find.text('Chưa có giao dịch thanh toán'), findsOneWidget);
    expect(find.byType(TenantInvoiceTransactionTile), findsNothing);
    expect(find.byType(TenantCurrentInvoiceCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Invoice navigation stays in the tenant shell with four working tabs',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final rental = LandlordDemoStore.demo();
      addTearDown(rental.dispose);
      rental.approvePayment(
        rental.payments.first,
        rental.payments.first.reportedAmount,
      );
      for (final month in [8, 9]) {
        final invoice = issue(rental, month);
        final payment = rental.submitPayment(
          tenantId: TenantSession.tenantId,
          invoiceId: invoice.id,
          amount: invoice.total,
          reference: 'PREVIEW-$month',
          method: 'Chuyển khoản',
        );
        rental.approvePayment(payment, invoice.total);
      }
      issue(rental, 11);
      final capture = Platform.environment['CAPTURE_TENANT_UI'] == 'true';
      final boundaryKey = GlobalKey();
      if (capture) {
        await tester.runAsync(() async {
          await (FontLoader('PreviewFont')..addFont(
                Future.value(
                  ByteData.sublistView(
                    File('C:/Windows/Fonts/arial.ttf').readAsBytesSync(),
                  ),
                ),
              ))
              .load();
          await (FontLoader('MaterialIcons')..addFont(
                Future.value(
                  ByteData.sublistView(
                    File(
                      'D:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                    ).readAsBytesSync(),
                  ),
                ),
              ))
              .load();
        });
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: capture ? 'PreviewFont' : null,
            ),
            home: TenantLayout(
              pageBuilder: (context, destination) => switch (destination.id) {
                'discovery' => const SizedBox(),
                'my_lease' => TenantHomePage(store: rental),
                'invoices' => TenantInvoicesPage(store: rental),
                _ => buildTenantPage(context, destination),
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thanh toán'));
      await tester.tap(find.text('Thanh toán'));
      await tester.pumpAndSettle();
      expect(find.byType(TenantInvoicesPage), findsOneWidget);
      expect(find.byType(TenantInvoiceNavigationBar), findsOneWidget);
      expect(find.text('Hợp đồng thuê'), findsNothing);
      expect(find.byType(TenantInvoiceTransactionTile), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      if (capture) {
        final context = tester.element(find.byType(TenantInvoicesPage));
        final images = tester
            .widgetList<Image>(find.byType(Image))
            .map((widget) => widget.image)
            .toList();
        await tester.runAsync(() async {
          for (final image in images) {
            await precacheImage(image, context);
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('.dart_tool/previews').create(recursive: true);
          await File('.dart_tool/previews/tenant_invoice_dashboard.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byTooltip('Quay lại').first);
      await tester.pumpAndSettle();
      expect(find.byType(TenantHomePage), findsOneWidget);
      await tester.ensureVisible(find.text('Xem hợp đồng'));
      await tester.tap(find.text('Xem hợp đồng'));
      await tester.pumpAndSettle();
      expect(find.text('Hợp đồng thuê\nphòng trọ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
