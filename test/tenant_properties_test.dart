import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/data/property_catalog.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/models/landlord_property.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_property_listing.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_properties_page.dart';
import 'package:quanlytro/pages/tenant/discovery/services/tenant_location_service.dart';

class _NoLocation extends TenantLocationService {
  @override
  Future<Position> currentPosition() async =>
      throw const TenantLocationFailure('GPS tắt.');
}

class _Properties implements TenantPropertyCatalogSource {
  _Properties(this.items);
  final List<TenantPropertyListing> items;
  final queries = <TenantPropertyQuery>[];

  @override
  Future<PropertyCatalogPage> fetch(
    TenantPropertyQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    queries.add(query);
    return PropertyCatalogPage(
      items: items.where(query.matches).take(limit).toList(),
    );
  }
}

class _Rooms implements TenantCatalogSource {
  final queries = <TenantCatalogQuery>[];
  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    queries.add(query);
    return CatalogPage(
      items: TenantRoomDemoData.allListings
          .where(query.matches)
          .take(limit)
          .toList(),
    );
  }
}

class _DelayedProperties implements TenantPropertyCatalogSource {
  final pending = <Completer<PropertyCatalogPage>>[];
  final queries = <TenantPropertyQuery>[];
  final cursors = <Object?>[];

  @override
  Future<PropertyCatalogPage> fetch(
    TenantPropertyQuery query, {
    Object? after,
    int limit = 8,
  }) {
    queries.add(query);
    cursors.add(after);
    final request = Completer<PropertyCatalogPage>();
    pending.add(request);
    return request.future;
  }
}

