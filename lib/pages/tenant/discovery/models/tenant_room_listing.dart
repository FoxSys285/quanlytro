import 'dart:typed_data';

import '../../../../data/admin_store.dart';
import '../../../landlord/room_types/models/landlord_room_type.dart';

import '../../../landlord/landlord_demo_store.dart';
import '../../../landlord/rooms/models/landlord_room.dart';
import '../../../landlord/services/models/landlord_service.dart';
import '../../../shared/media/room_photo.dart';

class TenantRoomPrice {
  const TenantRoomPrice({
    required this.id,
    required this.name,
    required this.unit,
    required this.basis,
    required this.price,
  });

  final String id;
  final String name;
  final String unit;
  final String basis;
  final int price;

  factory TenantRoomPrice.fromMap(Map<String, dynamic> map) => TenantRoomPrice(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? 'Dịch vụ',
    unit: map['unit'] as String? ?? '',
    basis: map['basis'] as String? ?? '',
    price: (map['price'] as num?)?.toInt() ?? 0,
  );
}

LandlordService? _roomTypeService(
  LandlordDemoStore store,
  LandlordRoomType type, {
  required bool water,
}) {
  for (final id in type.serviceIds) {
    final service = store.serviceRecordById(id);
    if (service == null || !service.active) continue;
    if (water
        ? service.id == 'water' || service.name.toLowerCase().contains('nước')
        : service.id == 'electricity' ||
              service.name.toLowerCase().contains('điện')) {
      return service;
    }
  }
  return store.serviceById(water ? 'water' : 'electricity');
}

int _roomTypeRate(
  LandlordDemoStore store,
  LandlordRoomType type, {
  required bool water,
}) {
  final service = _roomTypeService(store, type, water: water);
  return service == null ? 0 : type.servicePrices[service.id] ?? service.price;
}

String _roomTypeWaterBasis(LandlordDemoStore store, LandlordRoomType type) {
  final service = _roomTypeService(store, type, water: true);
  final unit = service?.unit.toLowerCase() ?? '';
  final basis = service?.basis.toLowerCase() ?? '';
  if (unit.contains('người') || basis.contains('người')) return 'Theo người';
  if (unit.contains('tháng') ||
      unit.contains('phòng') ||
      basis.contains('tháng') ||
      basis.contains('phòng')) {
    return 'Theo tháng';
  }
  return 'Theo m³';
}

class TenantRoomListing {
  const TenantRoomListing({
    required this.name,
    required this.address,
    required this.price,
    required this.size,
    required this.distance,
    required this.roomType,
    required this.city,
    required this.ward,
    required this.distanceMeters,
    required this.electricityPrice,
    required this.waterType,
    required this.waterPrice,
    required this.variant,
    required this.rating,
    required this.tags,
    this.listingId,
    this.ownerPropertyId,
    this.roomCode,
    this.capacity,
    this.description = '',
    this.imageBytes,
    this.imageUrl = '',
    this.roomServices,
    List<RoomPhoto> photos = const [],
    List<RoomTypeImage>? images,
  }) : photos = images ?? photos;

  final String name;
  final String address;
  final int price;
  final String size;
  final String distance;
  final String roomType;
  final String city;
  final String ward;
  final int distanceMeters;
  final int electricityPrice;
  final String waterType;
  final int waterPrice;
  final int variant;
  final String rating;
  final List<String> tags;
  final String? listingId;
  final String? ownerPropertyId;
  final String? roomCode;
  final int? capacity;
  final String description;
  final Uint8List? imageBytes;
  final String imageUrl;
  final List<TenantRoomPrice>? roomServices;
  final List<RoomPhoto> photos;
  List<RoomTypeImage> get images => photos;

