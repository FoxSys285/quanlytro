import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_area_picker_page.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/discovery/services/tenant_location_service.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';
import 'package:quanlytro/pages/tenant/tenant_ui.dart';

class _Location extends TenantLocationService {
  final result = Completer<TenantAreaSelection>();
  int calls = 0;

  @override
  Future<Position> currentPosition() async =>
      throw const TenantLocationFailure('GPS tắt.');

  @override
  Future<TenantAreaSelection> currentArea() {
    calls++;
    return result.future;
  }
}

class _PointLocation extends _Location {
  final requests = <Completer<TenantAreaSelection>>[];
  @override
  Future<TenantAreaSelection> areaAt(double latitude, double longitude) {
    final request = Completer<TenantAreaSelection>();
    requests.add(request);
    return request.future;
  }
}

class _Maps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

class _Catalog implements TenantCatalogSource {
  final queries = <TenantCatalogQuery>[];

  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    queries.add(query);
    return CatalogPage(
      items: TenantRoomDemoData.listings
          .where(query.matches)
          .take(limit)
          .toList(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
  late GoogleMapsFlutterPlatform originalMaps;
  setUp(() {
    originalMaps = GoogleMapsFlutterPlatform.instance;
    GoogleMapsFlutterPlatform.instance = _Maps();
    TenantSelectedLocation.instance.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, (_) async => false);
  });
  tearDown(() {
    GoogleMapsFlutterPlatform.instance = originalMaps;
    TenantSelectedLocation.instance.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(locationChannel, null);
  });

  test('GPS city aliases match the stored city in catalog filters', () {
    final room = TenantRoomDemoData.listings.first;
    for (final city in ['Hồ Chí Minh', 'Ho Chi Minh City', 'TP.HCM']) {
      expect(TenantCatalogQuery(city: city).matches(room), isTrue);
    }
    expect(TenantCatalogQuery(city: 'Hà Nội').matches(room), isFalse);
    expect(
      const TenantCatalogQuery(
        city: 'Hồ Chí Minh',
        ward: 'Phường 2',
      ).matches(room),
      isFalse,
    );
  });

  test(
    'A missing ward filters by city instead of using a district as ward',
    () {
      final selection = TenantLocationService.selectionFromPlacemark(
        const Placemark(
          administrativeArea: 'Hồ Chí Minh',
          subAdministrativeArea: 'Bình Thạnh',
          locality: 'Ho Chi Minh City',
        ),
        10.8,
        106.7,
      );
      expect(selection.city, 'Hồ Chí Minh');
      expect(selection.ward, isNull);
      final withWard = TenantLocationService.selectionFromPlacemark(
        const Placemark(
          administrativeArea: 'Hồ Chí Minh',
          subLocality: 'Phường 25',
        ),
        10.8,
        106.7,
      );
      expect(withWard.ward, 'Phường 25');
      expect(
        () => TenantLocationService.selectionFromPlacemark(
          const Placemark(),
          10.8,
          106.7,
        ),
        throwsA(isA<TenantLocationFailure>()),
      );
    },
  );

  testWidgets('Room shortcut opens the room list without requesting GPS', (
    tester,
  ) async {
    final location = _Location();
    final catalog = _Catalog();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantDiscoveryPage(
            catalogSource: catalog,
            locationService: location,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nearby = find.byKey(const ValueKey('discovery-category-rooms'));
    await tester.ensureVisible(nearby);
    await tester.tap(nearby);
    await tester.pumpAndSettle();
    expect(location.calls, 0);
    expect(catalog.queries.last.city, isNull);
    expect(catalog.queries.last.ward, isNull);
    expect(catalog.queries.last.sort, 'default');
    expect(
      tester
          .widgetList<TenantDiscoveryPage>(find.byType(TenantDiscoveryPage))
          .any((page) => page.resultsOnly),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Location shortcut confirms a Google Maps point and opens filtered rooms',
    (tester) async {
      final location = _PointLocation();
      final catalog = _Catalog();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantDiscoveryPage(
              catalogSource: catalog,
              locationService: location,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final shortcut = find.byKey(
        const ValueKey('discovery-category-location'),
      );
      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      expect(find.text('Chọn vị trí'), findsOneWidget);
      tester.widget<GoogleMap>(find.byType(GoogleMap)).onLongPress!(
        const LatLng(10.8, 106.7),
      );
      await tester.pump();
      expect(catalog.queries, hasLength(1));
      location.requests.single.complete(
        const TenantAreaSelection(
          city: 'Hồ Chí Minh',
          ward: 'Phường 25',
          latitude: 10.8,
          longitude: 106.7,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('search-selected-map-area')));
      await tester.pumpAndSettle();
      expect(find.text('Danh sách phòng trọ'), findsOneWidget);
      expect(find.text('Chọn vị trí'), findsNothing);
      expect(catalog.queries.last.city, 'Hồ Chí Minh');
      expect(catalog.queries.last.ward, 'Phường 25');
      expect(find.text('Phường 25 · Hồ Chí Minh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('GPS denial keeps existing filters and shows a useful message', (
    tester,
  ) async {
    final location = _Location();
    final catalog = _Catalog();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantDiscoveryPage(
            catalogSource: catalog,
            locationService: location,
            resultsOnly: true,
            initialCity: 'Hà Nội',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final nearby = find.text('Vị trí hiện tại');
    await tester.ensureVisible(nearby);
    await tester.tap(nearby);
    location.result.completeError(
      const TenantLocationFailure('Hãy bật dịch vụ vị trí trên thiết bị.'),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Hãy bật dịch vụ vị trí trên thiết bị.'),
      ),
      findsOneWidget,
    );
    expect(catalog.queries.last.city, 'Hà Nội');
    expect(find.byType(TenantDiscoveryPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Explore keeps search and filter shortcuts; map opens the filtered list',
    (tester) async {
      final location = _PointLocation();
      final catalog = _Catalog();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantDiscoveryPage(
              catalogSource: catalog,
              locationService: location,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('explore-filter')), findsOneWidget);
      expect(find.byKey(const ValueKey('rental-list-filter')), findsNothing);
      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.onLongPress, isNotNull);
      expect(map.gestureRecognizers, isNotEmpty);
      map.onLongPress!(const LatLng(10.8, 106.7));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('search-selected-map-area')),
            )
            .onPressed,
        isNull,
      );
      location.requests.single.complete(
        const TenantAreaSelection(
          city: 'Hồ Chí Minh',
          ward: 'Phường 25',
          latitude: 10.8,
          longitude: 106.7,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tỉnh / Thành phố: Hồ Chí Minh'), findsOneWidget);
      expect(find.text('Xã / Phường: Phường 25'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('search-selected-map-area')),
      );
      await tester.tap(find.byKey(const ValueKey('search-selected-map-area')));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.city, 'Hồ Chí Minh');
      expect(catalog.queries.last.ward, 'Phường 25');
      expect(find.byKey(const ValueKey('rental-list-filter')), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Quay lại khám phá'));
      await tester.tap(find.byTooltip('Quay lại khám phá'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('explore-filter')), findsOneWidget);
      expect(find.byKey(const ValueKey('rental-list-filter')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Latest point wins; failed address lookup clears the old area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = _PointLocation();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 410,
            child: TenantAreaPickerPage(
              embedded: true,
              locationService: location,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    GoogleMap map() => tester.widget<GoogleMap>(find.byType(GoogleMap));
    map().onLongPress!(const LatLng(10.8, 106.7));
    map().onLongPress!(const LatLng(21.0, 105.8));
    location.requests[1].complete(
      const TenantAreaSelection(
        city: 'Hà Nội',
        ward: 'Phường Cầu Giấy',
        latitude: 21,
        longitude: 105.8,
      ),
    );
    await tester.pumpAndSettle();
    location.requests[0].complete(
      const TenantAreaSelection(
        city: 'Hồ Chí Minh',
        ward: 'Phường 25',
        latitude: 10.8,
        longitude: 106.7,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tỉnh / Thành phố: Hà Nội'), findsOneWidget);
    expect(map().markers.single.position, const LatLng(21, 105.8));
    map().markers.single.onDragEnd!(const LatLng(21.1, 105.9));
    location.requests.last.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Tỉnh / Thành phố: Hà Nội'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('search-selected-map-area')),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  for (final useKeyboard in [false, true]) {
    testWidgets(
      'Explore forwards search to list via ${useKeyboard ? 'keyboard' : 'search button'}',
      (tester) async {
        final catalog = _Catalog();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TenantDiscoveryPage(
                catalogSource: catalog,
                locationService: _Location(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Studio');
        await tester.pumpAndSettle();
        expect(catalog.queries, hasLength(1));
        expect(catalog.queries.single.query, isEmpty);
        if (useKeyboard) {
          await tester.testTextInput.receiveAction(TextInputAction.search);
        } else {
          await tester.tap(find.byTooltip('Tìm nhà trọ'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Danh sách phòng trọ'), findsOneWidget);
        expect(catalog.queries.last.query, 'Studio');
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Studio',
        );
        await tester.ensureVisible(find.byTooltip('Quay lại khám phá'));
        await tester.tap(find.byTooltip('Quay lại khám phá'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('explore-filter')), findsOneWidget);
        expect(find.text('Đang áp dụng'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Applying Explore filters opens the list with query and conditions',
    (tester) async {
      final catalog = _Catalog();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantDiscoveryPage(
              catalogSource: catalog,
              locationService: _Location(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Studio');
      await tester.tap(find.byKey(const ValueKey('explore-filter')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Mức tiền tối đa',
        ),
        '4000000',
      );
      final city = find.byKey(
        const ValueKey('location-input-Tỉnh / Thành phố'),
      );
      final ward = find.byKey(const ValueKey('location-input-Xã / Phường'));
      await tester.ensureVisible(city);
      await tester.enterText(city, 'Hồ Chí Minh');
      await tester.pumpAndSettle();
      await tester.ensureVisible(ward);
      await tester.enterText(ward, 'Phường 25');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('min-area')));
      await tester.enterText(find.byKey(const ValueKey('min-area')), '20');
      await tester.enterText(find.byKey(const ValueKey('max-area')), '35');
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Danh sách phòng trọ'), findsOneWidget);
      final query = catalog.queries.last;
      expect(query.query, 'Studio');
      expect(query.maxRent, 4000000);
      expect(query.city, 'Hồ Chí Minh');
      expect(query.ward, 'Phường 25');
      expect(query.minArea, 20);
      expect(query.maxArea, 35);
      await tester.ensureVisible(find.byTooltip('Quay lại khám phá'));
      await tester.tap(find.byTooltip('Quay lại khám phá'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('explore-filter')), findsOneWidget);
      expect(find.text('Đang áp dụng'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dismissing Explore filters does not open or filter the list', (
    tester,
  ) async {
    final catalog = _Catalog();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantDiscoveryPage(
            catalogSource: catalog,
            locationService: _Location(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('explore-filter')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Áp dụng bộ lọc'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Danh sách phòng trọ'), findsNothing);
    expect(catalog.queries, hasLength(1));
    expect(catalog.queries.single.city, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Choosing a map area on the list updates the current list route',
    (tester) async {
      final location = _PointLocation();
      final catalog = _Catalog();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantDiscoveryPage(
              resultsOnly: true,
              catalogSource: catalog,
              locationService: location,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn trên bản đồ'));
      await tester.pumpAndSettle();
      tester.widget<GoogleMap>(find.byType(GoogleMap)).onLongPress!(
        const LatLng(10.8, 106.7),
      );
      location.requests.single.complete(
        const TenantAreaSelection(
          city: 'Hồ Chí Minh',
          ward: 'Phường 25',
          latitude: 10.8,
          longitude: 106.7,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('search-selected-map-area')));
      await tester.pumpAndSettle();
      expect(find.byType(TenantDiscoveryPage), findsOneWidget);
      expect(catalog.queries.last.city, 'Hồ Chí Minh');
      expect(catalog.queries.last.ward, 'Phường 25');
      expect(tester.takeException(), isNull);
    },
  );

  test('Ward metadata can come from locality or sub-administrative area', () {
    for (final place in [
      const Placemark(administrativeArea: 'Hồ Chí Minh', locality: 'Phường 25'),
      const Placemark(
        administrativeArea: 'Hồ Chí Minh',
        subAdministrativeArea: 'Phường 25',
      ),
    ]) {
      expect(
        TenantLocationService.selectionFromPlacemark(place, 10.8, 106.7).ward,
        'Phường 25',
      );
    }
  });

  testWidgets(
    'List filters accept typed areas and clear ward when city changes',
    (tester) async {
      final catalog = _Catalog();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantDiscoveryPage(
              resultsOnly: true,
              catalogSource: catalog,
              locationService: _Location(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rental-list-filter')));
      await tester.pumpAndSettle();
      final city = find.byKey(
        const ValueKey('location-input-Tỉnh / Thành phố'),
      );
      final ward = find.byKey(const ValueKey('location-input-Xã / Phường'));
      await tester.ensureVisible(city);
      await tester.enterText(city, 'Tỉnh thử nghiệm');
      await tester.pumpAndSettle();
      await tester.ensureVisible(ward);
      await tester.enterText(ward, 'Xã thử nghiệm');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.city, 'Tỉnh thử nghiệm');
      expect(catalog.queries.last.ward, 'Xã thử nghiệm');
      await tester.ensureVisible(
        find.byKey(const ValueKey('rental-list-filter')),
      );
      await tester.tap(find.byKey(const ValueKey('rental-list-filter')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(city);
      await tester.enterText(city, 'Hà Nội');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(ward).controller!.text, isEmpty);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(catalog.queries.last.city, 'Hà Nội');
      expect(catalog.queries.last.ward, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
