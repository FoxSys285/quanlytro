import 'dart:convert';
import 'dart:typed_data';

part 'rental_api_photos.dart';

class RoomPhoto {
  const RoomPhoto({
    required this.name,
    this.bytes,
    this.assetPath = '',
    this.url = '',
    this.isReference = false,
  });

  final String name;
  final Uint8List? bytes;
  final String assetPath;
  final String url;
  final bool isReference;
  bool get isIllustration => isReference || assetPath.isNotEmpty;
  bool get hasSource =>
      bytes?.isNotEmpty == true || assetPath.isNotEmpty || url.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'name': name,
    if (bytes != null) 'bytes': base64Encode(bytes!),
    if (assetPath.isNotEmpty) 'assetPath': assetPath,
    if (url.isNotEmpty) 'url': url,
    if (isReference) 'isReference': true,
  };

  factory RoomPhoto.fromMap(Map<String, dynamic> map) {
    // Chỉ đổi ảnh mẫu đã biết; giữ nguyên ảnh riêng do người dùng thêm.
    if (map['bytes'] == null) {
      for (final sample in [studio, balcony, loft, group]) {
        if (map['url'] == sample.url) return sample;
      }
    }
    // Replace only the former bundled samples; retain uploaded and custom photos.
    if (map['bytes'] == null && (map['url'] as String? ?? '').isEmpty) {
      final online = switch (map['assetPath']) {
        'assets/images/room_types/studio.jpg' => studio,
        'assets/images/room_types/balcony.jpg' => balcony,
        'assets/images/room_types/loft.jpg' => loft,
        'assets/images/room_types/group.jpg' => group,
        _ => null,
      };
      if (online != null) return online;
    }
    return RoomPhoto(
      name: map['name'] as String? ?? 'Ảnh phòng',
      bytes: map['bytes'] == null ? null : base64Decode(map['bytes'] as String),
      assetPath: map['assetPath'] as String? ?? '',
      url: map['url'] as String? ?? '',
      isReference: map['isReference'] as bool? ?? false,
    );
  }

  static const studio = RoomPhoto(
    assetPath: 'assets/images/room_types/studio.webp',
    name: 'Studio · ảnh minh họa',
    url: 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/4f462a177212b04ce90323_1659520123.jpg',
    isReference: true,
  );
  static const balcony = RoomPhoto(
    assetPath: 'assets/images/room_types/balcony.webp',
    name: 'Phòng ban công · ảnh minh họa',
    url: 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415474499-f37e78d3842cb00c00e93a8741eaf8c8_1693974014.jpg',
    isReference: true,
  );
  static const loft = RoomPhoto(
    assetPath: 'assets/images/room_types/loft.webp',
    name: 'Phòng có gác · ảnh minh họa',
    url: 'https://cdn.thuviennhadat.vn/upload/tin-dang/hinh-anh/20250311144334/20250311144334638773010148943147.jpg',
    isReference: true,
  );
  static const group = RoomPhoto(
    assetPath: 'assets/images/room_types/group.webp',
    name: 'Phòng lớn · ảnh minh họa',
    url: 'https://cdn1z.reatimes.vn/mediav2/media/uploaded/92/2019/06/07/6084966023202165616342311685105387516198912n.jpg',
    isReference: true,
  );

  static const studioDetail = RoomPhoto(
    assetPath: 'assets/images/room_types/studio_2.webp',
    name: 'Góc khác · ảnh minh họa',
    url: 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/5fe176b02eb5ecebb5a425_1659520123.jpg',
    isReference: true,
  );
  static const balconyDetail = RoomPhoto(
    assetPath: 'assets/images/room_types/balcony_2.webp',
    name: 'Góc khác · ảnh minh họa',
    url: 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415416997-d41e37ed1dbd28297236857bebfb0713_1693974007.jpg',
    isReference: true,
  );
  static const loftDetail = RoomPhoto(
    assetPath: 'assets/images/room_types/loft_2.webp',
    name: 'Góc khác · ảnh minh họa',
    url: 'https://file.phongtro.vn/2/rent_1791879384402_0_f7f5fefaed.jpg',
    isReference: true,
  );
  static const groupDetail = RoomPhoto(
    assetPath: 'assets/images/room_types/group_2.webp',
    name: 'Góc khác · ảnh minh họa',
    url: 'https://cdn1z.reatimes.vn/mediav2/media/uploaded/92/2019/06/07/169320425.jpg',
    isReference: true,
  );

  static String propertyAsset(int index) => _rentalApiAlbums.isNotEmpty
      ? _rentalApiAlbums[index % _rentalApiAlbums.length].photos.first.assetPath
      : 'assets/images/room_types/${index == 0
            ? 'interior'
            : index == 1
            ? 'cozy'
            : 'property_${index % 10 + 1}'}.webp';

  static List<RoomPhoto> demoForPropertyType(String id, int propertyIndex) {
    final albums = _rentalApiAlbums.where((album) => album.type == id).toList();
    if (albums.isEmpty) return demoForType(id);
    return albums[propertyIndex % albums.length].photos;
  }

  static List<RoomPhoto> demoForType(String id) => switch (id) {
    'studio' => const [studio, studioDetail],
    'balcony' => const [balcony, balconyDetail],
    'loft' => const [loft, loftDetail],
    'group' => const [group, groupDetail],
    _ => const [],
  };
}
