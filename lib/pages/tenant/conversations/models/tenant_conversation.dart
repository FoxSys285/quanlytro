import 'tenant_conversation_message.dart';

class TenantConversation {
  TenantConversation({
    required this.landlordName,
    required this.initials,
    required this.contextLabel,
    required this.messages,
    this.unread = 0,
  });

  final String landlordName;
  final String initials;
  final String contextLabel;
  final List<TenantConversationMessage> messages;
  int unread;

  static final demoConversations = <TenantConversation>[
    TenantConversation(
      landlordName: 'Nguyễn Văn An',
      initials: 'NA',
      contextLabel: 'Chủ trọ · Phòng A.302',
      unread: 1,
      messages: [
        const TenantConversationMessage(
          text: 'Chào bạn, bạn cần hỗ trợ gì về phòng đang thuê?',
          time: '09:12',
          fromTenant: false,
        ),
        const TenantConversationMessage(
          text: 'Dạ em muốn hỏi về lịch sửa máy lạnh ạ.',
          time: '09:15',
          fromTenant: true,
        ),
        const TenantConversationMessage(
          text: 'Chủ trọ sẽ ghé kiểm tra vào chiều nay nhé.',
          time: '09:18',
          fromTenant: false,
        ),
      ],
    ),
    TenantConversation(
      landlordName: 'Trần Thị Mai',
      initials: 'TM',
      contextLabel: 'Chủ trọ · Nhà trọ Hoa Mai',
      unread: 2,
      messages: [
        const TenantConversationMessage(
          text: 'Dạ phòng có ban công còn trống không cô?',
          time: '08:30',
          fromTenant: true,
        ),
        const TenantConversationMessage(
          text: 'Phòng còn trống nhé, bạn có thể ghé xem chiều nay.',
          time: '08:35',
          fromTenant: false,
        ),
        const TenantConversationMessage(
          text: 'Bạn báo cô giờ đến để cô mở cửa nhé.',
          time: '08:40',
          fromTenant: false,
        ),
      ],
    ),
    TenantConversation(
      landlordName: 'Lê Minh Hùng',
      initials: 'LH',
      contextLabel: 'Chủ trọ · Nhà trọ An Bình',
      messages: [
        const TenantConversationMessage(
          text: 'Dạ em cảm ơn anh, em sẽ liên hệ lại sau ạ.',
          time: 'Hôm qua',
          fromTenant: true,
        ),
      ],
    ),
  ];
}
