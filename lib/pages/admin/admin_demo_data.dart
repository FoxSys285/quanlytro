import 'package:flutter/foundation.dart';

import 'dart:convert';

import '../../data/admin_store.dart';
import '../../data/admin_commission.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../landlord/finance/landlord_finance_models.dart';

typedef AdminAccount = ({
  String id,
  String email,
  String name,
  String role,
  bool disabled,
});

/// Bộ mẫu riêng; tự lưu local, chỉ gửi Firebase khi admin chọn lưu.
class AdminDemoData extends ChangeNotifier {
  static final instance = AdminDemoData();
  bool enabled = false;
  bool syncing = false;
  String syncMessage = '';
  void setSyncState(bool busy, String message) {
    syncing = busy;
    syncMessage = message;
    notifyListeners();
  }

  RentalPortfolio? _portfolio;
  AdminStore? _admin;
  RentalPortfolio get portfolio => _portfolio ??= _buildPortfolio();
  AdminStore get admin => _admin ??= _buildAdmin();
  final _locked = <String>{'sample-4', 'sample-9'};
  DateTime now = DateTime.now();
  DateTime get month => DateTime(now.year, now.month - 1);

  void toggle() {
    enabled = !enabled;
    notifyListeners();
  }

  List<AdminAccount> get accounts {
    final members = [for (final s in portfolio.stores) ...s.members]
        .take(20)
        .toList();
    return [
      (
        id: 'sample-admin',
        email: 'admin@example.invalid',
        name: 'Quản trị viên mẫu',
        role: 'admin',
        disabled: false,
      ),
      for (var i = 0; i < 3 && i < portfolio.stores.length; i++)
        (
          id: 'sample-owner-$i',
          email: 'chutro${i + 1}@example.invalid',
          name: portfolio.stores[i].property.ownerName,
          role: 'landlord',
          disabled: _locked.contains('sample-owner-$i'),
        ),
      for (var i = 0; i < members.length; i++)
        (
          id: 'sample-$i',
          email: 'nguoithue${i + 1}@example.invalid',
          name: members[i].name,
          role: 'tenant',
          disabled: _locked.contains('sample-$i'),
        ),
    ];
  }

  void setLocked(String id, bool locked) {
    _requireAdmin();
    if (!accounts.any((a) => a.id == id && a.role != 'admin')) {
      throw ArgumentError('Không thể thay đổi tài khoản này.');
    }
    if (locked) {
      _locked.add(id);
    } else {
      _locked.remove(id);
    }
    notifyListeners();
  }

  void _requireAdmin() {
    if (LocalAuth.instance.role != AppRole.admin) {
      throw ArgumentError('Chỉ quản trị viên được sửa dữ liệu mẫu.');
    }
  }

  void editMember(
    String propertyId,
    String memberId,
    String name,
    String phone,
  ) {
    _requireAdmin();
    name = name.trim();
    phone = phone.trim().replaceAll(' ', '');
    if (name.isEmpty ||
        name.length > 100 ||
        !RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
      throw ArgumentError(
        'Nhập tên tối đa 100 ký tự và số điện thoại từ 9–15 chữ số.',
      );
    }
    final store = portfolio.byId(propertyId);
    final member = store?.members.where((m) => m.id == memberId).firstOrNull;
    if (member == null) throw ArgumentError('Không tìm thấy hồ sơ.');
    if (member.isRepresentative) {
      // Người đại diện được dựng từ hợp đồng, phải sửa nguồn để lưu bền vững.
      final lease = store!.leaseById(member.leaseId);
      if (lease == null) throw ArgumentError('Không tìm thấy hợp đồng.');
      lease.tenantName = name;
      lease.phone = phone;
    } else {
      member.name = name;
      member.phone = phone;
    }
    notifyListeners();
  }

