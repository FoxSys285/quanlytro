class TenantAreaSelection {
  const TenantAreaSelection({
    required this.city,
    required this.ward,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String? ward;
  final double latitude;
  final double longitude;
}

/// Compare platform address names with the names entered by landlords.
bool sameLocationName(String first, String second) =>
    _locationName(first) == _locationName(second);

/// Common stored spellings let Firestore filter locations before pagination,
/// while preserving aliases returned by GPS (e.g. Ho Chi Minh City).
List<String> catalogLocationValues(String value, {required bool city}) {
  var bare = value
      .trim()
      .replaceFirst(
        RegExp(
          r'^(thành phố|tỉnh|phường|xã|thị trấn|tp\.?|p\.)\s*',
          caseSensitive: false,
        ),
        '',
      )
      .replaceFirst(RegExp(r'\s+(city|province)$', caseSensitive: false), '');
  if (city) {
    const provinces = [
      'Hà Nội',
      'Cao Bằng',
      'Tuyên Quang',
      'Điện Biên',
      'Lai Châu',
      'Sơn La',
      'Lào Cai',
      'Thái Nguyên',
      'Lạng Sơn',
      'Quảng Ninh',
      'Bắc Ninh',
      'Phú Thọ',
      'Hải Phòng',
      'Hưng Yên',
      'Ninh Bình',
      'Thanh Hóa',
      'Nghệ An',
      'Hà Tĩnh',
      'Quảng Trị',
      'Huế',
      'Đà Nẵng',
      'Quảng Ngãi',
      'Gia Lai',
      'Khánh Hòa',
      'Đắk Lắk',
      'Lâm Đồng',
      'Hồ Chí Minh',
      'Đồng Nai',
      'Tây Ninh',
      'Cần Thơ',
      'Vĩnh Long',
      'Đồng Tháp',
      'An Giang',
      'Cà Mau',
    ];
    bare =
        provinces.where((name) => sameLocationName(name, value)).firstOrNull ??
        bare;
    return {
      value.trim(),
      bare,
      'Thành phố $bare',
      'Tỉnh $bare',
      'TP. $bare',
      'TP $bare',
    }.toList();
  }
  // At most 5 ward spellings × 6 city spellings = 30 Firestore disjunctions.
  return {
    value.trim(),
    bare,
    'Phường $bare',
    'Xã $bare',
    'Thị trấn $bare',
  }.toList();
}

String _locationName(String value) {
  var name = value.trim().toLowerCase();
  const accents = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in accents.entries) {
    name = name.replaceAll(RegExp('[${entry.value}]'), entry.key);
  }
  name = name
      .replaceFirst(
        RegExp(r'^(thanh pho|tinh|phuong|xa|thi tran|tp\.?|p\.)\s*'),
        '',
      )
      .replaceFirst(RegExp(r'\s+(city|province)$'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return switch (name) {
    'hcm' || 'tphcm' || 'saigon' => 'hochiminh',
    _ => name,
  };
}