  List<TenantRoomPrice> get priceList =>
      roomServices ??
      [
        TenantRoomPrice(
          id: 'electricity',
          name: 'Điện',
          unit: 'kWh',
          basis: 'Theo chỉ số',
          price: electricityPrice,
        ),
        TenantRoomPrice(
          id: 'water',
          name: 'Nước',
          unit: waterType == 'Theo tháng'
              ? 'tháng'
              : waterType == 'Theo người'
              ? 'người'
              : 'm³',
          basis: waterType,
          price: waterPrice,
        ),
      ];
  List<RoomPhoto> get gallery {
    if (photos.isNotEmpty) return photos;
    if (imageBytes != null || imageUrl.isNotEmpty) {
      return [RoomPhoto(name: name, bytes: imageBytes, url: imageUrl)];
    }
    if (roomCode != null) return const [];
    return RoomPhoto.demoForType(switch (roomType) {
      'Studio' => 'studio',
      'Phòng có gác' => 'loft',
      'Căn hộ mini' => 'group',
      _ => 'balcony',
    });
  }

  double get areaSquareMeters =>
      double.tryParse(
        RegExp(r'\d+(?:[.,]\d+)?')
                .firstMatch(size)
                ?.group(0)
                ?.replaceAll(',', '.') ??
            '',
      ) ??
      0;

  String get id => listingId ?? 'external-$name';

  String get propertyId {
    if (ownerPropertyId != null) return ownerPropertyId!;
    if (name.startsWith('Mây House')) return 'may';
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'listing-$slug';
  }
}

class TenantRoomDemoData {
  static const currentCity = 'TP. Hồ Chí Minh';
  static const currentWard = 'Phường 25';

