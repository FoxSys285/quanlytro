import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_discovery_filter_sheet.dart';
import 'package:quanlytro/pages/tenant/discovery/services/tenant_administrative_service.dart';

http.Response _json(Object value) =>
    http.Response.bytes(utf8.encode(jsonEncode(value)), 200);

Future<void> _open(
  WidgetTester tester,
  TenantAdministrativeService service, {
  String? city,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TenantDiscoveryFilterSheet(
          administrativeService: service,
          initialRent: 20000000,
          initialCity: city,
          initialWard: null,
          initialElectricityRange: const RangeValues(0, 5),
          initialWaterType: 'Tất cả',
          initialArea: null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Selects and searches API provinces and dependent wards', (
    tester,
  ) async {
    final calls = <Uri>[];
    final service = TenantAdministrativeService(
      client: MockClient((request) async {
        calls.add(request.url);
        if (request.url.path == '/api/v2/p/') {
          return _json([
            {'code': 79, 'name': 'Thành phố Hồ Chí Minh'},
            {'code': 1, 'name': 'Thành phố Hà Nội'},
          ]);
        }
        return _json({
          'wards': [
            {'code': 26734, 'name': 'Phường Thủ Đức'},
          ],
        });
      }),
    );
    await _open(tester, service);
    final ward = find.byKey(const ValueKey('location-input-Xã / Phường'));
    expect(tester.widget<TextField>(ward).enabled, isFalse);
    await tester.ensureVisible(find.byTooltip('Chọn tỉnh / thành phố'));
    await tester.tap(find.byTooltip('Chọn tỉnh / thành phố'));
    await tester.pumpAndSettle();
    expect(find.text('Thành phố Hà Nội'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tìm trong danh sách'),
      'Hồ Chí Minh',
    );
    await tester.pumpAndSettle();
    expect(find.text('Thành phố Hà Nội'), findsNothing);
    await tester.tap(find.text('Thành phố Hồ Chí Minh'));
    await tester.pumpAndSettle();
    expect(calls.last.path, '/api/v2/p/79');
    await tester.ensureVisible(find.byTooltip('Chọn xã / phường'));
    await tester.tap(find.byTooltip('Chọn xã / phường'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phường Thủ Đức'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(ward).controller!.text, 'Phường Thủ Đức');
    final city = find.byKey(const ValueKey('location-input-Tỉnh / Thành phố'));
    await tester.enterText(city, 'Hà Nội');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(ward).controller!.text, isEmpty);
    expect(calls.last.path, '/api/v2/p/1');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Retries province failures and ignores old ward responses after reset',
    (tester) async {
      var provinceCalls = 0;
      final pendingWards = Completer<http.Response>();
      final service = TenantAdministrativeService(
        client: MockClient((request) async {
          if (request.url.path == '/api/v2/p/') {
            if (++provinceCalls == 1) return http.Response('', 503);
            return _json([
              {'code': 79, 'name': 'Thành phố Hồ Chí Minh'},
            ]);
          }
          return pendingWards.future;
        }),
      );
      await _open(tester, service, city: 'TP.HCM');
      expect(
        find.textContaining('Không tải được danh sách tỉnh'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.ensureVisible(find.text('Đặt lại'));
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
      pendingWards.complete(
        _json({
          'wards': [
            {'code': 1, 'name': 'Phường cũ'},
          ],
        }),
      );
      await tester.pumpAndSettle();
      final ward = find.byKey(const ValueKey('location-input-Xã / Phường'));
      expect(tester.widget<TextField>(ward).enabled, isFalse);
      expect(tester.widget<TextField>(ward).controller!.text, isEmpty);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
