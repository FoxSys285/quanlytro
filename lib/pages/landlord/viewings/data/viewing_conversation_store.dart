import '../../../shared/viewings/models/room_viewing.dart';
import '../../../shared/conversations/conversation_store.dart';
import '../../conversations/models/landlord_cuoctrochuyen.dart';

class ViewingConversationStore {
  ViewingConversationStore({ConversationStore? store})
    : store = store ?? ConversationStore();
  static final instance = ViewingConversationStore(
    store: ConversationStore.instance,
  );
  final ConversationStore store;
  List<LandlordConversation> get conversations => store.conversations
      .where((item) => item.id.startsWith('viewing:'))
      .toList();

  LandlordConversation forViewing(RoomViewing viewing) => store.getOrCreate(
    LandlordConversation(
      id: 'viewing:${viewing.propertyId}:${viewing.tenantId.isEmpty ? viewing.phone : viewing.tenantId}:${viewing.roomId ?? viewing.roomName}',
      propertyId: viewing.propertyId,
      tenantId: viewing.tenantId,
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