  static const listings = [
    TenantRoomListing(
      name: 'Mây House · Studio đầy đủ nội thất',
      address: '25 Nguyễn Gia Trí, Bình Thạnh',
      price: 3800000,
      size: '25 m²',
      distance: '1,2 km',
      roomType: 'Studio',
      city: currentCity,
      ward: currentWard,
      distanceMeters: 1200,
      electricityPrice: 3500,
      waterType: 'Theo tháng',
      waterPrice: 100000,
      variant: 0,
      rating: '4.9',
      tags: ['Có máy lạnh', 'Ban công', 'Giờ tự do'],
    ),
    TenantRoomListing(
      name: 'Phòng gác lửng Nhà Nâu',
      address: '18 Phan Xích Long, Phú Nhuận',
      price: 3400000,
      size: '22 m²',
      distance: '2,4 km',
      roomType: 'Phòng có gác',
      city: currentCity,
      ward: 'Phường 2',
      distanceMeters: 2400,
      electricityPrice: 4000,
      waterType: 'Theo m³',
      waterPrice: 3000,
      variant: 1,
      rating: '4.8',
      tags: ['Gác lửng', 'Cửa sổ lớn', 'Có chỗ xe'],
    ),
    TenantRoomListing(
      name: 'Studio Ban Mai',
      address: '45/2 D2, Bình Thạnh',
      price: 4200000,
      size: '28 m²',
      distance: '900 m',
      roomType: 'Studio',
      city: currentCity,
      ward: currentWard,
      distanceMeters: 900,
      electricityPrice: 3800,
      waterType: 'Theo m³',
      waterPrice: 3500,
      variant: 2,
      rating: '5.0',
      tags: ['Thang máy', 'Máy giặt riêng', 'Bếp riêng'],
    ),
    TenantRoomListing(
      name: 'Phòng trọ Thanh Xuân',
      address: '103 D2, Bình Thạnh',
      price: 3100000,
      size: '20 m²',
      distance: '1,6 km',
      roomType: 'Phòng đơn',
      city: currentCity,
      ward: currentWard,
      distanceMeters: 1600,
      electricityPrice: 3200,
      waterType: 'Theo tháng',
      waterPrice: 120000,
      variant: 0,
      rating: '4.7',
      tags: ['Gần HUTECH', 'Có máy lạnh', 'Cửa sổ'],
    ),
    TenantRoomListing(
      name: 'Căn hộ An Nhiên',
      address: '69 Ung Văn Khiêm, Bình Thạnh',
      price: 4800000,
      size: '32 m²',
      distance: '700 m',
      roomType: 'Căn hộ mini',
      city: currentCity,
      ward: currentWard,
      distanceMeters: 700,
      electricityPrice: 3500,
      waterType: 'Theo m³',
      waterPrice: 4000,
      variant: 2,
      rating: '4.9',
      tags: ['Thang máy', 'Ban công', 'Bếp riêng'],
    ),
    TenantRoomListing(
      name: 'Gác Mộc',
      address: '7 Xô Viết Nghệ Tĩnh, Bình Thạnh',
      price: 3600000,
      size: '23 m²',
      distance: '3,1 km',
      roomType: 'Phòng có gác',
      city: currentCity,
      ward: 'Phường 17',
      distanceMeters: 3100,
      electricityPrice: 4500,
      waterType: 'Theo tháng',
      waterPrice: 100000,
      variant: 1,
      rating: '4.8',
      tags: ['Gác lửng', 'Có chỗ xe', 'Giờ tự do'],
    ),
    TenantRoomListing(
      name: 'Studio Cỏ May',
      address: '112 Chu Văn An, Bình Thạnh',
      price: 4100000,
      size: '28 m²',
      distance: '2,7 km',
      roomType: 'Studio',
      city: currentCity,
      ward: 'Phường 26',
      distanceMeters: 2700,
      electricityPrice: 3500,
      waterType: 'Theo m³',
      waterPrice: 3000,
      variant: 2,
      rating: '4.9',
      tags: ['Ban công', 'Máy lạnh', 'Máy giặt riêng'],
    ),
    TenantRoomListing(
      name: 'Bình Yên Room',
      address: '8 Nguyễn Xí, Bình Thạnh',
      price: 3200000,
      size: '21 m²',
      distance: '3,3 km',
      roomType: 'Phòng đơn',
      city: currentCity,
      ward: 'Phường 13',
      distanceMeters: 3300,
      electricityPrice: 5000,
      waterType: 'Theo tháng',
      waterPrice: 150000,
      variant: 1,
      rating: '4.6',
      tags: ['Cửa sổ lớn', 'Có máy lạnh', 'Gần chợ'],
    ),
    TenantRoomListing(
      name: 'Nhà Xinh Thảo Điền',
      address: '20 Quốc Hương, Thủ Đức',
      price: 5200000,
      size: '35 m²',
      distance: '4,8 km',
      roomType: 'Căn hộ mini',
      city: currentCity,
      ward: 'Phường Thảo Điền',
      distanceMeters: 4800,
      electricityPrice: 4000,
      waterType: 'Theo m³',
      waterPrice: 5000,
      variant: 2,
      rating: '5.0',
      tags: ['Ban công', 'Thang máy', 'Bếp riêng'],
    ),
    TenantRoomListing(
      name: 'Gác Trọ Tân Định',
      address: '36 Trần Khắc Chân, Quận 1',
      price: 3900000,
      size: '24 m²',
      distance: '6,8 km',
      roomType: 'Phòng có gác',
      city: currentCity,
      ward: 'Phường 8',
      distanceMeters: 6800,
      electricityPrice: 3000,
      waterType: 'Theo tháng',
      waterPrice: 100000,
      variant: 1,
      rating: '4.7',
      tags: ['Gác lửng', 'Gần trung tâm', 'Có chỗ xe'],
    ),
    TenantRoomListing(
      name: 'Mini House Tân Bình',
      address: '15 Cộng Hòa, Tân Bình',
      price: 3500000,
      size: '22 m²',
      distance: '8,5 km',
      roomType: 'Phòng đơn',
      city: currentCity,
      ward: 'Phường 4',
      distanceMeters: 8500,
      electricityPrice: 4500,
      waterType: 'Theo m³',
      waterPrice: 3500,
      variant: 0,
      rating: '4.6',
      tags: ['Có máy lạnh', 'Cửa sổ', 'Giờ tự do'],
    ),
  ];

