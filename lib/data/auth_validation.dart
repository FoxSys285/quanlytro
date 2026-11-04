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
