String? validateAccountEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Vui lòng nhập email.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Địa chỉ email chưa hợp lệ.';
  }
  return null;
}

String? validateAccountPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
  if (password.length < 8 ||
      !RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password)) {
    return 'Mật khẩu cần ít nhất 8 ký tự, gồm chữ và số.';
  }
  return null;
}

/// Canonical Firebase/E.164 representation of a Vietnamese mobile number.
String normalizeVietnamesePhone(String value) {
  var phone = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (phone.startsWith('0')) {
    phone = '+84${phone.substring(1)}';
  } else if (phone.startsWith('84')) {
    phone = '+$phone';
  }
  return phone;
}

String? validateAccountPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Vui lòng nhập số điện thoại.';
  }
  if (!RegExp(r'^\+84[35789][0-9]{8}$')
      .hasMatch(normalizeVietnamesePhone(value))) {
    return 'Nhập số di động Việt Nam hợp lệ (10 số hoặc +84).';
  }
  return null;
}
