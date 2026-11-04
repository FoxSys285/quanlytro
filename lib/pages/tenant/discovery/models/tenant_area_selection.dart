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
