import 'dart:typed_data';

class LandlordProperty {
  const LandlordProperty({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerName,
    required this.phone,
    required this.description,
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
  final String description;
  final String imageUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final String city;
  final String ward;
}
