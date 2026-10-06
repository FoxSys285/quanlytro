import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import 'models/tenant_conversation.dart';
import 'tenant_conversation_page.dart';

class TenantConversationsPage extends StatefulWidget {
  const TenantConversationsPage({super.key});

  @override
  State<TenantConversationsPage> createState() =>
      _TenantConversationsPageState();
}

class _TenantConversationsPageState extends State<TenantConversationsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final conversations = TenantConversation.demoConversations
        .where(
          (conversation) =>
              '${conversation.landlordName} ${conversation.contextLabel}'
                  .toLowerCase()
                  .contains(_query),
        )
        .toList();

    return TenantPageFrame(
      children: [
        const TenantPageTitle(
          title: 'Tin nhắn',
          subtitle: 'Trao đổi với chủ trọ về chỗ ở và phòng bạn quan tâm.',
        ),
        TextField(
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Tìm chủ trọ, nhà trọ hoặc phòng...',
            prefixIcon: const Icon(Icons.search_rounded, color: tenantMuted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: tenantLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: tenantLine),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TenantSectionHeading('Cuộc trò chuyện (${conversations.length})'),
        if (conversations.isEmpty)
          const TenantEmptyState(
            icon: Icons.forum_outlined,
            title: 'Không tìm thấy cuộc trò chuyện',
            subtitle: 'Thử tìm bằng tên chủ trọ, nhà trọ hoặc số phòng khác.',
          ),
        for (final conversation in conversations)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TenantSurface(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  onTap: () => _openChat(conversation),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F2EE),
                    child: Text(
                      conversation.initials,
                      style: const TextStyle(
                        color: tenantGreenDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    conversation.landlordName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tenantInk,
                      fontSize: 14,
                      fontWeight: conversation.unread > 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.contextLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.messages.isEmpty
                            ? 'Chưa có tin nhắn'
                            : '${conversation.messages.last.fromTenant ? 'Bạn: ' : ''}${conversation.messages.last.text}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: tenantInk, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        conversation.messages.isEmpty
                            ? ''
                            : conversation.messages.last.time,
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 10,
                        ),
                      ),
                      if (conversation.unread > 0) ...[
                        const SizedBox(height: 6),
                        Semantics(
                          label: '${conversation.unread} tin nhắn chưa đọc',
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: tenantGreen,
                            child: Text(
                              '${conversation.unread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openChat(TenantConversation conversation) async {
    setState(() => conversation.unread = 0);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TenantLandlordConversationPage(conversation: conversation),
      ),
    );
    if (mounted) setState(() {});
  }
}
