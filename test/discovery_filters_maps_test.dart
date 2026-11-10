import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/shared/widgets/google_maps_actions.dart';
import 'package:quanlytro/pages/shared/widgets/list_pagination.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_discovery_filter_sheet.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_card.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';

void main() {
  test('Google Maps encodes Vietnamese address and reserved characters', () {
    const address = '25/2 Nguyễn Gia Trí & Nhà #1, Bình Thạnh';
    final uri = googleMapsSearchUri(' $address ');
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters, {'api': '1', 'query': address});
    expect(uri.fragment, isEmpty);
  });

  test('Google Maps directions use exact coordinates when available', () {
    final uri = googleMapsDirectionsUri(
      '25 Nguyễn Gia Trí',
      latitude: 10.812345,
      longitude: 106.654321,
    );
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], '10.812345,106.654321');
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(
      googleMapsDirectionsUri('25 Nguyễn Gia Trí')
          .queryParameters['destination'],
      '25 Nguyễn Gia Trí',
    );
  });

  testWidgets('Map launch failure offers copy and copies complete URL', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleMapsActions(
            address: '25 Nguyễn Gia Trí',
            launch: (_) async => false,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở Google Maps'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không mở được bản đồ. Hãy sao chép liên kết.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Sao chép liên kết'));
    await tester.pumpAndSettle();
    expect(Uri.parse(copied!).queryParameters['query'], '25 Nguyễn Gia Trí');
  });

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Discovery sorts, saves query/sort/page on recreation at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bucket = PageStorageBucket();
        Widget app(bool visible) => MaterialApp(
          home: Scaffold(
            body: PageStorage(
              bucket: bucket,
              child: visible
                  ? const TenantDiscoveryPage(
                      tenantId: 'filter-test',
                      resultsOnly: true,
                    )
                  : const SizedBox(),
            ),
          ),
        );
        await tester.pumpWidget(app(true));
        await tester.pumpAndSettle();
        final dropdown = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Giá thuê giảm dần').last);
        await tester.pumpAndSettle();
        final cards = tester
            .widgetList<TenantRoomCard>(find.byType(TenantRoomCard))
            .toList();
        expect(cards.length, greaterThan(1));
        for (var i = 1; i < cards.length; i++) {
          expect(
            cards[i - 1].room.price,
            greaterThanOrEqualTo(cards[i].room.price),
          );
        }
        await tester.ensureVisible(find.byTooltip('Trang tiếp theo'));
        await tester.tap(find.byTooltip('Trang tiếp theo'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<ListPagination>(find.byType(ListPagination)).page,
          1,
        );
        await tester.pumpWidget(app(false));
        await tester.pumpAndSettle();
        await tester.pumpWidget(app(true));
        await tester.pumpAndSettle();
        expect(
          tester.widget<ListPagination>(find.byType(ListPagination)).page,
          1,
        );
        expect(find.text('Giá thuê giảm dần'), findsOneWidget);
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Studio');
        await tester.pumpAndSettle();
        await tester.pumpWidget(app(false));
        await tester.pumpAndSettle();
        await tester.pumpWidget(app(true));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Studio',
        );
        expect(
          tester.widget<ListPagination>(find.byType(ListPagination)).page,
          0,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Area validation and amenity selection at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TenantDiscoveryFilterSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result =
                      await showModalBottomSheet<
                        TenantDiscoveryFilterSelection
                      >(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const TenantDiscoveryFilterSheet(
                          initialRent: 20000000,
                          initialCity: null,
                          initialWard: null,
                          initialElectricityRange: RangeValues(0, 5),
                          initialWaterType: 'Tất cả',
                          initialArea: null,
                        ),
                      );
                },
                child: const Text('Lọc'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Lọc'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('min-area')));
      await tester.enterText(find.byKey(const ValueKey('min-area')), '30');
      await tester.enterText(find.byKey(const ValueKey('max-area')), '20');
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nhập diện tích hợp lệ; từ không vượt quá đến.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('max-area')));
      await tester.enterText(find.byKey(const ValueKey('max-area')), '40,5');
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Ban công'));
      await tester.tap(find.widgetWithText(FilterChip, 'Ban công'));
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(result!.minArea, 30);
      expect(result!.maxArea, 40.5);
      expect(result!.amenities, contains('Ban công'));
      expect(tester.takeException(), isNull);
    });
  }
}
