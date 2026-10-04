class LandlordProperty {
  const LandlordProperty({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerName,
    required this.phone,
    required this.description,
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String address;
  final String ownerName;
  final String phone;
  final String description;
  final String imageUrl;
}
