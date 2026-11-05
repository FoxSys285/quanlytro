import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/tenant/discovery/models/tenant_property_listing.dart';

class TenantPropertyQuery {
  const TenantPropertyQuery({this.query = '', this.verifiedOnly = false});
  final String query;
  final bool verifiedOnly;

  bool matches(TenantPropertyListing listing) {
    final property = listing.property;
    return (!verifiedOnly || listing.verified) &&
        '${property.name} ${property.address} ${property.city} ${property.ward}'
            .toLowerCase()
            .contains(query.trim().toLowerCase());
  }
}

class PropertyCatalogPage {
  const PropertyCatalogPage({required this.items, this.nextCursor});
  final List<TenantPropertyListing> items;
  final Object? nextCursor;
}

abstract interface class TenantPropertyCatalogSource {
  Future<PropertyCatalogPage> fetch(
    TenantPropertyQuery query, {
    Object? after,
    int limit = 8,
  });
}

abstract interface class TenantPropertyDetailsSource {
  Future<TenantPropertyListing?> fetchProperty(String propertyId);
}

class FirestoreTenantPropertyCatalogSource
    implements TenantPropertyCatalogSource, TenantPropertyDetailsSource {
  FirestoreTenantPropertyCatalogSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<TenantPropertyListing?> fetchProperty(String propertyId) async {
    final snapshot = await _firestore
        .collection('rental_properties')
        .doc(propertyId)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data == null || data['published'] == false || data['archived'] == true) {
      return null;
    }
    return TenantPropertyListing.fromMap(data);
  }

  @override
  Future<PropertyCatalogPage> fetch(
    TenantPropertyQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError('Số nhà trọ mỗi trang không hợp lệ.');
    }
    Query<Map<String, dynamic>> request = _firestore
        .collection('rental_properties')
        .where('published', isEqualTo: true)
        .orderBy(FieldPath.documentId);
    if (query.verifiedOnly) {
      request = request.where('verified', isEqualTo: true);
    }
    var cursor = after as DocumentSnapshot<Map<String, dynamic>>?;
    DocumentSnapshot<Map<String, dynamic>>? pageEnd;
    final items = <TenantPropertyListing>[];
    var remainingReads = 48;
    while (true) {
      final snapshot =
          await (cursor == null ? request : request.startAfterDocument(cursor))
              .limit((limit + 1).clamp(1, remainingReads))
              .get(const GetOptions(source: Source.server));
      final batchSize = (limit + 1).clamp(1, remainingReads);
      remainingReads -= snapshot.docs.length;
      for (final doc in snapshot.docs) {
        cursor = doc;
        final data = doc.data();
        if (data['published'] == false || data['archived'] == true) continue;
        final listing = TenantPropertyListing.fromMap(data);
        if (!query.matches(listing)) continue;
        if (items.length == limit) {
          return PropertyCatalogPage(items: items, nextCursor: pageEnd);
        }
        items.add(listing);
        pageEnd = doc;
      }
      if (snapshot.docs.length < batchSize) {
        return PropertyCatalogPage(items: items);
      }
      if (remainingReads <= 0) {
        return PropertyCatalogPage(items: items, nextCursor: cursor);
      }
    }
  }
}
