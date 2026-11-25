import 'package:flutter/foundation.dart';

import '../../landlord/conversations/models/landlord_cuoctrochuyen.dart';
import '../rental/tenant_session.dart';
import '../rental/rental_record_id.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';

/// A conversation and its messages are shared; unread counts belong to each role.
class ConversationStore extends ChangeNotifier {
  ConversationStore({
    Iterable<LandlordConversation> records = const [],
    LandlordDemoStore? rental,
  }) : _records = List.of(records),
       rental = rental ?? LandlordDemoStore.instance {
    this.rental.addListener(_syncRental);
    if (identical(this.rental, LandlordDemoStore.instance)) {
      _portfolio = RentalPortfolio.instance;
      _portfolio!.addListener(_syncRental);
    }
    _syncRental();
  }
  final LandlordDemoStore rental;
  RentalPortfolio? _portfolio;
  static ConversationStore instance = ConversationStore.demo();
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
  Map<String, dynamic> toMap() => {
    'records': _records.map((r) => r.toMap()).toList(),
  };
  void restore(Map<String, dynamic> map) {
    final existing = {
      for (final conversation in _records)
        (
          conversation.propertyId,
          conversation.id,
          conversation.tenantId,
          conversation.leaseId,
        ): conversation,
    };
    final decoded = (map['records'] as List).map((raw) {
      final incoming = LandlordConversation.fromMap(
        Map<String, dynamic>.from(raw as Map),
      );
      final current =
          existing[(
            incoming.propertyId,
            incoming.id,
            incoming.tenantId,
            incoming.leaseId,
          )];
      if (current == null) return incoming;
      // Open landlord pages and tenant adapters retain this exact source object.
      current
        ..tenantName = incoming.tenantName
        ..room = incoming.room
        ..landlordName = incoming.landlordName
        ..propertyName = incoming.propertyName
        ..unread = incoming.unread
        ..tenantUnread = incoming.tenantUnread;
      current.messages
        ..clear()
        ..addAll(incoming.messages);
      current.lastRoomContext = incoming.lastRoomContext;
      current.roomContexts
        ..clear()
        ..addAll(incoming.roomContexts);
      return current;
    }).toList();
    final restored = _mergeOwnerTenantThreads(decoded);
    _records
      ..clear()
      ..addAll(restored);
    _syncRental();
  }

