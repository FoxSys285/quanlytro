import 'dart:typed_data';

class LandlordProperty {
  const LandlordProperty({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerName,
    required this.phone,
    this.phoneIsSynthetic = false,
    required this.description,
    this.amenities = const [],
    this.imageUrl = '',
    this.imageBytes,
    this.imageName,
    this.city = 'TP. Hồ Chí Minh',
    this.ward = 'Phường 25',
  });

  final String id;
  final String name;
  final String address;
  final String ownerName;
  final String phone;
  final bool phoneIsSynthetic;
  final String description;
  final List<String> amenities;
  final String imageUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final String city;
  final String ward;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'ownerName': ownerName,
    'phone': phone,
    if (phoneIsSynthetic) 'phoneIsSynthetic': true,
    'description': description,
    'amenities': amenities,
    'imageUrl': imageUrl,
    'imageBytes': imageBytes?.toList(),
    'imageName': imageName,
    'city': city,
    'ward': ward,
  };

  factory LandlordProperty.fromMap(Map<String, dynamic> map) =>
      LandlordProperty(
        id: map['id'] as String,
        name: map['name'] as String,
        address: map['address'] as String,
        ownerName: map['ownerName'] as String,
        phone: map['phone'] as String,
        phoneIsSynthetic: map['phoneIsSynthetic'] == true,
        description: map['description'] as String,
        amenities: List<String>.from(map['amenities'] as List? ?? const []),
        imageUrl: map['imageUrl'] as String,
        imageBytes: map['imageBytes'] == null
            ? null
            : Uint8List.fromList(List<int>.from(map['imageBytes'] as List)),
        imageName: map['imageName'] as String?,
        city: map['city'] as String,
        ward: map['ward'] as String,
      );
}
