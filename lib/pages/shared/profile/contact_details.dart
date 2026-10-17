class ContactDetails {
  const ContactDetails({
    required this.name,
    required this.phone,
    required this.email,
    this.address = '',
    this.jobTitle = '',
  });
  final String name;
  final String phone;
  final String email;
  final String address;
  final String jobTitle;
}

String? validateContactName(String? value) =>
    value == null || value.trim().isEmpty ? 'Nhập họ và tên.' : null;
String? validateContactPhone(String? value) =>
    RegExp(r'^\+?\d{9,15}$')
        .hasMatch((value ?? '').replaceAll(RegExp(r'[\s().-]'), ''))
    ? null
    : 'Số điện thoại không hợp lệ.';
String? validateContactEmail(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())
    ? null
    : 'Email không hợp lệ.';

void validateContact(ContactDetails contact) {
  final error =
      validateContactName(contact.name) ??
      validateContactPhone(contact.phone) ??
      validateContactEmail(contact.email);
  if (error != null) throw ArgumentError(error);
}
