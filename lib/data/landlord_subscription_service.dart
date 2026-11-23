import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../layouts/role_layout.dart';
import 'firebase_account_gateway.dart';
import 'landlord_plans.dart';

class LandlordPlanOrder {
  const LandlordPlanOrder({
    required this.id,
    required this.landlordUid,
    required this.landlordName,
    required this.landlordEmail,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.paymentReference,
    required this.status,
    required this.createdAt,
    this.paymentSettings,
    this.paymentNote = '',
    this.adminNote = '',
    this.submittedAt,
    this.reviewedAt,
    this.startsAt,
    this.expiresAt,
  });

  final String id;
  final String landlordUid;
  final String landlordName;
  final String landlordEmail;
  final String planId;
  final String planName;
  final int amount;
  final String paymentReference;
  final String status;
  final DateTime? createdAt;
  final SubscriptionPaymentSettings? paymentSettings;
  final String paymentNote;
  final String adminNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  bool get isOpen => status == 'awaiting_payment' || status == 'submitted';
  bool get isSimulated => paymentReference.startsWith('DEMO');
  bool get isActive {
    final now = DateTime.now();
    return status == 'approved' &&
        startsAt != null &&
        expiresAt != null &&
        !startsAt!.isAfter(now) &&
        expiresAt!.isAfter(now);
  }

  factory LandlordPlanOrder.fromMap(String id, Map<String, dynamic> data) {
    return LandlordPlanOrder(
      id: id,
      landlordUid: data['landlordUid'] as String? ?? '',
      landlordName: data['landlordName'] as String? ?? '',
      landlordEmail: data['landlordEmail'] as String? ?? '',
      planId: data['planId'] as String? ?? 'free',
      planName: data['planName'] as String? ?? 'Free',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      paymentReference: data['paymentReference'] as String? ?? '',
      status: data['status'] as String? ?? 'unknown',
      createdAt: _date(data['createdAt']),
      paymentSettings: data['paymentBankBin'] is String
          ? SubscriptionPaymentSettings(
              bankName: data['paymentBankName'] as String? ?? '',
              bankBin: data['paymentBankBin'] as String? ?? '',
              accountName: data['paymentAccountName'] as String? ?? '',
              accountNumber: data['paymentAccountNumber'] as String? ?? '',
              instructions: data['paymentInstructions'] as String? ?? '',
            )
          : null,
      paymentNote: data['paymentNote'] as String? ?? '',
      adminNote: data['adminNote'] as String? ?? '',
      submittedAt: _date(data['submittedAt']),
      reviewedAt: _date(data['reviewedAt']),
      startsAt: _date(data['startsAt']),
      expiresAt: _date(data['expiresAt']),
    );
  }
}

class SubscriptionPaymentSettings {
  const SubscriptionPaymentSettings({
    required this.bankName,
    required this.bankBin,
    required this.accountName,
    required this.accountNumber,
    this.instructions = '',
  });

  final String bankName;
  final String bankBin;
  final String accountName;
  final String accountNumber;
  final String instructions;

  bool get isConfigured =>
      bankName.isNotEmpty &&
      RegExp(r'^\d{6}$').hasMatch(bankBin) &&
      accountName.isNotEmpty &&
      RegExp(r'^\d{6,19}$').hasMatch(accountNumber);

  factory SubscriptionPaymentSettings.fromMap(Map<String, dynamic> data) =>
      SubscriptionPaymentSettings(
        bankName: data['bankName'] as String? ?? '',
        bankBin: data['bankBin'] as String? ?? '',
        accountName: data['accountName'] as String? ?? '',
        accountNumber: data['accountNumber'] as String? ?? '',
        instructions: data['instructions'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'bankName': bankName.trim(),
    'bankBin': bankBin.trim(),
    'accountName': accountName.trim(),
    'accountNumber': accountNumber.trim(),
    'instructions': instructions.trim(),
  };
}

/// Subscription orders and payment records live in Supabase. Firebase Auth
/// remains the identity provider, while Firestore remains the app data store.
class LandlordSubscriptionService {
  LandlordSubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? client,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client();

  static final instance = LandlordSubscriptionService();
  static const settingsPath = 'public_settings/subscription_payment';
  static const ordersPath = 'subscription_orders';
  static const _legacyBatchSize = 100;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _client;
  Future<bool>? _legacyMigration;
  bool _legacyMigrationComplete = false;
  final _pollers = <String, Object>{};

