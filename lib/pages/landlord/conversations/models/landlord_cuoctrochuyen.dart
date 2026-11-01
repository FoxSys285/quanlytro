/// Model đại diện cho một tin nhắn đơn lẻ phía chủ trọ
class LandlordMessage {
  // Hàm khởi tạo tin nhắn
  const LandlordMessage({
    required this.text,
    required this.time,
    required this.fromLandlord,
  });

  // Nội dung tin nhắn
  final String text;

  // Thời gian gửi tin nhắn (ví dụ: 14:30)
  final String time;

  // Đánh dấu người gửi: true là chủ trọ gửi, false là khách thuê gửi
  final bool fromLandlord;

  Map<String, dynamic> toMap() => {
    'text': text,
    'time': time,
    'fromLandlord': fromLandlord,
  };

  factory LandlordMessage.fromMap(Map<String, dynamic> map) => LandlordMessage(
    text: map['text'] as String,
    time: map['time'] as String,
    fromLandlord: map['fromLandlord'] as bool,
  );
}

/// Model đại diện cho cuộc trò chuyện giữa chủ trọ và khách thuê
class LandlordConversation {
  // Hàm khởi tạo cuộc trò chuyện
  LandlordConversation({
    required this.tenantName,
    required this.room,
    required this.messages,
    this.unread = 0,
    this.id = '',
    this.propertyId = 'may',
    this.tenantId = '',
    this.landlordName = 'Nguyễn Văn An',
    this.propertyName = 'Mây House',
    this.leaseId,
    this.tenantUnread = 0,
  });

  // Tên khách thuê trọ
  String tenantName;

  // Số phòng thuê
  String room;

  // Mã định danh cuộc trò chuyện
  final String id;

  // Mã nhà trọ / tòa nhà
  final String propertyId;

  // Mã khách thuê
  final String tenantId;

  // Tên chủ trọ
  String landlordName;

  // Tên nhà trọ
  String propertyName;

  // Mã hợp đồng thuê (nếu có)
  final String? leaseId;

  // Danh sách các tin nhắn trong cuộc trò chuyện
  final List<LandlordMessage> messages;

  // Số lượng tin nhắn chưa đọc đối với chủ trọ
  int unread;

  // Số lượng tin nhắn chưa đọc đối với người thuê
  int tenantUnread;

  // Lấy tin nhắn mới nhất trong cuộc trò chuyện
  LandlordMessage get lastMessage => messages.last;

  Map<String, dynamic> toMap() => {
    'tenantName': tenantName,
    'room': room,
    'id': id,
    'propertyId': propertyId,
    'tenantId': tenantId,
    'landlordName': landlordName,
    'propertyName': propertyName,
    'leaseId': leaseId,
    'messages': messages.map((item) => item.toMap()).toList(),
    'unread': unread,
    'tenantUnread': tenantUnread,
  };

  factory LandlordConversation.fromMap(Map<String, dynamic> map) =>
      LandlordConversation(
        tenantName: map['tenantName'] as String,
        room: map['room'] as String,
        id: map['id'] as String,
        propertyId: map['propertyId'] as String,
        tenantId: map['tenantId'] as String,
        landlordName: map['landlordName'] as String,
        propertyName: map['propertyName'] as String,
        leaseId: map['leaseId'] as String?,
        messages: (map['messages'] as List)
            .map(
              (item) => LandlordMessage.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        unread: map['unread'] as int,
        tenantUnread: map['tenantUnread'] as int,
      );
}

// Biệt danh tiếng Việt dễ nhớ
typedef LandlordTinNhanModel = LandlordMessage;
typedef LandlordCuocTroChuyen = LandlordConversation;