void main() {
  testWidgets(
    'Property search discards stale responses and paginates with cached previous pages',
    (tester) async {
      final rental = LandlordDemoStore.demo();
      addTearDown(rental.dispose);
      final listing = TenantPropertyListing.fromStore(rental, verified: true);
      final source = _DelayedProperties();
      await tester.pumpWidget(
        MaterialApp(
          home: TenantPropertiesPage(
            catalogSource: source,
            onPropertySelected: (_) {},
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Mây');
      await tester.pump(const Duration(milliseconds: 350));
      expect(source.pending, hasLength(2));
      source.pending[0].complete(const PropertyCatalogPage(items: []));
      source.pending[1].complete(
        PropertyCatalogPage(items: [listing], nextCursor: 'next-property'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('property-card-may')), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Trang tiếp theo'));
      await tester.tap(find.byTooltip('Trang tiếp theo'));
      await tester.pump();
      expect(source.cursors.last, 'next-property');
      source.pending[2].complete(const PropertyCatalogPage(items: []));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Trang trước'));
      await tester.tap(find.byTooltip('Trang trước'));
      await tester.pumpAndSettle();
      expect(source.pending, hasLength(3));
      expect(find.byKey(const ValueKey('property-card-may')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Verified property request can retry without showing unverified local data',
    (tester) async {
      final source = _DelayedProperties();
      await tester.pumpWidget(
        MaterialApp(
          home: TenantPropertiesPage(
            verifiedOnly: true,
            catalogSource: source,
            onPropertySelected: (_) {},
          ),
        ),
      );
      source.pending.single.completeError(Exception('Offline'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được danh sách nhà trọ'), findsOneWidget);
      expect(find.byKey(const ValueKey('property-card-may')), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(source.queries.last.verifiedOnly, isTrue);
      source.pending.last.complete(const PropertyCatalogPage(items: []));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có nhà trọ đã xác minh'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('Published verification needs an admin approval matching the current property data', () {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final raw = rental.toMap();
    final proof = propertyVerificationProof(raw);
    Map<String, dynamic> document(String savedProof) => encodeCloudDocuments(
      {
        'portfolio': {
          'properties': [raw],
        },
        'admin': {
          'verified': {'may': true},
          'verificationProofs': {'may': savedProof},
        },
      },
      owners: {'may': 'owner'},
    )['rental_properties/may']!;
    expect(
      TenantPropertyListing.fromMap(document('old-proof')).verified,
      isFalse,
    );
    final verified = document(proof);
    expect(TenantPropertyListing.fromMap(verified).verified, isTrue);
    final data = Map<String, dynamic>.from(verified['data'] as Map);
    data['property'] = {...data['property'] as Map, 'name': 'Changed property'};
    expect(
      TenantPropertyListing.fromMap({...verified, 'data': data}).verified,
      isFalse,
    );
    expect(TenantPropertyListing.fromMap(document('')).verified, isFalse);
    final listing = TenantPropertyListing.fromStore(rental, verified: false);
    expect(listing.roomCount, rental.catalog.length);
    expect(
      TenantCatalogQuery(propertyId: 'other')
          .matches(TenantRoomDemoData.listings.first),
      isFalse,
    );
  });

  test('Demo metadata never substitutes a valid proof and cloud approvals replace stale cached flags', () {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final data = rental.toMap();
    final proof = propertyVerificationProof(data);
    final document = <String, dynamic>{
      'data': data,
      'verified': true,
      'verificationProof': proof,
      'isDemo': true,
      'verification': {
        'scope': 'demo',
        'status': 'verified',
        'note': 'Dữ liệu mẫu',
      },
    };
    final listing = TenantPropertyListing.fromMap(document);
    expect(listing.isDemoVerification, isTrue);
    expect(listing.verificationLabel, 'Đã xác minh · mẫu');
    final admin = <String, dynamic>{
      'verified': {'may': false, 'other': true},
      'verificationProofs': {'may': 'old-proof', 'other': 'other-proof'},
    };
    restoreCloudPropertyVerification(admin, [document]);
    expect(admin['verified'], {'may': true, 'other': true});
    expect(admin['verificationProofs']['may'], proof);
    final stale = {...document, 'verificationProof': 'outdated'};
    expect(TenantPropertyListing.fromMap(stale).verified, isFalse);
    restoreCloudPropertyVerification(admin, [stale]);
    expect(admin['verified']['may'], isFalse);
    expect(admin['verified']['other'], isTrue);
  });

  testWidgets(
    'Verified demo properties show the sample label on small screens with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.reset);
      final rental = LandlordDemoStore.demo();
      addTearDown(rental.dispose);
      final source = _Properties([
        TenantPropertyListing(
          property: rental.property,
          roomCount: 5,
          minRent: 2500000,
          verified: true,
          verificationScope: 'demo',
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: TenantPropertiesPage(
            verifiedOnly: true,
            catalogSource: source,
            onPropertySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đã xác minh · mẫu'), findsOneWidget);
      expect(
        find.text('Dữ liệu mẫu, chưa kiểm chứng ngoài thực tế.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets(
      'Four shortcuts, property search, verification and property rooms at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final rental = LandlordDemoStore.demo();
        addTearDown(rental.dispose);
        final properties = _Properties([
          TenantPropertyListing.fromStore(rental, verified: true),
          TenantPropertyListing(
            property: LandlordProperty.fromMap({
              ...rental.property.toMap(),
              'id': 'unverified',
              'name': 'Nhà chưa xác minh',
            }),
            roomCount: 4,
            minRent: 2000000,
            verified: false,
          ),
        ]);
        final rooms = _Rooms();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TenantDiscoveryPage(
                catalogSource: rooms,
                propertyCatalogSource: properties,
                locationService: _NoLocation(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final shortcuts = [
          for (final id in ['rooms', 'properties', 'verified', 'location'])
            find.byKey(ValueKey('discovery-category-$id')),
        ];
        for (var index = 0; index < shortcuts.length; index++) {
          expect(shortcuts[index], findsOneWidget);
          if (index > 0) {
            expect(
              tester.getRect(shortcuts[index]).left,
              greaterThan(tester.getRect(shortcuts[index - 1]).left),
            );
          }
        }
        await tester.ensureVisible(shortcuts[1]);
        await tester.tap(shortcuts[1]);
        await tester.pumpAndSettle();
        expect(find.byType(TenantPropertiesPage), findsOneWidget);
        expect(find.byKey(const ValueKey('property-card-may')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('property-card-unverified')),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(ChoiceChip, 'Đã xác minh'));
        await tester.pumpAndSettle();
        expect(properties.queries.last.verifiedOnly, isTrue);
        expect(
          find.byKey(const ValueKey('property-card-unverified')),
          findsNothing,
        );
        await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả nhà trọ'));
        await tester.enterText(find.byType(TextField), 'không tồn tại');
        await tester.pumpAndSettle();
        expect(find.text('Không tìm thấy nhà trọ'), findsOneWidget);
        await tester.tap(find.byTooltip('Xóa tìm kiếm'));
        await tester.pumpAndSettle();
        final card = find.byKey(const ValueKey('property-card-may'));
        await tester.ensureVisible(card);
        await tester.tap(
          find.descendant(
            of: card,
            matching: find.widgetWithText(FilledButton, 'Xem phòng trọ'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Danh sách phòng trọ'), findsOneWidget);
        expect(rooms.queries.last.propertyId, 'may');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.ensureVisible(shortcuts[2]);
        await tester.tap(shortcuts[2]);
        await tester.pumpAndSettle();
        expect(properties.queries.last.verifiedOnly, isTrue);
        expect(find.text('Nhà trọ đáng tin cậy'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('property-card-unverified')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