  Stream<List<LandlordPlanOrder>> watchLandlordOrders(String uid) => _poll(
    'landlord-orders:$uid',
    () async {
      if (_auth.currentUser?.uid != uid) {
        throw StateError('Chỉ xem được yêu cầu của tài khoản đang đăng nhập.');
      }
      return _readOrders();
    },
  );

  Stream<List<LandlordPlanOrder>> watchAllOrders() =>
      _poll('admin-orders', () async {
        await _ensureLegacyImported();
        return _readOrders();
      });

  Stream<List<Map<String, dynamic>>> watchSePayUnmatchedTransactions() =>
      _poll('admin-unmatched-transactions', () async {
        final response = await _call('listUnmatched');
        return (response['transactions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
      });

  Future<List<LandlordPlanOrder>> loadLandlordOrders(String uid) async {
    if (_auth.currentUser?.uid != uid) {
      throw StateError('Chỉ xem được yêu cầu của tài khoản đang đăng nhập.');
    }
    return _readOrders();
  }

  Stream<SubscriptionPaymentSettings?> watchPaymentSettings() =>
      _poll('subscription-payment-settings', loadPaymentSettings);

  Future<SubscriptionPaymentSettings?> loadPaymentSettings() async {
    final response = await _call('getPaymentSettings');
    final data = response['settings'];
    if (data is! Map<String, dynamic>) return null;
    return SubscriptionPaymentSettings.fromMap(data);
  }

  Future<LandlordPlanOrder> createOrder({
    required FirebaseAccountSession session,
    required LandlordPlan plan,
    required SubscriptionPaymentSettings paymentSettings,
  }) async {
    if (session.role != AppRole.landlord || plan.id == 'free') {
      throw ArgumentError('Chỉ chủ trọ có thể đăng ký gói trả phí.');
    }
    if (!paymentSettings.isConfigured) {
      throw ArgumentError('Admin chưa cấu hình tài khoản nhận thanh toán.');
    }
    final response = await _call('createOrder', {'planId': plan.id});
    final data = response['order'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Backend không trả về đơn đăng ký hợp lệ.');
    }
    return LandlordPlanOrder.fromMap((data['id'] ?? '').toString(), data);
  }

  Future<void> submitPayment({
    required String orderId,
    required String paymentNote,
  }) async {
    final note = paymentNote.trim();
    if (note.length < 4 || note.length > 300) {
      throw ArgumentError(
        'Nhập mã giao dịch hoặc thông tin chuyển khoản hợp lệ.',
      );
    }
    await _call('submitPayment', {'orderId': orderId, 'paymentNote': note});
  }

  Future<LandlordPlanOrder> prepareSimulatedPayment({
    required FirebaseAccountSession session,
    LandlordPlan? plan,
    String? orderId,
  }) async {
    if (session.role != AppRole.landlord) {
      throw ArgumentError('Chỉ chủ trọ có thể đăng ký gói dịch vụ.');
    }
    if ((plan == null) == (orderId == null)) {
      throw ArgumentError('Chọn gói hoặc yêu cầu cần chuẩn bị thanh toán.');
    }
    if (plan != null && plan.id == 'free') {
      throw ArgumentError('Gói Free không cần thanh toán.');
    }

    final response = await _call('prepareSimulatedPayment', {
      if (plan != null) 'planId': plan.id,
      if (orderId != null) 'orderId': orderId,
    });
    final data = response['order'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Backend không trả về yêu cầu thanh toán hợp lệ.');
    }
    final order = LandlordPlanOrder.fromMap(
      (data['id'] ?? '').toString(),
      data,
    );
    _publishLandlordOrder(session.uid, order);
    return order;
  }

  Future<LandlordPlanOrder> simulatePayment({
    required FirebaseAccountSession session,
    required String orderId,
  }) async {
    if (session.role != AppRole.landlord) {
      throw ArgumentError('Chỉ chủ trọ có thể giả lập thanh toán.');
    }
    if (orderId.trim().isEmpty) {
      throw ArgumentError('Yêu cầu thanh toán không hợp lệ.');
    }
    final response = await _call('simulatePayment', {'orderId': orderId});
    final data = response['order'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Backend không trả về kết quả thanh toán hợp lệ.');
    }
    final order = LandlordPlanOrder.fromMap(
      (data['id'] ?? '').toString(),
      data,
    );
    _publishLandlordOrder(session.uid, order);
    return order;
  }

  Future<void> cancelUnpaidOrder(String orderId) async {
    await _call('cancelOrder', {'orderId': orderId});
  }

  Future<void> reviewOrder({
    required LandlordPlanOrder order,
    required String adminUid,
    required bool approve,
    required String note,
  }) async {
    final trimmedNote = note.trim();
    if (!approve && trimmedNote.isEmpty) {
      throw ArgumentError('Nhập lý do từ chối yêu cầu.');
    }
    if (trimmedNote.length > 500) {
      throw ArgumentError('Ghi chú không được vượt quá 500 ký tự.');
    }
    if (adminUid.isEmpty) throw ArgumentError('Phiên admin không hợp lệ.');
    await _call('reviewOrder', {
      'orderId': order.id,
      'approve': approve,
      'note': trimmedNote,
    });
  }

  Future<void> savePaymentSettings({
    required SubscriptionPaymentSettings settings,
    required String adminUid,
  }) async {
    if (!settings.isConfigured) {
      throw ArgumentError('Kiểm tra ngân hàng, BIN và số tài khoản nhận tiền.');
    }
    if (settings.instructions.length > 300) {
      throw ArgumentError('Hướng dẫn chuyển khoản tối đa 300 ký tự.');
    }
    if (adminUid.isEmpty) throw ArgumentError('Phiên admin không hợp lệ.');
    final response = await _call('savePaymentSettings', {
      'settings': settings.toMap(),
    });
    final data = response['settings'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Backend không xác nhận cấu hình tài khoản đã lưu.');
    }
    final saved = SubscriptionPaymentSettings.fromMap(data);
    final requested = settings.toMap();
    final persisted = saved.toMap();
    if (requested.entries.any((entry) => persisted[entry.key] != entry.value)) {
      throw StateError(
        'Dữ liệu backend trả về chưa khớp với thông tin vừa lưu.',
      );
    }
    final channel = _pollers['subscription-payment-settings'];
    if (channel is _PollingChannel<SubscriptionPaymentSettings?>) {
      channel.publish(saved);
    }
  }

  Future<LandlordPlan> activePlanFor(String uid) async {
    final orders = await loadLandlordOrders(uid);
    return LandlordPlan.byId(activeOrder(orders)?.planId);
  }

  static LandlordPlanOrder? activeOrder(
    Iterable<LandlordPlanOrder> orders, {
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final active =
        orders
            .where(
              (order) =>
                  order.status == 'approved' &&
                  order.startsAt != null &&
                  order.expiresAt != null &&
                  !order.startsAt!.isAfter(time) &&
                  order.expiresAt!.isAfter(time),
            )
            .toList()
          ..sort((a, b) => b.startsAt!.compareTo(a.startsAt!));
    return active.isEmpty ? null : active.first;
  }

  Future<List<LandlordPlanOrder>> _readOrders() async {
    final response = await _call('listOrders');
    final rows = response['orders'] as List<dynamic>? ?? const [];
    final orders = rows
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => LandlordPlanOrder.fromMap((row['id'] ?? '').toString(), row),
        )
        .toList();
    orders.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return orders;
  }

  void _publishLandlordOrder(String uid, LandlordPlanOrder order) {
    final channel = _pollers['landlord-orders:$uid'];
    if (channel is! _PollingChannel<List<LandlordPlanOrder>>) return;
    final orders = channel._hasValue
        ? List<LandlordPlanOrder>.of(
            channel._lastValue as List<LandlordPlanOrder>,
          )
        : <LandlordPlanOrder>[];
    orders.removeWhere((existing) => existing.id == order.id);
    orders.add(order);
    orders.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    channel.publish(orders);
  }

  Stream<T> _poll<T>(String key, Future<T> Function() load) {
    final existing = _pollers[key];
    if (existing != null) return (existing as _PollingChannel<T>).stream;
    final channel = _PollingChannel<T>(load);
    _pollers[key] = channel;
    return channel.stream;
  }

  Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Phiên Firebase đã hết hạn. Hãy đăng nhập lại.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError(
        'Không lấy được phiên xác thực Firebase. Hãy đăng nhập lại.',
      );
    }
    final response = await _client
        .post(
          Uri.parse('$_functionsUrl/subscription-api'),
          headers: {
            'Authorization': 'Bearer $token',
            'apikey': _publishableKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'action': action, ...values}),
        )
        .timeout(const Duration(seconds: 25));
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError(
        'Backend đăng ký gói trả về dữ liệu không hợp lệ (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ArgumentError(
        (decoded['error'] ?? 'Không xử lý được yêu cầu đăng ký gói.')
            .toString(),
      );
    }
    return decoded;
  }

  Future<void> _ensureLegacyImported() async {
    if (_legacyMigrationComplete) return;
    final pending = _legacyMigration ??= _migrateLegacyData();
    try {
      _legacyMigrationComplete = await pending;
    } finally {
      if (identical(_legacyMigration, pending)) _legacyMigration = null;
    }
  }

  Future<bool> _migrateLegacyData() async {
    try {
      final status = await _call('legacyMigrationStatus');
      if (status['completed'] == true) return true;
      final settingsDocument = await _firestore.doc(settingsPath).get();
      final ordersSnapshot = await _firestore.collection(ordersPath).get();
      final unmatchedSnapshot = await _firestore
          .collection('sepay_unmatched_transactions')
          .get();
      final orders = ordersSnapshot.docs
          .map((document) => {'id': document.id, ..._jsonMap(document.data())})
          .toList();
      final unmatched = unmatchedSnapshot.docs
          .map((document) => {'id': document.id, ..._jsonMap(document.data())})
          .toList();
      final batchCount = [
        (orders.length + _legacyBatchSize - 1) ~/ _legacyBatchSize,
        (unmatched.length + _legacyBatchSize - 1) ~/ _legacyBatchSize,
        1,
      ].reduce((left, right) => left > right ? left : right);
      for (var index = 0; index < batchCount; index++) {
        final orderStart = index * _legacyBatchSize;
        final unmatchedStart = index * _legacyBatchSize;
        await _call('migrateLegacy', {
          'settings': index == 0 && settingsDocument.exists
              ? _jsonSafe(settingsDocument.data())
              : null,
          'orders': orders.skip(orderStart).take(_legacyBatchSize).toList(),
          'unmatched': unmatched
              .skip(unmatchedStart)
              .take(_legacyBatchSize)
              .toList(),
          'finalBatch': index == batchCount - 1,
        });
      }
      return true;
    } catch (error) {
      debugPrint('Legacy subscription import deferred: $error');
      return false;
    }
  }

  static Map<String, dynamic> _jsonMap(Map<String, dynamic> value) =>
      (_jsonSafe(value) as Map).map((key, nested) => MapEntry('$key', nested));

  static Object? _jsonSafe(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map((key, nested) => MapEntry('$key', _jsonSafe(nested)));
    }
    if (value is Iterable) return value.map(_jsonSafe).toList();
    return value;
  }

  static const _functionsUrl = String.fromEnvironment(
    'TROPREMIUM_INTEGRATIONS_BACKEND_URL',
    defaultValue: 'https://hihsjrdzbtfldlscigzi.supabase.co/functions/v1',
  );
  static const _publishableKey = String.fromEnvironment(
    'TROPREMIUM_SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_2oautia3Tc3XUFP1VGlVQw__uNfvWGC',
  );
}

