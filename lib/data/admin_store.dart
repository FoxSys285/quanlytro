import 'package:flutter/foundation.dart';

import '../layouts/role_layout.dart';
import 'local_auth.dart';

class SupportTicket {
  SupportTicket({
    required this.id,
    required this.role,
    required this.title,
    required this.content,
    required this.createdAt,
    this.reply = '',
    this.closed = false,
  });
  final String id;
  final AppRole role;
  final String title;
  final String content;
  final DateTime createdAt;
  String reply;
  bool closed;
  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role.name,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'reply': reply,
    'closed': closed,
  };
  factory SupportTicket.fromMap(Map<String, dynamic> m) => SupportTicket(
    id: m['id'] as String,
    role: AppRole.values.byName(m['role'] as String),
    title: m['title'] as String,
    content: m['content'] as String,
    createdAt: DateTime.parse(m['createdAt'] as String),
    reply: m['reply'] as String,
    closed: m['closed'] as bool,
  );
}

class AdminStore extends ChangeNotifier {
  static final instance = AdminStore();
  final _verified = <String, bool>{};
  final _hidden = <String>{};
  final _tickets = <SupportTicket>[];
  final _logs = <Map<String, String>>[];
  bool acceptingViewings = true;
  bool isVerified(String id) => _verified[id] ?? false;
  bool isHidden(String id) => _hidden.contains(id);
  List<SupportTicket> get tickets => List.unmodifiable(_tickets);
  List<Map<String, String>> get logs => List.unmodifiable(_logs);
  void _requireAdmin() {
    if (LocalAuth.instance.role != AppRole.admin) {
      throw ArgumentError('Chỉ quản trị viên được thực hiện thao tác này.');
    }
  }

  void record(String action) {
    _logs.insert(0, {
      'action': action,
      'at': DateTime.now().toIso8601String(),
      'actor': LocalAuth.instance.role?.label ?? 'Hệ thống',
    });
    if (_logs.length > 500) _logs.removeLast();
    notifyListeners();
  }

  void verify(String id, bool value) {
    _requireAdmin();
    _verified[id] = value;
    record('${value ? 'Xác minh' : 'Thu hồi xác minh'} nhà trọ $id');
  }

  void setHidden(String id, bool hidden) {
    _requireAdmin();
    if (hidden) {
      _hidden.add(id);
    } else {
      _hidden.remove(id);
    }
    record('${hidden ? 'Ẩn' : 'Hiện'} tin đăng của nhà trọ $id');
  }

  void setAcceptingViewings(bool enabled) {
    _requireAdmin();
    acceptingViewings = enabled;
    record('${enabled ? 'Bật' : 'Tắt'} tiếp nhận lịch xem phòng');
  }

  void submitTicket(AppRole role, String title, String content) {
    if (title.trim().length < 5 || content.trim().length < 10) {
      throw ArgumentError(
        'Tiêu đề cần ít nhất 5 ký tự, nội dung ít nhất 10 ký tự.',
      );
    }
    _tickets.insert(
      0,
      SupportTicket(
        id: 'HT-${DateTime.now().microsecondsSinceEpoch}',
        role: role,
        title: title.trim(),
        content: content.trim(),
        createdAt: DateTime.now(),
      ),
    );
    record('${role.label} gửi yêu cầu hỗ trợ: ${title.trim()}');
  }

  void reply(SupportTicket ticket, String reply, bool closed) {
    _requireAdmin();
    if (reply.trim().isEmpty || !_tickets.contains(ticket)) {
      throw ArgumentError('Nhập nội dung phản hồi.');
    }
    ticket.reply = reply.trim();
    ticket.closed = closed;
    record('Phản hồi yêu cầu ${ticket.id}${closed ? ' và đóng yêu cầu' : ''}');
  }

  Map<String, dynamic> toMap() => {
    'verified': _verified,
    'hidden': _hidden.toList(),
    'tickets': _tickets.map((t) => t.toMap()).toList(),
    'logs': _logs,
    'acceptingViewings': acceptingViewings,
  };
  void restore(Map<String, dynamic> map) {
    _verified
      ..clear()
      ..addAll(Map<String, bool>.from(map['verified'] as Map));
    _hidden
      ..clear()
      ..addAll(List<String>.from(map['hidden'] as List));
    _tickets
      ..clear()
      ..addAll(
        (map['tickets'] as List).map(
          (t) => SupportTicket.fromMap(Map<String, dynamic>.from(t as Map)),
        ),
      );
    _logs
      ..clear()
      ..addAll(
        (map['logs'] as List).map((l) => Map<String, String>.from(l as Map)),
      );
    acceptingViewings = map['acceptingViewings'] as bool;
  }
}