  RentalPortfolio _buildPortfolio() {
    final result = RentalPortfolio.seeded();
    for (var i = 0; i < result.stores.length; i++) {
      final store = result.stores[i];
      final map = store.toMap();
      final invoices = <Map<String, dynamic>>[];
      final payments = <Map<String, dynamic>>[];
      for (var offset = 0; offset < 3; offset++) {
        final period = DateTime(month.year, month.month - offset);
        final amount = 12000000 + i * 2500000 + offset * 500000;
        final invoice = LandlordInvoice(
          id: 'DEMO-${store.property.id}-$offset',
          leaseId: store.leases.first.id,
          room: store.leases.first.room,
          tenantName: store.leases.first.tenantName,
          period: period,
          dueDate: DateTime(period.year, period.month, 10),
          charges: [
            LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: amount),
            const LandlordInvoiceCharge(name: 'Điện nước', amount: 600000),
          ],
          paidAmount: amount + 600000,
        );
        invoices.add(invoice.toMap());
        payments.add(
          (LandlordPayment(
            id: 'DEMO-THU-${store.property.id}-$offset',
            invoiceId: invoice.id,
            tenantName: invoice.tenantName,
            room: invoice.room,
            reportedAmount: invoice.total,
            approvedAmount: invoice.total,
            paidAt: DateTime(period.year, period.month, 8),
            method: 'Chuyển khoản',
            reference: 'DEMO-$i-$offset',
            status: LandlordPaymentStatus.approved,
          )..reviewedAt = DateTime(period.year, period.month, 9)).toMap(),
        );
      }
      map['invoices'] = invoices;
      map['payments'] = payments;
      store.restore(map);
    }
    result.addListener(notifyListeners);
    return result;
  }

  AdminStore _buildAdmin() {
    final result = AdminStore(portfolio: portfolio);
    result.addListener(notifyListeners);
    final rates = <String, int>{};
    final statements = <Map<String, dynamic>>[];
    for (var i = 0; i < portfolio.stores.length; i++) {
      final store = portfolio.stores[i];
      if (i != 0) rates[store.property.id] = 500;
      for (var offset = 0; offset < 3; offset++) {
        if (offset == 0 && i < 2) continue;
        final period = DateTime(month.year, month.month - offset);
        final statement = CommissionStatement(
          propertyId: store.property.id,
          propertyName: store.property.name,
          month: period,
          rentCollected: commissionRentCollected(store, period),
          rateBasisPoints: 500,
          createdAt: DateTime(period.year, period.month + 1, 1),
        );
        if (i % 3 != 2) {
          statement.receive(
            i % 3 == 0 ? statement.due ~/ 2 : statement.due,
            'DEMO-PT-$i-$offset',
            DateTime(period.year, period.month + 1, 2),
          );
        }
        statements.add(statement.toMap());
      }
    }
    result.restore({
      'verified': <String, bool>{},
      'hidden': <String>[],
      'tickets': <dynamic>[],
      'logs': <dynamic>[],
      'acceptingViewings': true,
      'commissionRates': rates,
      'commissionStatements': statements,
    });
    return result;
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'anchor': now.toIso8601String(),
    'portfolio': portfolio.toMap(),
    'admin': admin.toMap(),
    'locked': _locked.toList(),
  };

  void restore(Map<String, dynamic> map) {
    final anchor = DateTime.parse(map['anchor'] as String);
    final saved = RentalPortfolio.fromMap(
      Map<String, dynamic>.from(map['portfolio'] as Map),
    );
    final savedAdmin = AdminStore(portfolio: saved)
      ..restore(Map<String, dynamic>.from(map['admin'] as Map));
    final locked = List<String>.from(map['locked'] as List);
    // Chỉ thay bộ đang dùng sau khi toàn bộ dữ liệu đã đọc thành công.
    _portfolio?.removeListener(notifyListeners);
    _admin?.removeListener(notifyListeners);
    _portfolio = saved..addListener(notifyListeners);
    _admin = savedAdmin..addListener(notifyListeners);
    now = anchor;
    _locked
      ..clear()
      ..addAll(locked);
    enabled = map['enabled'] == true;
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> cloudDocuments(String prefix) {
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(toMap())) as Map,
    );
    final rental = snapshot.remove('portfolio') as Map;
    final generation = DateTime.now().microsecondsSinceEpoch.toString();
    final houses = (rental['properties'] as List).cast<Map>();
    final result = <String, Map<String, dynamic>>{
      prefix: {
        'schema': 1,
        'generation': generation,
        'demo': snapshot,
        'selectedId': rental['selectedId'],
        'properties': [
          for (final house in houses) (house['property'] as Map)['id'],
        ],
      },
      for (final house in houses)
        '$prefix:${Uri.encodeComponent((house['property'] as Map)['id'] as String)}':
            {'generation': generation, 'store': house},
    };
    if (result.values.any(
      (doc) => utf8.encode(jsonEncode(doc)).length > 800000,
    )) {
      throw ArgumentError(
        'Một nhà trọ có quá nhiều dữ liệu để lưu Firebase. Giảm ảnh đính kèm rồi thử lại.',
      );
    }
    return result;
  }

  void restoreCloudDocuments(
    Map<String, Map<String, dynamic>> records,
    String prefix,
  ) {
    final manifest = records[prefix];
    if (manifest == null || manifest['schema'] != 1) {
      throw ArgumentError('Chưa có bộ dữ liệu mẫu Firebase hợp lệ.');
    }
    final ids = List<String>.from(manifest['properties'] as List);
    if (ids.isEmpty || ids.length > 50 || ids.toSet().length != ids.length) {
      throw ArgumentError('Danh sách nhà trọ Firebase không hợp lệ.');
    }
    final houses = <Map<String, dynamic>>[];
    for (final id in ids) {
      final part = records['$prefix:${Uri.encodeComponent(id)}'];
      if (part == null || part['generation'] != manifest['generation']) {
        throw ArgumentError(
          'Dữ liệu Firebase đang thay đổi. Vui lòng tải lại.',
        );
      }
      final house = Map<String, dynamic>.from(part['store'] as Map);
      if ((house['property'] as Map)['id'] != id) {
        throw ArgumentError('Mã nhà trọ Firebase không khớp.');
      }
      houses.add(house);
    }
    restore({
      ...Map<String, dynamic>.from(manifest['demo'] as Map),
      'portfolio': {'selectedId': manifest['selectedId'], 'properties': houses},
    });
  }
}
