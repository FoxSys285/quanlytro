import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/shared/media/room_photo.dart';
import '../pages/tenant/discovery/models/tenant_area_selection.dart';
import '../pages/tenant/discovery/models/tenant_room_listing.dart';
import 'property_catalog.dart';

class TenantCatalogQuery {
  const TenantCatalogQuery({
    this.query = '',
    this.maxRent = 20000000,
    this.minElectricity = 0,
    this.maxElectricity = 5000,
    this.city,
    this.ward,
    this.waterType = 'Tất cả',
    this.minArea,
    this.maxArea,
    this.amenities = const {},
    this.sort = 'default',
    this.propertyId,
  });
  final String query, waterType, sort;
  final int maxRent, minElectricity, maxElectricity;
  final String? city, ward;
  final String? propertyId;
  final double? minArea, maxArea;
  final Set<String> amenities;

  bool matches(TenantRoomListing room) {
    final text =
        '${room.name} ${room.address} ${room.roomType} ${room.tags.join(' ')} ${room.city} ${room.ward}'
            .toLowerCase();
    return text.contains(query.trim().toLowerCase()) &&
        (propertyId == null || propertyId == room.propertyId) &&
        room.price <= maxRent &&
        room.electricityPrice >= minElectricity &&
        room.electricityPrice <= maxElectricity &&
        (city == null || sameLocationName(city!, room.city)) &&
        (ward == null || sameLocationName(ward!, room.ward)) &&
        (waterType == 'Tất cả' || waterType == room.waterType) &&
        (minArea == null || room.areaSquareMeters >= minArea!) &&
        (maxArea == null || room.areaSquareMeters <= maxArea!) &&
        amenities.every((item) => room.tags.contains(item));
  }
}

class CatalogPage {
  const CatalogPage({required this.items, this.nextCursor});
  final List<TenantRoomListing> items;
  final Object? nextCursor;
}

class DiscoveryHomeFeed {
  const DiscoveryHomeFeed({
    required this.featured,
    required this.goodPrice,
    required this.trusted,
  });
  factory DiscoveryHomeFeed.fromRooms(List<TenantRoomListing> rooms) {
    final preview = rooms.take(10).toList();
    return DiscoveryHomeFeed(
      featured: preview,
      goodPrice: [...preview]..sort((a, b) => a.price.compareTo(b.price)),
      trusted: const [],
    );
  }
  final List<TenantRoomListing> featured;
  final List<TenantRoomListing> goodPrice;
  final List<TenantRoomListing> trusted;
}

abstract interface class TenantDiscoveryHomeSource {
  Future<DiscoveryHomeFeed> fetchHome({int limit = 10});
}

abstract interface class TenantCatalogSource {
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  });
}

class FirestoreTenantCatalogSource
    implements TenantCatalogSource, TenantDiscoveryHomeSource {
  FirestoreTenantCatalogSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<DiscoveryHomeFeed> fetchHome({int limit = 10}) async {
    if (limit < 1 || limit > 10) {
      throw ArgumentError('Mỗi mục xem trước tối đa 10 phòng.');
    }
    final featured = fetch(const TenantCatalogQuery(), limit: limit);
    final goodPrice = fetch(
      const TenantCatalogQuery(sort: 'rentAsc'),
      limit: limit,
    );
    final trusted = _fetchTrustedPreview(limit);
    final pages = await Future.wait([featured, goodPrice, trusted]);
    return DiscoveryHomeFeed(
      featured: pages[0].items,
      goodPrice: pages[1].items,
      trusted: pages[2].items,
    );
  }

  Future<CatalogPage> _fetchTrustedPreview(int limit) async {
    final properties = await FirestoreTenantPropertyCatalogSource(
      firestore: _firestore,
    ).fetch(const TenantPropertyQuery(verifiedOnly: true), limit: limit);
    final ids = properties.items.map((item) => item.property.id).toList();
    if (ids.isEmpty) return const CatalogPage(items: []);
    final snapshot = await _firestore
        .collection('public_rooms')
        .where('published', isEqualTo: true)
        .where('available', isEqualTo: true)
        .where('propertyId', whereIn: ids)
        .orderBy(FieldPath.documentId)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
    return CatalogPage(
      items: snapshot.docs
          .map((doc) => catalogListingFromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError('Số phòng mỗi trang không hợp lệ.');
    }
    Query<Map<String, dynamic>> request = _firestore
        .collection('public_rooms')
        .where('published', isEqualTo: true)
        .where('available', isEqualTo: true);
    if (query.propertyId != null) {
      request = request.where('propertyId', isEqualTo: query.propertyId);
    } else {
      if (query.city != null) {
        request = request.where(
          'city',
          whereIn: catalogLocationValues(query.city!, city: true),
        );
      }
      if (query.ward != null) {
        request = request.where(
          'ward',
          whereIn: catalogLocationValues(query.ward!, city: false),
        );
      }
    }
    request = switch (query.sort) {
      'rentAsc' => request.orderBy('price'),
      'rentDesc' => request.orderBy('price', descending: true),
      'areaAsc' => request.orderBy('area'),
      'areaDesc' => request.orderBy('area', descending: true),
      _ => request.orderBy(FieldPath.documentId),
    };
    var cursor = after as DocumentSnapshot<Map<String, dynamic>>?;
    DocumentSnapshot<Map<String, dynamic>>? pageEnd;
    final items = <TenantRoomListing>[];
    var remainingReads = 64;
    // Firestore không tìm chuỗi con. Lọc phần còn lại theo từng lô có cursor;
    // không tải portfolio/hợp đồng để tìm trọ. Nâng lên search service khi dữ liệu lớn.
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
        if (data['published'] != true || data['available'] != true) continue;
        final room = catalogListingFromMap(doc.id, data);
        if (!query.matches(room)) continue;
        if (items.length == limit) {
          return CatalogPage(items: items, nextCursor: pageEnd);
        }
        items.add(room);
        pageEnd = doc;
      }
      if (snapshot.docs.length < batchSize) return CatalogPage(items: items);
      if (remainingReads <= 0) {
        return CatalogPage(items: items, nextCursor: cursor);
      }
    }
  }
}

TenantRoomListing catalogListingFromMap(String id, Map<String, dynamic> data) =>
    TenantRoomListing(
      listingId: Uri.decodeComponent(id),
      ownerPropertyId: data['propertyId'] as String,
      roomCode: data['roomCode'] as String,
      name: data['name'] as String,
      address: data['address'] as String,
      price: (data['price'] as num).toInt(),
      size: '${data['area']} m²',
      capacity: (data['capacity'] as num).toInt(),
      description: data['description'] as String? ?? '',
      distance: '',
      roomType: data['roomType'] as String,
      city: data['city'] as String,
      ward: data['ward'] as String,
      distanceMeters: 0,
      electricityPrice: (data['electricityPrice'] as num).toInt(),
      waterType: data['waterType'] as String,
      waterPrice: (data['waterPrice'] as num).toInt(),
      roomServices: data.containsKey('services')
          ? (data['services'] as List? ?? const [])
                .map(
                  (service) => TenantRoomPrice.fromMap(
                    Map<String, dynamic>.from(service as Map),
                  ),
                )
                .toList()
          : null,
      variant: 0,
      rating: '—',
      tags: List<String>.from(data['tags'] as List? ?? []),
      photos: (data['photos'] as List? ?? [])
          .map((p) => RoomPhoto.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
