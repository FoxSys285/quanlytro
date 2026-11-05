import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_home.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/discovery/services/tenant_location_service.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_details_page.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';

class _NoLocation extends TenantLocationService {
  @override
  Future<Position> currentPosition() async =>
      throw const TenantLocationFailure('GPS tắt.');
}

class _Source implements TenantCatalogSource, TenantDiscoveryHomeSource {
  final homeLimits = <int>[];
  final requests = <Completer<DiscoveryHomeFeed>>[];
  final listCursors = <Object?>[];
  final listLimits = <int>[];
  @override
  Future<DiscoveryHomeFeed> fetchHome({int limit = 10}) {
    homeLimits.add(limit);
    final request = Completer<DiscoveryHomeFeed>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    listCursors.add(after);
    listLimits.add(limit);
    return CatalogPage(
      items: _rooms(after == null ? 'first' : 'next').take(limit).toList(),
      nextCursor: after == null ? 'page-2' : null,
    );
  }
}

List<TenantRoomListing> _rooms(String name) => List.generate(
  10,
  (i) => TenantRoomListing(
    listingId: '$name-$i',
    ownerPropertyId: 'remote-property',
    name: 'Phòng $name $i',
    address: 'Địa chỉ',
    price: 2000000 + i * 100000,
    size: '25 m²',
    distance: '',
    roomType: 'Studio',
    city: 'TP. Hồ Chí Minh',
    ward: 'Phường 25',
    distanceMeters: 0,
    electricityPrice: 3500,
    waterType: 'Theo m³',
    waterPrice: 20000,
    variant: 0,
    rating: '—',
    tags: const [],
    roomCode: 'P.$i',
  ),
);

DiscoveryHomeFeed _feed(String name) {
  final rooms = _rooms(name);
  return DiscoveryHomeFeed(featured: rooms, goodPrice: rooms, trusted: rooms);
}

Future<void> _mounted(WidgetTester tester, _Source source) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TenantLayout(
        pageBuilder: (context, destination) => destination.id == 'discovery'
            ? TenantDiscoveryPage(
                catalogSource: source,
                locationService: _NoLocation(),
              )
            : const Center(child: Text('Trang khác')),
      ),
    ),
  );
  await tester.pump();
  source.requests.single.complete(_feed('saved'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Returning to Explore keeps its state, scroll offset and ten-room preview without refetching',
    (tester) async {
      final source = _Source();
      await _mounted(tester, source);
      final discoveryState = tester.state(find.byType(TenantDiscoveryPage));
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const PageStorageKey('discovery-home-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scroll.position.jumpTo(250);
      await tester.pump();
      await tester.tap(find.text('Tin nhắn').last);
      await tester.pumpAndSettle();
      expect(find.text('Trang khác'), findsOneWidget);
      await tester.tap(find.text('Khám phá').last);
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(TenantDiscoveryPage)),
        same(discoveryState),
      );
      expect(scroll.position.pixels, 250);
      expect(source.homeLimits, [10]);
      final home = tester.widget<TenantDiscoveryHome>(
        find.byType(TenantDiscoveryHome),
      );
      expect(home.visibleRooms, hasLength(10));
      expect(home.homeFeed!.goodPrice, hasLength(10));
      expect(home.homeFeed!.trusted, hasLength(10));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Pull down refresh shows the indicator, coalesces requests and preserves old content until success',
    (tester) async {
      final source = _Source();
      await _mounted(tester, source);
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const PageStorageKey('discovery-home-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scroll.position.jumpTo(0);
      await tester.pump();
      final gesture = await tester.startGesture(const Offset(400, 130));
      await gesture.moveBy(const Offset(0, 350));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(source.homeLimits, [10, 10]);
      var home = tester.widget<TenantDiscoveryHome>(
        find.byType(TenantDiscoveryHome),
      );
      expect(home.visibleRooms.first.id, 'saved-0');
      expect(home.loading, isFalse);
      final refresh = tester.widget<RefreshIndicator>(
        find.byKey(const ValueKey('discovery-pull-to-refresh')),
      );
      final duplicate = refresh.onRefresh();
      expect(source.requests, hasLength(2));
      source.requests.last.complete(_feed('fresh'));
      await duplicate;
      await tester.pumpAndSettle();
      home = tester.widget<TenantDiscoveryHome>(
        find.byType(TenantDiscoveryHome),
      );
      expect(home.visibleRooms.first.id, 'fresh-0');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'A failed manual refresh keeps the previous preview and can be retried',
    (tester) async {
      final source = _Source();
      await _mounted(tester, source);
      final refresh = tester.widget<RefreshIndicator>(
        find.byKey(const ValueKey('discovery-pull-to-refresh')),
      );
      final pending = refresh.onRefresh();
      source.requests.last.completeError(StateError('Offline'));
      await pending;
      await tester.pumpAndSettle();
      final home = tester.widget<TenantDiscoveryHome>(
        find.byType(TenantDiscoveryHome),
      );
      expect(home.visibleRooms.first.id, 'saved-0');
      expect(home.hasError, isFalse);
      expect(
        find.text('Chưa làm mới được. Danh sách hiện tại vẫn được giữ lại.'),
        findsOneWidget,
      );
      final retry = refresh.onRefresh();
      source.requests.last.complete(_feed('retry'));
      await retry;
      await tester.pumpAndSettle();
      expect(source.homeLimits, [10, 10, 10]);
      expect(
        tester
            .widget<TenantDiscoveryHome>(find.byType(TenantDiscoveryHome))
            .visibleRooms
            .first
            .id,
        'retry-0',
      );
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Viewing a room loads only its missing owner without inserting the public portfolio',
    (tester) async {
      final calls = <String>[];
      final request = Completer<LandlordProperty?>();
      final originalProperties = RentalPortfolio.instance.stores.length;
      await tester.pumpWidget(
        MaterialApp(
          home: TenantRoomDetailsPage(
            room: _rooms('details').first,
            onBook: () {},
            isFavorite: false,
            onFavoriteToggle: () {},
            propertyLoader: (id) {
              calls.add(id);
              return request.future;
            },
          ),
        ),
      );
      expect(calls, ['remote-property']);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Gọi ngay'),
            )
            .onPressed,
        isNull,
      );
      request.complete(
        const LandlordProperty(
          id: 'remote-property',
          name: 'Nhà trọ được chọn',
          address: 'Địa chỉ',
          ownerName: 'Chủ trọ được chọn',
          phone: '0912345678',
          description: 'Mô tả nhà trọ',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chủ trọ được chọn'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Gọi ngay'),
            )
            .onPressed,
        isNotNull,
      );
      expect(RentalPortfolio.instance.stores.length, originalProperties);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
