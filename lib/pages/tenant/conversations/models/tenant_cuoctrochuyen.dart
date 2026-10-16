import 'dart:collection';

import '../../../landlord/conversations/models/landlord_cuoctrochuyen.dart';
import '../../../shared/conversations/conversation_store.dart';
import '../../../shared/rental/tenant_session.dart';
import 'tenant_tinnhan.dart';


/// Model đại diện cho một cuộc trò chuyện phía người thuê trọ
/// Lớp này đóng vai trò adapter (cầu nối) đồng bộ tin nhắn 2 chiều với phía chủ trọ
class TenantConversation {
  // Hàm khởi tạo độc lập (dành cho kiểm thử hoặc dữ liệu mẫu)
  TenantConversation({
    required this._landlordName,
    required this._initials,
    required this._contextLabel,
    required this._messages,
    this._unread = 0,
  }) : source = null;

  // Hàm khởi tạo dùng chung dữ liệu với nguồn tin nhắn phía chủ trọ
  TenantConversation.shared(this.source)
    : _landlordName = '',
      _initials = '',
      _contextLabel = '',
      _messages = [],
      _unread = 0;

  // Nguồn dữ liệu gốc từ phía chủ trọ (nếu có)
  final LandlordConversation? source;

  // Tên chủ trọ
  final String _landlordName;

  // Chữ viết tắt đại diện ảnh đại diện (avatar)
  final String _initials;

  // Nhãn ngữ cảnh (ví dụ: Chủ trọ · Phòng 101)
  final String _contextLabel;

  // Danh sách tin nhắn nội bộ
  final List<TenantConversationMessage> _messages;

  // Số lượng tin nhắn chưa đọc
  int _unread;

  // Lấy tên chủ trọ
  String get landlordName {
    if (source != null) {
      return source!.landlordName;
    } else {
      return _landlordName;
    }
  }

  // Lấy chữ cái đầu của tên chủ trọ để làm ảnh đại diện (sử dụng LINQ gọn gàng)
  String get initials {
    if (source == null) return _initials;
    return landlordName
        .split(' ')
        .where((tu) => tu.trim().isNotEmpty)
        .map((tu) => tu.trim()[0])
        .take(2)
        .join();
  }

  // Lấy nhãn mô tả phòng của cuộc trò chuyện
  String get contextLabel {
    if (source == null) {
      return _contextLabel;
    }
    if (source!.leaseId == null) {
      return 'Chủ trọ · ${source!.room}';
    } else {
      return 'Chủ trọ · Phòng ${source!.room}';
    }
  }

  // Lấy danh sách tin nhắn của cuộc trò chuyện
  List<TenantConversationMessage> get messages {
    if (source == null) {
      return _messages;
    } else {
      return _SharedMessages(source!);
    }
  }

  // Lấy số lượng tin nhắn chưa đọc
  int get unread {
    if (source != null) {
      return source!.tenantUnread;
    } else {
      return _unread;
    }
  }

  // Cập nhật số lượng tin nhắn chưa đọc
  set unread(int value) {
    if (source == null) {
      _unread = value;
    } else {
      source!.tenantUnread = value;
    }
  }

  // Bộ nhớ tạm lưu các adapter cuộc trò chuyện đã tạo
  static final _adapters = <String, TenantConversation>{};

  // Danh sách cuộc trò chuyện mẫu lấy từ kho dữ liệu dùng chung (sử dụng LINQ map)
  static List<TenantConversation> get demoConversations => ConversationStore
      .instance
      .forTenant(TenantSession.tenantId)
      .map(
        (source) => _adapters.putIfAbsent(
          source.id,
          () => TenantConversation.shared(source),
        ),
      )
      .toList();


  // Hàm gửi tin nhắn mới
  void send(String text, String time) {
    if (source == null) {
      _messages.add(
        TenantConversationMessage(
          text: text,
          time: time,
          fromTenant: true,
        ),
      );
    } else {
      ConversationStore.instance.send(
        source!,
        text: text,
        time: time,
        fromLandlord: false,
        tenantId: TenantSession.tenantId,
      );
    }
  }
}

/// Lớp trung gian ánh xạ danh sách tin nhắn giữa Landlord và Tenant
class _SharedMessages extends ListBase<TenantConversationMessage> {
  _SharedMessages(this.conversation);

  final LandlordConversation conversation;

  @override
  int get length => conversation.messages.length;

  @override
  set length(int value) {
    if (value > length) {
      throw UnsupportedError('Dùng hàm add để thêm tin nhắn mới.');
    }
    conversation.messages.removeRange(value, length);
  }

  @override
  TenantConversationMessage operator [](int index) {
    final message = conversation.messages[index];
    return TenantConversationMessage(
      text: message.text,
      time: message.time,
      fromTenant: !message.fromLandlord,
    );
  }

  @override
  void operator []=(int index, TenantConversationMessage value) {
    conversation.messages[index] = LandlordMessage(
      text: value.text,
      time: value.time,
      fromLandlord: !value.fromTenant,
    );
  }

  @override
  void add(TenantConversationMessage value) {
    conversation.messages.add(
      LandlordMessage(
        text: value.text,
        time: value.time,
        fromLandlord: !value.fromTenant,
      ),
    );
  }
}

// Biệt danh tiếng Việt dễ nhớ
typedef TenantCuocTroChuyen = TenantConversation;

