import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../../shared/conversations/conversation_store.dart';
import '../landlord_demo_store.dart';
import 'landlord_chat_page.dart';
import 'models/landlord_conversation.dart';

class LandlordConversationsPage extends StatefulWidget {
  const LandlordConversationsPage({super.key});

  @override
  State<LandlordConversationsPage> createState() =>
      _LandlordConversationsPageState();
}

class _LandlordConversationsPageState extends State<LandlordConversationsPage> {
  final _store = ConversationStore.instance;
  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _store.forProperty(
      LandlordDemoStore.instance.property.id,
    );
    return LandlordPageFrame(
      children: [
        const LandlordPageTitle(
          title: 'Tin nhắn',
          subtitle: 'Trao đổi với người thuê theo từng phòng.',
        ),
        if (conversations.isEmpty)
          const LandlordEmptyState(message: 'Chưa có cuộc trò chuyện nào.'),
        for (final conversation in conversations)
          LandlordCard(
            padding: EdgeInsets.zero,
            onTap: () => _openChat(conversation),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: landlordBlue.withValues(alpha: 0.1),
                child: Text(
                  conversation.tenantName[0],
                  style: const TextStyle(
                    color: landlordBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                '${conversation.tenantName} · ${conversation.room}',
                style: TextStyle(
                  fontWeight: conversation.unread > 0
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
              subtitle: Text(
                conversation.lastMessage.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation.lastMessage.time,
                    style: const TextStyle(color: landlordMuted, fontSize: 11),
                  ),
                  if (conversation.unread > 0) ...[
                    const SizedBox(height: 4),
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: landlordBlue,
                      child: Text(
                        '${conversation.unread}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openChat(LandlordConversation conversation) async {
    _store.markRead(conversation, landlord: true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LandlordChatPage(conversation: conversation),
      ),
    );
    // Cập nhật lại tin nhắn cuối sau khi quay về.
    if (mounted) setState(() {});
  }
}
