import 'package:flutter/material.dart';

import '../../shared/profile/contact_details.dart';
import '../../shared/profile/contact_editor.dart';
import '../landlord_ui.dart';
import 'landlord_staff_store.dart';

class LandlordStaffPage extends StatelessWidget {
  const LandlordStaffPage({super.key, this.store});
  final LandlordStaffStore? store;
  LandlordStaffStore get _store => store ?? LandlordStaffStore.instance;

  Future<void> _edit(BuildContext context, [LandlordStaff? member]) async {
    final result = await showDialog<ContactDetails>(
      context: context,
      builder: (_) => ContactEditor(
        title: member == null ? 'Thêm nhân viên' : 'Sửa nhân viên',
        isStaff: true,
        initial:
            member?.contact ??
            const ContactDetails(name: '', phone: '', email: ''),
      ),
    );
    if (result == null || !context.mounted) return;
    _store.save(result, id: member?.id);
    showLandlordMessage(
      context,
      member == null ? 'Đã thêm nhân viên.' : 'Đã cập nhật nhân viên.',
    );
  }

  Future<void> _delete(BuildContext context, LandlordStaff member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhân viên?'),
        content: Text('Xóa thông tin liên hệ của ${member.contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) _store.delete(member.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => LandlordPageFrame(
      children: [
        const LandlordPageTitle(
          title: 'Nhân viên quản lý',
          subtitle: 'Thông tin liên hệ của nhân viên tại nhà trọ.',
        ),
        FilledButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Thêm nhân viên'),
        ),
        const SizedBox(height: 20),
        Text(
          '${_store.staff.length} nhân viên',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_store.staff.isEmpty)
          const LandlordEmptyState(
            message: 'Chưa có nhân viên. Bấm Thêm nhân viên để tạo thông tin liên hệ.',
          ),
        for (final member in _store.staff)
          LandlordCard(
            key: ValueKey(member.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.badge_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        member.contact.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (member.contact.jobTitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      member.contact.jobTitle,
                      style: const TextStyle(color: landlordMuted),
                    ),
                  ),
                const Divider(height: 24),
                _contactLine(Icons.phone_outlined, member.contact.phone),
                const SizedBox(height: 12),
                _contactLine(Icons.email_outlined, member.contact.email),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _edit(context, member),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Sửa'),
                    ),
                    TextButton.icon(
                      onPressed: () => _delete(context, member),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Xóa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _contactLine(IconData icon, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: landlordMuted, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: SelectableText(
          value,
          style: const TextStyle(color: landlordInk, fontSize: 14),
        ),
      ),
    ],
  );
}
