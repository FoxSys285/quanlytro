import 'dart:typed_data';

class PropertyVerificationFile {
  const PropertyVerificationFile({
    required this.name,
    this.bytes,
    this.storagePath,
  });

  final String name;
  final Uint8List? bytes;
  final String? storagePath;

  Map<String, dynamic> toMap() => {
    'name': name,
    'bytes': bytes?.toList(),
    'storagePath': storagePath,
  };

  factory PropertyVerificationFile.fromMap(Map<String, dynamic> map) =>
      PropertyVerificationFile(
        name: map['name'] as String? ?? 'Tài liệu',
        bytes: map['bytes'] == null
            ? null
            : Uint8List.fromList(List<int>.from(map['bytes'] as List)),
        storagePath: map['storagePath'] as String?,
      );
}

class PropertyVerificationDocument {
  const PropertyVerificationDocument({required this.id, required this.files});

  final String id;
  final List<PropertyVerificationFile> files;

  Map<String, dynamic> toMap() => {
    'id': id,
    'files': files.map((file) => file.toMap()).toList(),
  };

  factory PropertyVerificationDocument.fromMap(Map<String, dynamic> map) =>
      PropertyVerificationDocument(
        id: map['id'] as String,
        files: (map['files'] as List? ?? const [])
            .map(
              (file) => PropertyVerificationFile.fromMap(
                Map<String, dynamic>.from(file as Map),
              ),
            )
            .toList(),
      );
}

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
    this.verificationDocuments = const [],
    this.verificationSubmittedAt,
    this.verificationIsOwner = true,
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
  final List<PropertyVerificationDocument> verificationDocuments;
  final DateTime? verificationSubmittedAt;
  final bool verificationIsOwner;

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
    'verificationDocuments': verificationDocuments
        .map((document) => document.toMap())
        .toList(),
    'verificationSubmittedAt': verificationSubmittedAt?.toIso8601String(),
    'verificationIsOwner': verificationIsOwner,
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
        verificationDocuments:
            (map['verificationDocuments'] as List? ?? const [])
                .map(
                  (document) => PropertyVerificationDocument.fromMap(
                    Map<String, dynamic>.from(document as Map),
                  ),
                )
                .toList(),
        verificationSubmittedAt: map['verificationSubmittedAt'] == null
            ? null
            : DateTime.tryParse(map['verificationSubmittedAt'] as String),
        verificationIsOwner: map['verificationIsOwner'] as bool? ?? true,
      );
}
