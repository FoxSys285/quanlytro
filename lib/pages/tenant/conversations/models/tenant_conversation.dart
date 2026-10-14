import 'dart:collection';

import '../../../landlord/conversations/models/landlord_conversation.dart';
import '../../../shared/conversations/conversation_store.dart';
import '../../../shared/rental/tenant_session.dart';
import 'tenant_conversation_message.dart';

/// Tenant presentation adapter over the same messages used by the landlord.
class TenantConversation {
  TenantConversation({
    required this._landlordName,
    required this._initials,
    required this._contextLabel,
    required this._messages,
    this._unread = 0,
  }) : source = null;
  TenantConversation.shared(this.source)
    : _landlordName = '',
      _initials = '',
      _contextLabel = '',
      _messages = [],
      _unread = 0;
  final LandlordConversation? source;
  final String _landlordName;
  final String _initials;
  final String _contextLabel;
  final List<TenantConversationMessage> _messages;
  int _unread;
  String get landlordName => source?.landlordName ?? _landlordName;
  String get initials => source == null
      ? _initials
      : landlordName
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0])
            .take(2)
            .join();
  String get contextLabel => source == null
      ? _contextLabel
      : source!.leaseId == null
      ? 'Chủ trọ · ${source!.room}'
      : 'Chủ trọ · Phòng ${source!.room}';
  List<TenantConversationMessage> get messages =>
      source == null ? _messages : _SharedMessages(source!);
  int get unread => source?.tenantUnread ?? _unread;
  set unread(int value) {
    if (source == null) {
      _unread = value;
    } else {
      source!.tenantUnread = value;
    }
  }

  static final _adapters = <String, TenantConversation>{};
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
  void send(String text, String time) {
    if (source == null) {
      _messages.add(
        TenantConversationMessage(text: text, time: time, fromTenant: true),
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

class _SharedMessages extends ListBase<TenantConversationMessage> {
  _SharedMessages(this.conversation);
  final LandlordConversation conversation;
  @override
  int get length => conversation.messages.length;
  @override
  set length(int value) {
    if (value > length) throw UnsupportedError('Use add to append a message.');
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
  void add(TenantConversationMessage value) => conversation.messages.add(
    LandlordMessage(
      text: value.text,
      time: value.time,
      fromLandlord: !value.fromTenant,
    ),
  );
}
