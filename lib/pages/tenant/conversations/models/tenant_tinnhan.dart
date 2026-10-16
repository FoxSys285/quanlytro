// Model đại diện cho từng tin nhắn trong cuộc trò chuyện phía người thuê
class TenantConversationMessage {
  const TenantConversationMessage({
    required this.text,
    required this.time,
    required this.fromTenant,
  });

  // Nội dung tin nhắn
  final String text;

  // Thời gian gửi tin nhắn (ví dụ: 09:15)
  final String time;

  // Đánh dấu người gửi: true là người thuê gửi, false là chủ trọ gửi
  final bool fromTenant;
}

// Biệt danh tiếng Việt dễ nhớ
typedef TenantTinNhan = TenantConversationMessage;

