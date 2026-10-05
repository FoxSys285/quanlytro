import '../../../shared/viewings/models/room_viewing.dart';
import '../../conversations/models/landlord_conversation.dart';

class ViewingConversationStore {
  static final instance = ViewingConversationStore();
  final _conversations = <String, LandlordConversation>{};
  List<LandlordConversation> get conversations =>
      List.unmodifiable(_conversations.values);

  LandlordConversation forViewing(
    RoomViewing viewing,
  ) => _conversations.putIfAbsent(
    '${viewing.propertyId}:${viewing.tenantId.isEmpty ? viewing.phone : viewing.tenantId}:${viewing.roomName}',
    () => LandlordConversation(
      tenantName: viewing.customerName,
      room: viewing.roomName,
      messages: [
        LandlordMessage(
          text:
              'Chào chủ trọ, tôi đã đặt lịch xem ${viewing.roomName}. ${viewing.personalNeeds}',
          time: 'Lịch xem phòng',
          fromLandlord: false,
        ),
      ],
    ),
  );
}
