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
  });

  final String tenantName;
  final String room;
  final List<LandlordMessage> messages;
  int unread;

  LandlordMessage get lastMessage => messages.last;
}
