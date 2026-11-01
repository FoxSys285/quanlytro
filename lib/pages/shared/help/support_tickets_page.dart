import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import '../../landlord/finance/landlord_finance_models.dart';

class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({super.key, required this.role});
  final AppRole role;

  Future<void> _compose(BuildContext context) async {
    final title = TextEditingController();
    final content = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Gửi yêu cầu hỗ trợ'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    maxLength: 120,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: content,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả vấn đề và cách tái hiện',
                    ),
                  ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                ],
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
                try {
                  AdminStore.instance.submitTicket(
                    role,
                    title.text,
                    content.text,
                  );
                  Navigator.pop(context);
                } on ArgumentError catch (e) {
                  setState(() => error = e.message.toString());
                }
              },
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
    // Controllers remain alive until the dialog's closing animation has completed.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    title.dispose();
    content.dispose();
  }

  Future<void> _reply(BuildContext context, SupportTicket ticket) async {
    final controller = TextEditingController(text: ticket.reply);
    var closed = ticket.closed;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Phản hồi hỗ trợ'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ticket.content),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung phản hồi',
                    ),
                  ),
                  CheckboxListTile(
                    value: closed,
                    onChanged: (v) => setState(() => closed = v!),
                    title: const Text('Đã giải quyết'),
                  ),
                ],
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
                try {
                  AdminStore.instance.reply(ticket, controller.text, closed);
                  Navigator.pop(context);
                } on ArgumentError catch (e) {
                  showLandlordMessage(context, e.message.toString());
                }
              },
              child: const Text('Lưu phản hồi'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AdminStore.instance,
    builder: (context, _) {
      final tickets = AdminStore.instance.tickets
          .where((t) => role == AppRole.admin || t.role == role)
          .toList();
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Yêu cầu hỗ trợ',
            subtitle: 'Theo dõi yêu cầu và phản hồi trên thiết bị.',
          ),
          if (role != AppRole.admin)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FilledButton.icon(
                onPressed: () => _compose(context),
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Gửi yêu cầu hỗ trợ'),
              ),
            ),
          if (tickets.isEmpty)
            const LandlordEmptyState(message: 'Chưa có yêu cầu hỗ trợ.'),
          for (final ticket in tickets)
            LandlordCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ticket.role.label} · ${landlordDate(ticket.createdAt)} · ${ticket.closed ? 'Đã giải quyết' : 'Đang mở'}',
                    style: const TextStyle(color: landlordMuted),
                  ),
                  const SizedBox(height: 12),
                  Text(ticket.content),
                  if (ticket.reply.isNotEmpty) ...[
                    const Divider(height: 28),
                    const Text(
                      'Phản hồi từ quản trị viên',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(ticket.reply),
                  ],
                  if (role == AppRole.admin)
                    TextButton.icon(
                      onPressed: () => _reply(context, ticket),
                      icon: const Icon(Icons.reply),
                      label: const Text('Phản hồi'),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
