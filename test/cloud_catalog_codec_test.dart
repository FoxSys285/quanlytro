import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';

void main() {
  test(
    'Public room projections contain no private tenant or financial history',
    () {
      final portfolio = RentalPortfolio.seeded();
      addTearDown(portfolio.dispose);
      final snapshot = {'portfolio': portfolio.toMap()};
      final docs = encodeCloudDocuments(
        snapshot,
        owners: {for (final s in portfolio.stores) s.property.id: 'owner-a'},
      );
      expect(
        (docs['rental_properties/may']!['data'] as Map)['schemaVersion'],
        2,
      );
      final public = docs.entries.where(
        (e) => e.key.startsWith('public_rooms/'),
      );
      expect(public.length, 454);
      final occupied = public
          .where((e) => e.value['available'] == false)
          .length;
      expect(occupied, greaterThan(300));
      for (final entry in public) {
        expect(entry.value.containsKey('tenantId'), isFalse);
        expect(entry.value.containsKey('tenantCitizenId'), isFalse);
        expect(entry.value.containsKey('paidAmount'), isFalse);
        final listing = catalogListingFromMap(
          entry.key.split('/').last,
          entry.value,
        );
        expect(listing.id, Uri.decodeComponent(entry.key.split('/').last));
        expect(listing.gallery.length, inInclusiveRange(2, 4));
      }
      expect(
        docs.keys.any((path) => path.startsWith('rental_records/may:leases:')),
        isTrue,
      );
    },
  );
  test('Catalog criteria combine prices, decimals, amenities and location', () {
    final portfolio = RentalPortfolio.seeded();
    addTearDown(portfolio.dispose);
    final docs = encodeCloudDocuments(
      {'portfolio': portfolio.toMap()},
      owners: {for (final s in portfolio.stores) s.property.id: 'owner-a'},
    );
    final sample = docs.entries.firstWhere(
      (e) => e.key.startsWith('public_rooms/'),
    );
    final room = catalogListingFromMap(
      sample.key.split('/').last,
      sample.value,
    );
    expect(
      TenantCatalogQuery(
        minArea: room.areaSquareMeters,
        maxArea: room.areaSquareMeters,
        amenities: {room.tags.first},
      ).matches(room),
      isTrue,
    );
    expect(TenantCatalogQuery(maxRent: room.price - 1).matches(room), isFalse);
    expect(
      const TenantCatalogQuery(amenities: {'Unavailable amenity'})
          .matches(room),
      isFalse,
    );
    expect(
      const TenantCatalogQuery(city: 'Different city').matches(room),
      isFalse,
    );
  });
}
