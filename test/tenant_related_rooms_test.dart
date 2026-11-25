import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_details_page.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';

class _RelatedRoomsSource implements TenantCatalogSource {
  _RelatedRoomsSource(this.current, this.firstRelated, this.secondRelated);

  final TenantRoomListing current;
  final TenantRoomListing firstRelated;
  final TenantRoomListing secondRelated;
  final calls = <(String?, Object?)>[];
  var failRelatedOnce = true;

  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    calls.add((query.roomCode, after));
    if (query.roomCode != null) {
      final rooms = [
        current,
        firstRelated,
        secondRelated,
      ].where((candidate) => candidate.roomCode == query.roomCode).toList();
      return CatalogPage(items: rooms);
    }
    if (failRelatedOnce) {
      failRelatedOnce = false;
      throw StateError('temporary catalogue failure');
    }
    if (after == null) {
      return CatalogPage(
        items: [current, firstRelated],
        nextCursor: 'related-page-2',
      );
    }
    return CatalogPage(items: [secondRelated]);
  }
}

TenantRoomListing _room({required String name, required String code}) =>
    TenantRoomListing(
      name: name,
      address: 'Example address',
      price: code == '101' ? 2000000 : 1500000,
      size: code == '101' ? '20 m²' : '22 m²',
      distance: '',
      roomType: 'Studio',
      city: 'Ho Chi Minh City',
      ward: 'Ward 1',
      distanceMeters: 0,
      electricityPrice: 3500,
      waterType: 'Theo m³',
      waterPrice: 3000,
      variant: 0,
      rating: '4.8',
      tags: const [],
      listingId: 'property-1-$code',
      ownerPropertyId: 'property-1',
      roomCode: code,
    );

void main() {
  testWidgets(
    'Related available rooms retry, paginate, and open a bookable room',
    (tester) async {
      final current = _room(name: 'Current room 101', code: '101');
      final firstRelated = _room(name: 'Related room 102', code: '102');
      final secondRelated = _room(name: 'Related room 103', code: '103');
      final source = _RelatedRoomsSource(current, firstRelated, secondRelated);
      TenantRoomListing? bookedRoom;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantRoomDetailsPage(
              room: current,
              onBook: () {},
              isFavorite: false,
              onFavoriteToggle: () {},
              catalogSource: source,
              onBookRoom: (room) => bookedRoom = room,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heading = find.text('Các phòng còn trống cùng nhà trọ');
      await tester.ensureVisible(heading);
      expect(find.text('Chưa tải được danh sách phòng.'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Related room 102'), findsOneWidget);
      expect(find.text('Related room 103'), findsNothing);
      expect(find.text('Current room 101'), findsOneWidget);
      expect(find.textContaining('22 m²'), findsOneWidget);
      expect(
        source.calls.where((call) => call.$2 == 'related-page-2'),
        isEmpty,
      );

      final loadMore = find.text('Tải thêm phòng');
      await tester.ensureVisible(loadMore);
      await tester.tap(loadMore);
      await tester.pumpAndSettle();
      expect(find.text('Related room 103'), findsOneWidget);
      expect(source.calls, contains((null, 'related-page-2')));

      await tester.tap(find.text('Related room 102'));
      await tester.pumpAndSettle();
      expect(find.text('Related room 102'), findsOneWidget);
      final booking = find
          .widgetWithText(FilledButton, 'Đặt lịch xem phòng')
          .hitTestable();
      await tester.ensureVisible(booking);
      await tester.tap(booking);
      await tester.pumpAndSettle();
      expect(bookedRoom?.roomCode, '102');
      expect(tester.takeException(), isNull);
    },
  );
}
