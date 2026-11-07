import '../../../../data/rental_cloud_codec.dart';
import '../../../landlord/landlord_demo_store.dart';
import '../../../landlord/properties/models/landlord_property.dart';

class TenantPropertyListing {
  const TenantPropertyListing({
    required this.property,
    required this.roomCount,
    required this.minRent,
    required this.verified,
    this.roomTypes = const [],
    this.verificationScope = 'profile',
    this.verificationNote = '',
  });

  final LandlordProperty property;
  final int roomCount;
  final int? minRent;
  final bool verified;
  final List<String> roomTypes;
  final String verificationScope;
  final String verificationNote;
  bool get isDemoVerification => verificationScope == 'demo';
  String get verificationLabel =>
      isDemoVerification ? 'Đã xác minh · mẫu' : 'Đã xác minh';

  factory TenantPropertyListing.fromStore(
    LandlordDemoStore store, {
    required bool verified,
  }) => TenantPropertyListing(
    property: store.property,
    roomCount: store.catalog.length,
    minRent: _minimum(store.roomDetails.map((room) => room.monthlyRent)),
    verified: verified,
    roomTypes: store.roomTypes.map((type) => type.name).toSet().toList(),
  );

  factory TenantPropertyListing.fromMap(Map<String, dynamic> document) {
    final data = Map<String, dynamic>.from(document['data'] as Map);
    final verification = document['verification'] as Map?;
    return TenantPropertyListing(
      property: LandlordProperty.fromMap(
        Map<String, dynamic>.from(data['property'] as Map),
      ),
      roomCount: (data['rooms'] as List).length,
      minRent: _minimum(
        (data['roomTypes'] as List).map(
          (type) => (type['monthlyRent'] as num).toInt(),
        ),
      ),
      verified:
          document['verified'] == true &&
          document['verificationProof'] == propertyVerificationProof(data),
      roomTypes: (data['roomTypes'] as List? ?? const [])
          .map((type) => (type as Map)['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(),
      verificationScope:
          document['isDemo'] == true || verification?['scope'] == 'demo'
          ? 'demo'
          : 'profile',
      verificationNote: verification?['note'] as String? ?? '',
    );
  }

  static int? _minimum(Iterable<int?> prices) {
    final values = prices.whereType<int>().where((price) => price > 0).toList()
      ..sort();
    return values.firstOrNull;
  }
}
