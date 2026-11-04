import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/shared/media/room_photo.dart';
import '../pages/tenant/discovery/models/tenant_area_selection.dart';
import '../pages/tenant/discovery/models/tenant_room_listing.dart';

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
  });
  final String query, waterType, sort;
  final int maxRent, minElectricity, maxElectricity;
  final String? city, ward;
  final double? minArea, maxArea;
  final Set<String> amenities;

  bool matches(TenantRoomListing room) {
    final text =
        '${room.name} ${room.address} ${room.roomType} ${room.tags.join(' ')} ${room.city} ${room.ward}'
            .toLowerCase();
    return text.contains(query.trim().toLowerCase()) &&
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

abstract interface class TenantCatalogSource {
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  });
}

class FirestoreTenantCatalogSource implements TenantCatalogSource {
  FirestoreTenantCatalogSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError('Số phòng mỗi trang không hợp lệ.');
    }
    Query<Map<String, dynamic>> request = _firestore.collection('public_rooms');
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
    // Firestore không tìm chuỗi con. Lọc phần còn lại theo từng lô có cursor;
    // không tải portfolio/hợp đồng để tìm trọ. Nâng lên search service khi dữ liệu lớn.
    while (true) {
      final snapshot =
          await (cursor == null ? request : request.startAfterDocument(cursor))
              .limit(32)
              .get();
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
      if (snapshot.docs.length < 32) return CatalogPage(items: items);
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
      variant: 0,
      rating: '—',
      tags: List<String>.from(data['tags'] as List? ?? []),
      photos: (data['photos'] as List? ?? [])
          .map((p) => RoomPhoto.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
