import 'package:flutter/foundation.dart';

import '../../landlord/conversations/models/landlord_cuoctrochuyen.dart';
import '../rental/tenant_session.dart';
import '../../landlord/landlord_demo_store.dart';

/// A conversation and its messages are shared; unread counts belong to each role.
class ConversationStore extends ChangeNotifier {
  ConversationStore({
    Iterable<LandlordConversation> records = const [],
    LandlordDemoStore? rental,
  }) : _records = List.of(records),
       rental = rental ?? LandlordDemoStore.instance {
    this.rental.addListener(_syncRental);
    _syncRental();
  }
  final LandlordDemoStore rental;
  static final instance = ConversationStore.demo();
  factory ConversationStore.demo() => ConversationStore(
    records: [
      LandlordConversation(
        id: 'lease-0302',
        leaseId: 'HD-2026-0302',
        tenantId: TenantSession.tenantId,
        tenantName: TenantSession.name,
        room: 'A.302',
        unread: 1,
        tenantUnread: 1,
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
          const LandlordMessage(
            text: 'Chủ trọ sẽ ghé kiểm tra vào chiều nay nhé.',
            time: '09:18',
            fromLandlord: true,
          ),
        ],
      ),
      LandlordConversation(
        id: 'lease-0101',
        leaseId: 'HD-2026-0101',
        tenantId: 'tenant-khoa',
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
        id: 'lease-0105',
        leaseId: 'HD-2026-0105',
        tenantId: 'tenant-bao',
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
      LandlordConversation(
        id: 'external-hoa-mai',
        propertyId: 'hoa-mai',
        tenantId: TenantSession.tenantId,
        landlordName: 'Trần Thị Mai',
        propertyName: 'Nhà trọ Hoa Mai',
        tenantName: TenantSession.name,
        room: 'Nhà trọ Hoa Mai',
        tenantUnread: 2,
        messages: [
          const LandlordMessage(
            text: 'Dạ phòng có ban công còn trống không cô?',
            time: '08:30',
            fromLandlord: false,
          ),
          const LandlordMessage(
            text: 'Phòng còn trống nhé, bạn có thể ghé xem chiều nay.',
            time: '08:35',
            fromLandlord: true,
          ),
          const LandlordMessage(
            text: 'Bạn báo cô giờ đến để cô mở cửa nhé.',
            time: '08:40',
            fromLandlord: true,
          ),
        ],
      ),
      LandlordConversation(
        id: 'external-an-binh',
        propertyId: 'an-binh',
        tenantId: TenantSession.tenantId,
        landlordName: 'Lê Minh Hùng',
        propertyName: 'Nhà trọ An Bình',
        tenantName: TenantSession.name,
        room: 'Nhà trọ An Bình',
        messages: [
          const LandlordMessage(
            text: 'Dạ em cảm ơn anh, em sẽ liên hệ lại sau ạ.',
            time: 'Hôm qua',
            fromLandlord: false,
          ),
        ],
      ),
    ],
  );
  final List<LandlordConversation> _records;
  void _syncRental() {
    for (final conversation in _records) {
      if (conversation.propertyId != rental.property.id) continue;
      conversation.landlordName = rental.property.ownerName;
      conversation.propertyName = rental.property.name;
      final lease = conversation.leaseId == null
          ? null
          : rental.leaseById(conversation.leaseId!);
      if (lease != null) {
        conversation.tenantName = lease.tenantName;
        conversation.room = lease.room;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    rental.removeListener(_syncRental);
    super.dispose();
  }

  List<LandlordConversation> get conversations => List.unmodifiable(_records);
  List<LandlordConversation> forTenant(String id) =>
      _records.where((item) => item.tenantId == id).toList();
  List<LandlordConversation> forProperty(String id) =>
      _records.where((item) => item.propertyId == id).toList();
  LandlordConversation getOrCreate(LandlordConversation conversation) {
    for (final item in _records) {
      if (item.id == conversation.id) return item;
    }
    _records.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  void send(
    LandlordConversation conversation, {
    required String text,
    required String time,
    required bool fromLandlord,
    String? tenantId,
  }) {
    if (tenantId != null && conversation.tenantId != tenantId) {
      throw ArgumentError('Hội thoại không thuộc người thuê.');
    }
    if (text.trim().isEmpty) return;
    conversation.messages.add(
      LandlordMessage(
        text: text.trim(),
        time: time,
        fromLandlord: fromLandlord,
      ),
    );
    if (fromLandlord) {
      conversation.tenantUnread++;
    } else {
      conversation.unread++;
    }
    notifyListeners();
  }

  void markRead(LandlordConversation conversation, {required bool landlord}) {
    if (landlord) {
      conversation.unread = 0;
    } else {
      conversation.tenantUnread = 0;
    }
    notifyListeners();
  }
}
