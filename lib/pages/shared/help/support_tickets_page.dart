import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../tenant/tenant_detail_ui.dart';
import '../../tenant/tenant_feature_ui.dart';
import '../../tenant/tenant_ui.dart';

class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({super.key, required this.role});
  final AppRole role;

  bool get _usesFeatureStyle =>
      role == AppRole.tenant || role == AppRole.landlord;

  Widget _dialogStyle(Widget child) => _usesFeatureStyle
      ? TenantDetailTheme(landlordStyle: role == AppRole.landlord, child: child)
      : child;

  Future<void> _compose(BuildContext context) async {
    final title = TextEditingController();
    final content = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => _dialogStyle(
        StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            titlePadding: _usesFeatureStyle
                ? const EdgeInsets.fromLTRB(16, 16, 16, 0)
                : null,
            title: _usesFeatureStyle
                ? const TenantFormHeading(
                    icon: Icons.support_agent_rounded,
                    title: 'Gửi yêu cầu hỗ trợ',
                    subtitle:
                        'Mô tả rõ màn hình và thao tác để đội hỗ trợ kiểm tra.',
                  )
                : const Text('Gửi yêu cầu hỗ trợ'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề',
                        prefixIcon: _usesFeatureStyle
                            ? const Icon(Icons.edit_note_rounded)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: content,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: 'Mô tả vấn đề và cách tái hiện',
                        alignLabelWithHint: true,
                        hintText: _usesFeatureStyle
                            ? 'Bạn đang ở màn hình nào? Đã thao tác gì và gặp vấn đề gì?'
                            : null,
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
      if (_usesFeatureStyle) {
        return TenantFeatureFrame(
          artwork: role == AppRole.landlord
              ? TenantFeatureArtwork.landlordHelp
              : TenantFeatureArtwork.help,
          title: 'Yêu cầu hỗ trợ',
          subtitle: role == AppRole.landlord
              ? 'Theo dõi yêu cầu hỗ trợ và phản hồi từ quản trị viên.'
              : 'Theo dõi yêu cầu của bạn và phản hồi từ quản trị viên.',
          children: [
            TenantSurface(
              child: Row(
                children: [
                  const TenantDetailIcon(Icons.support_agent_rounded, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role == AppRole.landlord
                              ? 'Hỗ trợ vận hành nhà trọ'
                              : 'Cùng bạn giải quyết vấn đề',
                          style: TextStyle(
                            color: tenantInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${tickets.where((ticket) => !ticket.closed).length} yêu cầu đang mở',
                          style: const TextStyle(
                            color: tenantMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _compose(context),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Gửi yêu cầu hỗ trợ'),
            ),
            const SizedBox(height: 24),
            const TenantSectionHeading('Yêu cầu và phản hồi'),
            if (tickets.isEmpty)
              const TenantEmptyState(
                icon: Icons.forum_outlined,
                title: 'Chưa có yêu cầu hỗ trợ.',
                subtitle: 'Gửi mô tả khi bạn cần quản trị viên hỗ trợ thao tác trong ứng dụng.',
              ),
            for (final ticket in tickets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TenantSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TenantStatusPill(
                            ticket.closed ? 'Đã giải quyết' : 'Đang mở',
                            color: ticket.closed
                                ? tenantGreenDark
                                : const Color(0xFFA77720),
                          ),
                          Text(
                            landlordDate(ticket.createdAt),
                            style: const TextStyle(
                              color: tenantMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const TenantThinDivider(),
                      Text(
                        ticket.content,
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 12,
                          height: 1.7,
                        ),
                      ),
                      if (ticket.reply.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        TenantDetailNote(
                          'Phản hồi từ quản trị viên\n${ticket.reply}',
                          icon: Icons.support_agent_outlined,
                        ),
                      ] else ...[
                        const SizedBox(height: 14),
                        const TenantDetailNote(
                          'Yêu cầu đã được ghi nhận. Phản hồi sẽ hiển thị tại đây.',
                          icon: Icons.mark_chat_unread_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      }
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
