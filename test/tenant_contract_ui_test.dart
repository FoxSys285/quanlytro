import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/payments/vietqr_service.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/tenant/invoices/components/tenant_bank_qr.dart';
import 'package:quanlytro/pages/tenant/leases/tenant_lease_contract_page.dart';
import 'package:quanlytro/pages/tenant/leases/components/tenant_lease_overview.dart';
import 'package:quanlytro/pages/tenant/tenant_detail_ui.dart';

import 'vietqr_service_test.dart' show bankResponse;

// A simple SVG fixture exercises decoding; it is never used as a payment QR.
const fixture =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect x="10" y="10" width="80" height="80" fill="black"/></svg>';

void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets(
      'Contract information and current payment account fit at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final rental = LandlordDemoStore.demo();
        addTearDown(rental.dispose);
        String? copiedAccount;
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            copiedAccount = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        final requested = <Uri>[];
        final client = MockClient((request) async {
          requested.add(request.url);
          return request.url.host == 'api.vietqr.io'
              ? bankResponse()
              : http.Response(fixture, 200);
        });
        addTearDown(client.close);
        final service = VietQrService(client: client);
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
              home: TenantSubpageScaffold(
                title: 'Hợp đồng thuê',
                appBar: TenantLeaseNavigationBar(onBack: () {}),
                child: TenantLeaseContractPage(
                  store: rental,
                  qrService: service,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (capture) {
          final context = tester.element(find.byType(TenantLeaseContractPage));
          final providers = tester
              .widgetList<Image>(find.byType(Image))
              .map((image) => image.image)
              .toList();
          await tester.runAsync(() async {
            for (final provider in providers) {
              await precacheImage(provider, context);
            }
          });
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        expect(find.text('Hợp đồng thuê\nphòng trọ'), findsOneWidget);
        expect(find.text('Tải hợp đồng'), findsNothing);
        expect(find.text('Xem chi tiết'), findsNothing);
        expect(find.text('BÊN CHO THUÊ'), findsOneWidget);
        expect(find.text('BÊN THUÊ'), findsOneWidget);
        expect(find.text('Dịch vụ & chi phí'), findsOneWidget);
        expect(find.text('Phương thức thanh toán'), findsOneWidget);
        expect(find.byType(SvgPicture), findsOneWidget);

        Future<void> screenshot(String section) async {
          if (!capture || width != 390) return;
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('.dart_tool/previews').create(recursive: true);
            await File('.dart_tool/previews/tenant_contract_$section.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await screenshot('overview');
        await tester.ensureVisible(find.text('BÊN CHO THUÊ'));
        await tester.pumpAndSettle();
        await screenshot('parties');
        await tester.ensureVisible(find.text('Sao chép STK'));
        await tester.pumpAndSettle();
        await screenshot('payment');
        expect(tester.takeException(), isNull);

        final alternative = rental.paymentAccounts.last;
        rental.setPaymentAccountActive(alternative, true);
        rental.setDefaultPaymentAccount(alternative);
        await tester.pumpAndSettle();
        final qr = tester.widget<TenantBankQr>(find.byType(TenantBankQr));
        expect(qr.accountNumber, '6688990011');
        expect(requested.last.path, '/image/970422-6688990011-qr_only.svg');
        expect(find.text('Số tài khoản trong hợp đồng'), findsOneWidget);
        expect(find.text('0123456789'), findsOneWidget);
        expect(requested.last.queryParameters.containsKey('amount'), isFalse);
        await tester.ensureVisible(find.text('Sao chép STK'));
        await tester.tap(find.text('Sao chép STK'));
        await tester.pumpAndSettle();
        expect(copiedAccount, '6688990011');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('QR failures keep bank details visible and support retry', (
    tester,
  ) async {
    var online = false;
    final client = MockClient((request) async {
      if (!online) return http.Response('Offline', 503);
      return request.url.host == 'api.vietqr.io'
          ? bankResponse()
          : http.Response(fixture, 200);
    });
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TenantBankQr(
              bankName: 'Vietcombank',
              accountNumber: '001234',
              service: VietQrService(client: client),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('001234'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
    online = true;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changing destination hides the old QR while the new one loads', (
    tester,
  ) async {
    final nextImage = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.host == 'api.vietqr.io') return bankResponse();
      return request.url.path.contains('998877')
          ? nextImage.future
          : http.Response(fixture, 200);
    });
    addTearDown(client.close);
    final service = VietQrService(client: client);
    Widget app(String number) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TenantBankQr(
            bankName: 'VCB',
            accountNumber: number,
            service: service,
          ),
        ),
      ),
    );
    await tester.pumpWidget(app('001234'));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    await tester.pumpWidget(app('998877'));
    await tester.pump();
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.text('Đang tạo mã QR…'), findsOneWidget);
    nextImage.complete(http.Response(fixture, 200));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets(
    'Tenant without a current contract sees an empty state and no payment QR',
    (tester) async {
      final rental = LandlordDemoStore.demo();
      addTearDown(rental.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantLeaseContractPage(
              store: rental,
              tenantId: '${TenantSession.tenantId}-missing',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa có hợp đồng đang hiệu lực'), findsOneWidget);
      expect(find.byType(TenantBankQr), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
