class LandlordMessage {
  const LandlordMessage({
    required this.text,
    required this.time,
    required this.fromLandlord,
  });

  final String text;
  final String time;
  final bool fromLandlord;
}

class LandlordConversation {
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

  String tenantName;
  String room;
  final String id;
  final String propertyId;
  final String tenantId;
  String landlordName;
  String propertyName;
  final String? leaseId;
  final List<LandlordMessage> messages;
  int unread;
  int tenantUnread;

  LandlordMessage get lastMessage => messages.last;
}
