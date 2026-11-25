import '../../../../data/local_auth.dart';
import '../../landlord_demo_store.dart';
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
      .where(
        (item) =>
            item.lastRoomContext?['source'] == 'viewing' ||
            item.messages.any(
              (message) => message.contextId?.startsWith('viewing:') == true,
            ),
      )
      .toList();

  LandlordConversation forViewing(RoomViewing viewing, {String? ownerUid}) {
    if (viewing.tenantId.isEmpty) {
      throw StateError('Người đặt lịch chưa liên kết tài khoản để nhắn tin.');
    }
    final rental = RentalPortfolio.instance.byId(viewing.propertyId);
    final property = rental?.property;
    final owner = ownerUid ?? LocalAuth.instance.session?.uid;
    final roomId = viewing.roomId ?? viewing.roomName;
    final context = <String, dynamic>{
      'propertyId': viewing.propertyId,
      'roomId': roomId,
      'roomName': viewing.roomName,
      'propertyName': property?.name ?? viewing.address,
      'source': 'viewing',
    };
    final conversation = store.forRoom(
      propertyId: viewing.propertyId,
      roomId: roomId,
      roomName: viewing.roomName,
      landlordName: property?.ownerName ?? 'Chủ trọ',
      propertyName: property?.name ?? viewing.address,
      tenantId: viewing.tenantId,
      tenantName: viewing.customerName,
      ownerUid: owner,
    );
    store.updateRoomContext(conversation, context);
    return conversation;
  }
}
