import 'dart:convert';
import 'dart:typed_data';

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
    name: 'Studio · ảnh minh họa',
    url: 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/4f462a177212b04ce90323_1659520123.jpg',
    isReference: true,
  );
  static const balcony = RoomPhoto(
    name: 'Phòng ban công · ảnh minh họa',
    url: 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415474499-f37e78d3842cb00c00e93a8741eaf8c8_1693974014.jpg',
    isReference: true,
  );
  static const loft = RoomPhoto(
    name: 'Phòng có gác · ảnh minh họa',
    url: 'https://cdn.thuviennhadat.vn/upload/tin-dang/hinh-anh/20250311144334/20250311144334638773010148943147.jpg',
    isReference: true,
  );
  static const group = RoomPhoto(
    name: 'Phòng lớn · ảnh minh họa',
    url: 'https://cdn1z.reatimes.vn/mediav2/media/uploaded/92/2019/06/07/6084966023202165616342311685105387516198912n.jpg',
    isReference: true,
  );

  static List<RoomPhoto> demoForType(String id) => switch (id) {
    'studio' => const [studio],
    'balcony' => const [balcony],
    'loft' => const [loft],
    'group' => const [group],
    _ => const [],
  };
}
