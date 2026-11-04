import 'dart:math';

// Mỗi thiết bị/người thuê tạo mã riêng, không dùng bộ đếm của bản dữ liệu cũ.
String rentalRecordId(String prefix) {
  final random = Random.secure();
  return '$prefix-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