  void _syncRental() {
    for (final conversation in _records) {
      final target = conversation.propertyId == rental.property.id
          ? rental
          : RentalPortfolio.instance.byId(conversation.propertyId);
      if (target == null) continue;
      conversation.landlordName = target.property.ownerName;
      conversation.propertyName = target.property.name;
      final lease = conversation.leaseId == null
          ? null
          : target.leaseById(conversation.leaseId!);
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
    _portfolio?.removeListener(_syncRental);
    super.dispose();
  }

  List<LandlordConversation> get conversations => List.unmodifiable(_records);
  List<LandlordConversation> forTenant(String id) =>
      _records.where((item) => item.tenantId == id).toList();
  List<LandlordConversation> forProperty(String id) => _records.where((item) {
    if (item.propertyId == id || item.contextPropertyId == id) return true;
    if (item.roomContexts.any((context) => context['propertyId'] == id)) {
      return true;
    }
    return item.messages.any(
      (message) => message.roomContext?['propertyId'] == id,
    );
  }).toList();

  static String canonicalId(String ownerUid, String tenantId) =>
      'owner:${Uri.encodeComponent(ownerUid)}:${Uri.encodeComponent(tenantId)}';

  LandlordConversation forRoom({
    required String propertyId,
    required String roomId,
    required String roomName,
    required String landlordName,
    required String propertyName,
    required String tenantId,
    required String tenantName,
    String? ownerUid,
  }) {
    final owner = _ownerIdentity(propertyId, ownerUid);
    final id = canonicalId(owner, tenantId);
    final context = <String, dynamic>{
      'propertyId': propertyId,
      'roomId': roomId,
      'roomName': roomName,
      'propertyName': propertyName,
    };
    final existing = _records.where((conversation) {
      if (conversation.tenantId != tenantId) return false;
      return conversation.id == id ||
          (conversation.ownerUid == owner && owner.isNotEmpty);
    }).firstOrNull;
    if (existing != null) {
      existing
        ..lastRoomContext = context
        ..room = roomName
        ..tenantName = tenantName
        ..landlordName = landlordName
        ..propertyName = propertyName;
      _addRoomContext(existing, context);
      notifyListeners();
      return existing;
    }
    return getOrCreate(
      LandlordConversation(
        id: id,
        propertyId: propertyId,
        ownerUid: owner,
        tenantId: tenantId,
        tenantName: tenantName,
        landlordName: landlordName,
        propertyName: propertyName,
        room: roomName,
        lastRoomContext: context,
        roomContexts: [context],
        messages: [],
      ),
    );
  }

  String _ownerIdentity(String propertyId, String? provided) {
    if (provided != null && provided.trim().isNotEmpty) return provided.trim();
    final session = LocalAuth.instance.session;
    if (session != null && session.role == AppRole.landlord) return session.uid;
    // Local preview data has no Firebase owner UID. Scope it to a single
    // property instead of accidentally merging tenants across landlords.
    return 'local-property:$propertyId';
  }

  List<LandlordConversation> _mergeOwnerTenantThreads(
    List<LandlordConversation> decoded,
  ) {
    final groups = <String, List<LandlordConversation>>{};
    for (final item in decoded) {
      final key = item.ownerUid.isEmpty
          ? 'legacy:${item.propertyId}:${item.id}:${item.tenantId}'
          : '${item.ownerUid}\u0000${item.tenantId}';
      (groups[key] ??= []).add(item);
    }
    final merged = <LandlordConversation>[];
    for (final group in groups.values) {
      if (group.length == 1 && group.single.ownerUid.isEmpty) {
        merged.add(group.single);
        continue;
      }
      final ownerUid = group.first.ownerUid;
      final tenantId = group.first.tenantId;
      final id = ownerUid.isEmpty
          ? group.first.id
          : canonicalId(ownerUid, tenantId);
      group.sort((a, b) {
        final aCanonical = a.id == id ? 0 : 1;
        final bCanonical = b.id == id ? 0 : 1;
        final canonicalOrder = aCanonical.compareTo(bCanonical);
        return canonicalOrder != 0
            ? canonicalOrder
            : a.propertyId.compareTo(b.propertyId);
      });
      final primary = group.first;
      final orderedMessages = <({LandlordMessage message, int order})>[];
      var order = 0;
      for (final thread in group) {
        for (final message in thread.messages) {
          orderedMessages.add((message: message, order: order++));
        }
      }
      final seenIds = <String>{};
      final seenLegacy = <String>{};
      final uniqueMessages = <({LandlordMessage message, int order})>[];
      for (final entry in orderedMessages) {
        final message = entry.message;
        final idKey = message.id;
        if (idKey != null && idKey.isNotEmpty) {
          if (!seenIds.add(idKey)) continue;
        } else {
          final key =
              '${message.fromLandlord}\u0000${message.createdAt?.toUtc().toIso8601String() ?? message.time}\u0000${message.text}';
          if (!seenLegacy.add(key)) continue;
        }
        uniqueMessages.add(entry);
      }
      uniqueMessages.sort((a, b) {
        final aTime = a.message.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.message.createdAt?.millisecondsSinceEpoch ?? 0;
        final timeOrder = aTime.compareTo(bTime);
        return timeOrder != 0 ? timeOrder : a.order.compareTo(b.order);
      });
      final messages = [
        for (var index = 0; index < uniqueMessages.length; index++)
          LandlordMessage(
            text: uniqueMessages[index].message.text,
            time: uniqueMessages[index].message.time,
            fromLandlord: uniqueMessages[index].message.fromLandlord,
            id: uniqueMessages[index].message.id,
            createdAt: uniqueMessages[index].message.createdAt,
            index: index,
            contextId: uniqueMessages[index].message.contextId,
            roomContext: uniqueMessages[index].message.roomContext,
          ),
      ];
      final latestContext = messages
          .where((message) => message.roomContext != null)
          .lastOrNull
          ?.roomContext;
      final contexts = <Map<String, dynamic>>[];
      final contextKeys = <String>{};
      void keepContext(Map<String, dynamic>? context) {
        if (context == null) return;
        final key = '${context['propertyId']}\u0000${context['roomId']}';
        if (contextKeys.add(key)) {
          contexts.add(Map<String, dynamic>.from(context));
        }
      }

      for (final thread in group) {
        for (final context in thread.roomContexts) {
          keepContext(context);
        }
        keepContext(thread.lastRoomContext);
      }
      for (final message in messages) {
        keepContext(message.roomContext);
      }
      final source = latestContext ?? contexts.lastOrNull;
      LandlordConversation? current = _records
          .where(
            (thread) =>
                thread.id == id &&
                thread.propertyId == primary.propertyId &&
                thread.tenantId == tenantId,
          )
          .firstOrNull;
      current ??= LandlordConversation(
        id: id,
        propertyId: primary.propertyId,
        ownerUid: ownerUid,
        tenantId: tenantId,
        tenantName: primary.tenantName,
        landlordName: primary.landlordName,
        propertyName: primary.propertyName,
        room: primary.room,
        leaseId: primary.leaseId,
        messages: [],
      );
      current
        ..tenantName = primary.tenantName
        ..landlordName = primary.landlordName
        ..propertyName =
            latestContext?['propertyName'] as String? ?? primary.propertyName
        ..room = latestContext?['roomName'] as String? ?? primary.room
        ..lastRoomContext = latestContext ?? source
        ..unread = group.fold<int>(
          0,
          (value, thread) => value > thread.unread ? value : thread.unread,
        )
        ..tenantUnread = group.fold<int>(
          0,
          (value, thread) =>
              value > thread.tenantUnread ? value : thread.tenantUnread,
        );
      current.messages
        ..clear()
        ..addAll(messages);
      current.roomContexts
        ..clear()
        ..addAll(contexts);
      merged.add(current);
    }
    return merged;
  }

  LandlordConversation getOrCreate(LandlordConversation conversation) {
    for (final item in _records) {
      if (item.id == conversation.id) return item;
    }
    _records.insert(0, conversation);
    _syncRental();
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
        id: rentalRecordId('message'),
        createdAt: DateTime.now().toUtc(),
        index: conversation.messages.length,
        roomContext: conversation.lastRoomContext,
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

  void updateRoomContext(
    LandlordConversation conversation,
    Map<String, dynamic> context,
  ) {
    final copied = Map<String, dynamic>.from(context);
    conversation
      ..lastRoomContext = copied
      ..room = context['roomName'] as String? ?? conversation.room
      ..propertyName =
          context['propertyName'] as String? ?? conversation.propertyName;
    _addRoomContext(conversation, copied);
    notifyListeners();
  }

  void _addRoomContext(
    LandlordConversation conversation,
    Map<String, dynamic> context,
  ) {
    final propertyId = context['propertyId'];
    final roomId = context['roomId'];
    if (conversation.roomContexts.any(
      (existing) =>
          existing['propertyId'] == propertyId && existing['roomId'] == roomId,
    )) {
      return;
    }
    conversation.roomContexts.add(Map<String, dynamic>.from(context));
  }

  void addContextMessage(
    LandlordConversation conversation, {
    required String contextId,
    required String text,
    required String time,
    required Map<String, dynamic> roomContext,
  }) {
    if (conversation.messages.any(
      (message) => message.contextId == contextId,
    )) {
      return;
    }
    conversation
      ..lastRoomContext = roomContext
      ..room = roomContext['roomName'] as String? ?? conversation.room
      ..propertyName =
          roomContext['propertyName'] as String? ?? conversation.propertyName;
    conversation.messages.add(
      LandlordMessage(
        text: text,
        time: time,
        fromLandlord: false,
        id: contextId,
        contextId: contextId,
        createdAt: DateTime.now().toUtc(),
        index: conversation.messages.length,
        roomContext: roomContext,
      ),
    );
    conversation.unread++;
    notifyListeners();
  }
}
