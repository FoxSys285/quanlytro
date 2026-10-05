import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../viewings/data/viewing_conversation_store.dart';
import 'landlord_chat_page.dart';
import 'models/landlord_conversation.dart';

class LandlordConversationsPage extends StatefulWidget {
  const LandlordConversationsPage({super.key});

  @override
  State<LandlordConversationsPage> createState() =>
      _LandlordConversationsPageState();
}

class _LandlordConversationsPageState extends State<LandlordConversationsPage> {
  final _conversations = <LandlordConversation>[
    LandlordConversation(
      tenantName: 'Minh Anh',
      room: 'A.302',
      unread: 1,
      messages: [
        const LandlordMessage(
          text: 'Chào bạn, bạn cần hỗ trợ gì về phòng đang thuê?',
          time: '09:12',
          fromLandlord: true,
        ),
        const LandlordMessage(
          text: 'Dạ em muốn hỏi về lịch sửa máy lạnh ạ.',
          time: '09:15',
          fromLandlord: false,
        ),
      ],
    ),
    LandlordConversation(
      tenantName: 'Lê Văn Khoa',
      room: 'A.101',
      messages: [
        const LandlordMessage(
          text: 'Anh ơi hóa đơn tháng này em chuyển khoản rồi nhé.',
          time: 'Hôm qua',
          fromLandlord: false,
        ),
        const LandlordMessage(
          text: 'Ok em, anh sẽ kiểm tra và xác nhận.',
          time: 'Hôm qua',
          fromLandlord: true,
        ),
      ],
    ),
    LandlordConversation(
      tenantName: 'Phạm Quốc Bảo',
      room: 'B.105',
      unread: 2,
      messages: [
        const LandlordMessage(
          text: 'Em muốn thêm bạn vào ở cùng phòng được không anh?',
          time: '08:40',
          fromLandlord: false,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final conversations = [
      ...ViewingConversationStore.instance.conversations,
      ..._conversations,
    ];
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
    setState(() => conversation.unread = 0);
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
