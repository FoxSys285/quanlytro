/// Model đại diện cho một tin nhắn đơn lẻ phía chủ trọ
class LandlordMessage {
  // Hàm khởi tạo tin nhắn
  const LandlordMessage({
    required this.text,
    required this.time,
    required this.fromLandlord,
    this.id,
    this.createdAt,
    this.index,
    this.contextId,
    this.roomContext,
  });

  // Nội dung tin nhắn
  final String text;

  // Thời gian gửi tin nhắn (ví dụ: 14:30)
  final String time;

  // Đánh dấu người gửi: true là chủ trọ gửi, false là khách thuê gửi
  final bool fromLandlord;
  final String? id;
  final DateTime? createdAt;
  // Original ordering position stays stable after concurrent messages merge.
  final int? index;
  final String? contextId;
  final Map<String, dynamic>? roomContext;

  Map<String, dynamic> toMap() => {
    'text': text,
    'time': time,
    'fromLandlord': fromLandlord,
    if (id != null) 'id': id,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (index != null) 'index': index,
    if (contextId != null) 'contextId': contextId,
    if (roomContext != null) 'roomContext': roomContext,
  };

  factory LandlordMessage.fromMap(Map<String, dynamic> map) => LandlordMessage(
    text: map['text'] as String,
    time: map['time'] as String,
    fromLandlord: map['fromLandlord'] as bool,
    id: map['id'] as String?,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.parse(map['createdAt'] as String),
    index: map['index'] as int?,
    contextId: map['contextId'] as String?,
    roomContext: map['roomContext'] is Map
        ? Map<String, dynamic>.from(map['roomContext'] as Map)
        : null,
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
    this.ownerUid = '',
    this.lastRoomContext,
    List<Map<String, dynamic>>? roomContexts,
  }) : roomContexts = List<Map<String, dynamic>>.of(roomContexts ?? const []);

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

  /// Firebase owner identity; display names and phone numbers never key chats.
  final String ownerUid;

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
  Map<String, dynamic>? lastRoomContext;
  final List<Map<String, dynamic>> roomContexts;

  String get contextRoom => lastRoomContext?['roomName'] as String? ?? room;
  String get contextPropertyName =>
      lastRoomContext?['propertyName'] as String? ?? propertyName;
  String get contextPropertyId =>
      lastRoomContext?['propertyId'] as String? ?? propertyId;

  // Lấy tin nhắn mới nhất trong cuộc trò chuyện
  LandlordMessage get lastMessage => messages.last;

  Map<String, dynamic> toMap() => {
    'tenantName': tenantName,
    'room': room,
    'id': id,
    'propertyId': propertyId,
    'tenantId': tenantId,
    if (ownerUid.isNotEmpty) 'ownerUid': ownerUid,
    'landlordName': landlordName,
    'propertyName': propertyName,
    'leaseId': leaseId,
    'messages': messages.map((item) => item.toMap()).toList(),
    'unread': unread,
    'tenantUnread': tenantUnread,
    if (lastRoomContext != null) 'lastRoomContext': lastRoomContext,
    'roomContexts': roomContexts,
  };

  factory LandlordConversation.fromMap(Map<String, dynamic> map) =>
      LandlordConversation(
        tenantName: map['tenantName'] as String,
        room: map['room'] as String,
        id: map['id'] as String,
        propertyId: map['propertyId'] as String,
        tenantId: map['tenantId'] as String,
        ownerUid: map['ownerUid'] as String? ?? '',
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
        lastRoomContext: map['lastRoomContext'] is Map
            ? Map<String, dynamic>.from(map['lastRoomContext'] as Map)
            : null,
        roomContexts: (map['roomContexts'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
}

// Biệt danh tiếng Việt dễ nhớ
typedef LandlordTinNhanModel = LandlordMessage;
typedef LandlordCuocTroChuyen = LandlordConversation;