  static final _moreListings = List<TenantRoomListing>.generate(10, (index) {
    final isStudio = index.isEven;
    final waterByMeter = index.isOdd;
    final distanceMeters = 1300 + index * 720;
    const wards = ['Phường 25', 'Phường 26', 'Phường 17', 'Phường 13'];
    const studioTags = ['Ban công', 'Có máy lạnh', 'Bếp riêng'];
    const loftTags = ['Gác lửng', 'Cửa sổ lớn', 'Có chỗ xe'];
    return TenantRoomListing(
      name: isStudio
          ? 'Studio Mây ${index + 1}'
          : 'Phòng gác An Nhiên ${index + 1}',
      address: '${20 + index} Nguyễn Gia Trí, Bình Thạnh',
      price: 3200000 + (index % 5) * 300000,
      size: '${21 + (index % 10)} m²',
      distance: '${(distanceMeters / 1000).toStringAsFixed(1)} km',
      roomType: isStudio ? 'Studio' : 'Phòng có gác',
      city: currentCity,
      ward: wards[index % wards.length],
      distanceMeters: distanceMeters,
      electricityPrice: 3000 + (index % 5) * 500,
      waterType: waterByMeter ? 'Theo m³' : 'Theo tháng',
      waterPrice: waterByMeter ? 3000 + (index % 4) * 500 : 100000,
      variant: index % 3,
      rating: '4.${6 + (index % 4)}',
      tags: isStudio ? studioTags : loftTags,
    );
  });

  static List<TenantRoomListing> forStore(
    LandlordDemoStore store, {
    bool includeExternal = true,
  }) => [
    for (final details in store.roomDetails)
      if (details.status == LandlordRoomStatus.vacant && details.type != null)
        TenantRoomListing(
          listingId: '${store.property.id}:${details.room.code}',
          ownerPropertyId: store.property.id,
          roomCode: store.canonicalRoom(details.room.code),
          name:
              '${store.property.name} · Phòng ${details.room.code} · ${details.typeName}',
          address: store.property.address,
          price: details.type!.monthlyRent,
          size: '${details.room.area} m²',
          capacity: details.room.capacity,
          description: store.property.description,
          photos: details.type!.photos,
          imageBytes: details.type!.photos.firstOrNull?.bytes,
          imageUrl: details.type!.photos.firstOrNull?.url ?? '',
          distance: '',
          distanceMeters: 0,
          roomType: details.typeName,
          city: store.property.city,
          ward: store.property.ward,
          electricityPrice: _roomTypeRate(store, details.type!, water: false),
          waterType: _roomTypeWaterBasis(store, details.type!),
          waterPrice: _roomTypeRate(store, details.type!, water: true),
          roomServices: [
            for (final serviceId in details.type!.serviceIds)
              if (store.serviceRecordById(serviceId) case final service?
                  when service.active)
                TenantRoomPrice(
                  id: service.id,
                  name: service.name,
                  unit: service.unit,
                  basis: service.basis,
                  price:
                      details.type!.servicePrices[service.id] ?? service.price,
                ),
          ],
          variant: 0,
          rating: '—',
          tags: [
            ...store.property.amenities,
            'Tầng ${details.room.floor}',
            'Giờ tự do',
            if (details.room.floor > 3) 'Tầng cao',
          ],
        ),
    if (includeExternal)
      ...listings.where((room) => room.propertyId != store.property.id),
    if (includeExternal) ..._moreListings,
  ];

  static List<TenantRoomListing> get allListings =>
      RentalPortfolio.instance.stores.length > 1
      ? [
          for (final store in RentalPortfolio.instance.stores)
            if (!AdminStore.instance.isHidden(store.property.id))
              ...forStore(store, includeExternal: false),
        ]
      : forStore(LandlordDemoStore.instance);
}
