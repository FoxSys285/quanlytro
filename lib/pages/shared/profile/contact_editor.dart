import 'package:flutter/material.dart';

import 'contact_details.dart';
import '../../tenant/tenant_feature_ui.dart';

class ContactEditor extends StatefulWidget {
  const ContactEditor({
    super.key,
    required this.title,
    required this.initial,
    this.isStaff = false,
    this.tenantStyle = false,
    this.subtitle = 'Thông tin giúp chủ trọ liên hệ và hỗ trợ bạn.',
  });
  final String title;
  final ContactDetails initial;
  final bool isStaff;
  final bool tenantStyle;
  final String subtitle;
  @override
  State<ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<ContactEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _email = TextEditingController(text: widget.initial.email);
  late final _extra = TextEditingController(
    text: widget.isStaff ? widget.initial.jobTitle : widget.initial.address,
  );
  @override
  void dispose() {
    for (final controller in [_name, _phone, _email, _extra]) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: widget.tenantStyle ? null : const OutlineInputBorder(),
    counterText: '',
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    titlePadding: widget.tenantStyle
        ? const EdgeInsets.fromLTRB(16, 16, 16, 0)
        : null,
    title: widget.tenantStyle
        ? TenantFormHeading(
            icon: Icons.edit_note_rounded,
            title: widget.title,
            subtitle: widget.subtitle,
          )
        : Text(widget.title),
    contentPadding: widget.tenantStyle
        ? const EdgeInsets.fromLTRB(16, 20, 16, 8)
        : const EdgeInsets.fromLTRB(24, 20, 24, 24),
    actionsPadding: widget.tenantStyle
        ? const EdgeInsets.fromLTRB(16, 8, 16, 16)
        : null,
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          autovalidateMode: widget.tenantStyle
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Họ và tên', Icons.person_outline),
                validator: validateContactName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                maxLength: 25,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Số điện thoại', Icons.phone_outlined),
                validator: validateContactPhone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                maxLength: 150,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email', Icons.email_outlined),
                validator: validateContactEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _extra,
                maxLength: 250,
                maxLines: widget.isStaff ? 1 : 3,
                decoration: _decoration(
                  widget.isStaff ? 'Công việc phụ trách' : 'Địa chỉ liên hệ',
                  widget.isStaff
                      ? Icons.badge_outlined
                      : Icons.location_on_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          FocusScope.of(context).unfocus();
          Navigator.pop(
            context,
            ContactDetails(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim(),
              address: widget.isStaff ? '' : _extra.text.trim(),
              jobTitle: widget.isStaff ? _extra.text.trim() : '',
            ),
          );
        },
        child: const Text('Lưu thay đổi'),
      ),
    ],
  );
}
