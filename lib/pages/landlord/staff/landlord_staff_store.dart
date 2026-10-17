import 'package:flutter/foundation.dart';

import '../../shared/profile/contact_details.dart';

class LandlordStaff {
  const LandlordStaff({required this.id, required this.contact});
  final String id;
  final ContactDetails contact;
}

class LandlordStaffStore extends ChangeNotifier {
  LandlordStaffStore.demo();
  static final instance = LandlordStaffStore.demo();
  int _nextId = 1;
  final _staff = <LandlordStaff>[
    const LandlordStaff(
      id: 'manager',
      contact: ContactDetails(
        name: 'Trần Hoàng Phúc',
        phone: '0900000011',
        email: 'phuc.quanly@example.com',
        jobTitle: 'Quản lý nhà trọ',
      ),
    ),
    const LandlordStaff(
      id: 'maintenance',
      contact: ContactDetails(
        name: 'Lê Quốc Huy',
        phone: '0900000012',
        email: 'huy.kythuat@example.com',
        jobTitle: 'Kỹ thuật và sửa chữa',
      ),
    ),
    const LandlordStaff(
      id: 'cleaning',
      contact: ContactDetails(
        name: 'Nguyễn Thị Hương',
        phone: '0900000013',
        email: 'huong.vesinh@example.com',
        jobTitle: 'Vệ sinh khu vực chung',
      ),
    ),
  ];
  List<LandlordStaff> get staff => List.unmodifiable(_staff);
  void save(ContactDetails contact, {String? id}) {
    validateContact(contact);
    if (id == null) {
      _staff.add(LandlordStaff(id: 'staff-${_nextId++}', contact: contact));
    } else {
      final index = _staff.indexWhere((item) => item.id == id);
      if (index == -1) throw ArgumentError('Nhân viên không tồn tại.');
      _staff[index] = LandlordStaff(id: id, contact: contact);
    }
    notifyListeners();
  }

  void delete(String id) {
    _staff.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
