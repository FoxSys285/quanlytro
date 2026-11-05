import 'package:flutter/foundation.dart';

import '../layouts/role_layout.dart';
import 'local_auth.dart';
import 'admin_commission.dart';
import 'rental_cloud_codec.dart';
import '../pages/landlord/landlord_demo_store.dart';

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
  AdminStore({RentalPortfolio? portfolio}) : _rental = portfolio;
  final RentalPortfolio? _rental;
  RentalPortfolio get _portfolio => _rental ?? RentalPortfolio.instance;
  static final instance = AdminStore();
  final _verified = <String, bool>{};
  final _verificationProofs = <String, String>{};
  final _reviewNotes = <String, String>{};
  final _commissionRates = <String, int>{};
  final _statements = <CommissionStatement>[];
  final _hidden = <String>{};
  final _tickets = <SupportTicket>[];
  final _logs = <Map<String, String>>[];
  bool acceptingViewings = true;
  bool isVerified(String id) {
    final store = _portfolio.byId(id);
    return store != null &&
        _verified[id] == true &&
        _verificationProofs[id] == _proof(store);
  }

  String reviewNote(String id) => _reviewNotes[id] ?? '';
  int? commissionRate(String id) => _commissionRates[id];
  List<CommissionStatement> get statements => List.unmodifiable(_statements);

  void editMemberContact(
    String propertyId,
    String memberId,
    String name,
    String phone,
  ) {
    _requireAdmin();
    name = name.trim();
    phone = phone.trim().replaceAll(RegExp(r'[\s.-]'), '');
    if (name.isEmpty ||
        name.length > 100 ||
        !RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
      throw ArgumentError(
        'Nhập họ tên tối đa 100 ký tự và số điện thoại hợp lệ.',
      );
    }
    final store = _portfolio.byId(propertyId);
    final member = store?.members.where((m) => m.id == memberId).firstOrNull;
    if (member == null) throw ArgumentError('Không tìm thấy hồ sơ người thuê.');
    store!.updateTenantContact(member.tenantId, name: name, phone: phone);
    record('Cập nhật liên hệ người thuê ${member.tenantId} tại $propertyId');
  }

  static String _proof(LandlordDemoStore store) => propertyVerificationProof({
    'property': store.property.toMap(),
    'rooms': store.catalog.map((r) => r.toMap()).toList(),
    'roomTypes': store.roomTypes.map((r) => r.toMap()).toList(),
  });

  static List<String> verificationIssues(LandlordDemoStore store) {
    final p = store.property;
    final verificationFiles = {
      for (final document in p.verificationDocuments)
        document.id: document.files
            .where(
              (file) =>
                  file.bytes?.isNotEmpty == true ||
                  (file.storagePath ?? '').isNotEmpty,
            )
            .length,
    };
    return [
      if (p.name.trim().isEmpty) 'Tên nhà trọ',
      if (p.address.trim().isEmpty ||
          p.city.trim().isEmpty ||
          p.ward.trim().isEmpty)
        'Địa chỉ đầy đủ',
      if (p.ownerName.trim().isEmpty) 'Họ tên chủ trọ',
      if (!RegExp(r'^(0\d{9}|\+84\d{9})$')
          .hasMatch(p.phone.replaceAll(RegExp(r'[\s.-]'), '')))
        'Số điện thoại hợp lệ',
      if (p.description.trim().length < 20) 'Mô tả ít nhất 20 ký tự',
      if ((p.imageBytes?.isNotEmpty != true) && p.imageUrl.trim().isEmpty)
        'Ảnh nhà trọ',
      if (store.catalog.isEmpty) 'Danh sách phòng',
      if (store.catalog.any(
        (room) =>
            room.area <= 0 ||
            room.capacity <= 0 ||
            !store.roomTypes.any(
              (type) => type.id == room.roomTypeId && type.monthlyRent > 0,
            ),
      ))
        'Diện tích, sức chứa và giá thuê từng phòng',
      if (p.verificationSubmittedAt == null) 'Hồ sơ giấy tờ xác minh',
      if ((verificationFiles['portrait'] ?? 0) == 0) 'Ảnh chân dung chủ trọ',
      if ((verificationFiles['identity'] ?? 0) == 0) 'CCCD / thẻ căn cước',
      if ((verificationFiles['ownership'] ?? 0) == 0) 'Sổ đỏ / sổ hồng',
      if (!p.verificationIsOwner &&
          (verificationFiles['authorization'] ?? 0) == 0)
        'Giấy ủy quyền cho thuê nhà',
    ];
  }

  void requestSupplement(String id, String reason) {
    _requireAdmin();
    if (_portfolio.byId(id) == null || reason.trim().length < 10) {
      throw ArgumentError('Chọn nhà trọ và nhập yêu cầu ít nhất 10 ký tự.');
    }
    _verified[id] = false;
    _reviewNotes[id] = reason.trim();
    record('Yêu cầu nhà trọ $id bổ sung: ${reason.trim()}');
  }

  void setCommissionRate(String id, int basisPoints) {
    _requireAdmin();
    if (_portfolio.byId(id) == null || basisPoints < 0 || basisPoints > 10000) {
      throw ArgumentError('Tỷ lệ hoa hồng phải từ 0 đến 100%.');
    }
    _commissionRates[id] = basisPoints;
    record(
      'Đặt hoa hồng nhà trọ $id: ${basisPoints / 100}% (chỉ áp dụng kỳ chưa chốt)',
    );
  }

  CommissionStatement closeCommission(String id, DateTime month) {
    _requireAdmin();
    final now = DateTime.now();
    if (!DateTime(
      month.year,
      month.month,
    ).isBefore(DateTime(now.year, now.month))) {
      throw ArgumentError('Chỉ chốt đối soát sau khi kết thúc tháng.');
    }
    final store = _portfolio.byId(id);
    final rate = _commissionRates[id];
    if (store == null || rate == null) {
      throw ArgumentError('Cần thiết lập tỷ lệ hoa hồng trước.');
    }
    if (_statements.any(
      (s) =>
          s.propertyId == id &&
          s.month.year == month.year &&
          s.month.month == month.month,
    )) {
      throw ArgumentError('Kỳ này đã chốt, không thể tạo trùng.');
    }
    final statement = CommissionStatement(
      propertyId: id,
      propertyName: store.property.name,
      month: DateTime(month.year, month.month),
      rentCollected: commissionRentCollected(store, month),
      rateBasisPoints: rate,
      createdAt: now,
    );
    _statements.insert(0, statement);
    record(
      'Chốt hoa hồng $id kỳ ${month.month}/${month.year}: ${statement.due} đ',
    );
    return statement;
  }

  void receiveCommission(
    CommissionStatement statement,
    int amount,
    String reference,
  ) {
    _requireAdmin();
    if (!_statements.contains(statement)) {
      throw ArgumentError('Không tìm thấy kỳ đối soát.');
    }
    statement.receive(amount, reference, DateTime.now());
    record('Nhận hoa hồng ${statement.id}: $amount đ · ${reference.trim()}');
  }

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
    final store = _portfolio.byId(id);
    if (store == null) throw ArgumentError('Không tìm thấy nhà trọ.');
    if (value && verificationIssues(store).isNotEmpty) {
      throw ArgumentError(
        'Hồ sơ còn thiếu: ${verificationIssues(store).join(', ')}.',
      );
    }
    _verified[id] = value;
    if (value) {
      _verificationProofs[id] = _proof(store);
      _reviewNotes.remove(id);
    }
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
    'verificationProofs': _verificationProofs,
    'reviewNotes': _reviewNotes,
    'commissionRates': _commissionRates,
    'commissionStatements': _statements.map((s) => s.toMap()).toList(),
    'verified': _verified,
    'hidden': _hidden.toList(),
    'tickets': _tickets.map((t) => t.toMap()).toList(),
    'logs': _logs,
    'acceptingViewings': acceptingViewings,
  };
  void restore(Map<String, dynamic> map) {
    _verificationProofs
      ..clear()
      ..addAll(
        Map<String, String>.from(map['verificationProofs'] as Map? ?? {}),
      );
    _reviewNotes
      ..clear()
      ..addAll(Map<String, String>.from(map['reviewNotes'] as Map? ?? {}));
    _commissionRates
      ..clear()
      ..addAll(Map<String, int>.from(map['commissionRates'] as Map? ?? {}));
    _statements
      ..clear()
      ..addAll(
        (map['commissionStatements'] as List? ?? []).map(
          (s) =>
              CommissionStatement.fromMap(Map<String, dynamic>.from(s as Map)),
        ),
      );
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
    notifyListeners();
  }
}
