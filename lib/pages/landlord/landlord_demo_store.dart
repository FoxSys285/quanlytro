import 'package:flutter/foundation.dart';

import 'properties/models/landlord_property.dart';
import 'room_types/models/landlord_room_type.dart';

/// Temporary data for one authenticated landlord, replaced by a repository later.
class LandlordDemoStore extends ChangeNotifier {
  LandlordDemoStore.demo();
  static final instance = LandlordDemoStore.demo();

  LandlordProperty _property = const LandlordProperty(
    id: 'may',
    name: 'Mây House',
    address: '25 Nguyễn Gia Trí, Bình Thạnh, TP. Hồ Chí Minh',
    ownerName: 'Nguyễn Văn An',
    phone: '0900000000',
    description:
        'Nhà trọ có không gian thoáng, giờ giấc tự do và chỗ để xe. '
        'Liên hệ chủ trọ để biết thêm thông tin phòng và nội quy.',
  );
  LandlordProperty get property => _property;

  static const rooms = {'101': 1, '102': 1, '201': 2, '202': 2};
  final _roomTypes = [
    const LandlordRoomType(id: 'studio', name: 'Studio', monthlyRent: 3000000),
    const LandlordRoomType(
      id: 'balcony',
      name: 'Phòng có ban công',
      monthlyRent: 3500000,
    ),
    const LandlordRoomType(
      id: 'loft',
      name: 'Phòng có gác',
      monthlyRent: 2800000,
    ),
    const LandlordRoomType(
      id: 'group',
      name: 'Phòng lớn cho 5 người',
      monthlyRent: 5000000,
    ),
  ];
  int _nextType = 1;
  List<LandlordRoomType> get roomTypes => List.unmodifiable(_roomTypes);

  void updateProperty(LandlordProperty property) {
    if (property.id != _property.id) {
      throw ArgumentError('Nhà trọ không hợp lệ.');
    }
    _property = property;
    notifyListeners();
  }

  bool nameExists(String name, {String? excludingId}) => _roomTypes.any(
    (type) =>
        type.id != excludingId &&
        type.name.toLowerCase() == name.trim().toLowerCase(),
  );

  void saveRoomType(String name, {required int monthlyRent, String? id}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || nameExists(trimmed, excludingId: id)) {
      throw ArgumentError('Tên loại phòng trống hoặc trùng.');
    }
    if (monthlyRent <= 0) throw ArgumentError('Giá thuê phải lớn hơn 0.');
    if (id == null) {
      _roomTypes.add(
        LandlordRoomType(
          id: 'custom-${_nextType++}',
          name: trimmed,
          monthlyRent: monthlyRent,
        ),
      );
    } else {
      final index = _roomTypes.indexWhere((type) => type.id == id);
      if (index == -1) throw ArgumentError('Loại phòng không tồn tại.');
      _roomTypes[index] = LandlordRoomType(
        id: id,
        name: trimmed,
        monthlyRent: monthlyRent,
      );
    }
    notifyListeners();
  }

  void deleteRoomType(String id) {
    _roomTypes.removeWhere((type) => type.id == id);
    notifyListeners();
  }
}