class _PollingChannel<T> {
  _PollingChannel(this._load);

  final Future<T> Function() _load;
  final _events = StreamController<T>.broadcast();
  T? _lastValue;
  Timer? _timer;
  int _listeners = 0;
  bool _hasValue = false;
  bool _loading = false;
  int _revision = 0;

  Stream<T> get stream => Stream<T>.multi((controller) {
    final startPolling = _listeners == 0;
    _listeners++;
    final subscription = _events.stream.listen(
      controller.add,
      onError: (Object error, StackTrace stackTrace) =>
          controller.addError(error, stackTrace),
    );
    if (_hasValue) controller.add(_lastValue as T);
    controller.onCancel = () async {
      await subscription.cancel();
      _listeners--;
      if (_listeners == 0) {
        _timer?.cancel();
        _timer = null;
      }
    };
    if (startPolling) unawaited(_refresh());
  }, isBroadcast: true);

  Future<void> _refresh() async {
    if (_loading || _listeners == 0) return;
    _loading = true;
    final revision = _revision;
    try {
      final value = await _load();
      if (revision == _revision) {
        _lastValue = value;
        _hasValue = true;
        if (_listeners > 0) _events.add(value);
      }
    } catch (error, stackTrace) {
      if (_listeners > 0 && revision == _revision) {
        _events.addError(error, stackTrace);
      }
    } finally {
      _loading = false;
      if (_listeners > 0) {
        _timer = Timer(const Duration(seconds: 8), () {
          unawaited(_refresh());
        });
      }
    }
  }

  void publish(T value) {
    _revision++;
    _lastValue = value;
    _hasValue = true;
    if (_listeners > 0) _events.add(value);
  }
}

DateTime? _date(Object? value) => switch (value) {
  Timestamp timestamp => timestamp.toDate(),
  DateTime date => date,
  String date => DateTime.tryParse(date),
  _ => null,
};
