import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_cuoctrochuyen.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/layouts/role_layout.dart';

// flutter test tool/prepare_demo_data_test.dart --no-pub
// Chỉ tạo file xem trước trong workspace; Python mới thực hiện ghi Firestore.
void main() {
  test('Prepare additive demo data from the saved snapshot', () async {
    final directory = Directory('.dart_tool/demo_data');
    final input = jsonDecode(
      await File('${directory.path}/input.json').readAsString(),
    ) as Map<String, dynamic>;
    final portfolio = RentalPortfolio.fromMap(
      Map<String, dynamic>.from(input['portfolio'] as Map),
    );
    addTearDown(portfolio.dispose);
    portfolio.supplementDemoActivity();
    final once = jsonEncode(portfolio.toMap());
    portfolio.supplementDemoActivity();
    expect(
      jsonEncode(portfolio.toMap()),
      once,
      reason: 'Rerun must not duplicate samples',
    );
    input['portfolio'] = portfolio.toMap();

    final conversations = Map<String, dynamic>.from(
      input['conversations'] as Map,
    );
    final records = List<dynamic>.of(conversations['records'] as List);
    for (final record in records) {
      final store = portfolio.byId(record['propertyId'] as String);
      if (store == null) continue;
      final lease = store.leaseById(record['leaseId'] as String? ?? '');
      if (lease != null) record['tenantName'] = lease.tenantName;
    }
    for (final store in portfolio.stores) {
      final property = store.property;
      for (final lease in store.activeLeases.take(2)) {
        if (records.any(
          (r) => r['leaseId'] == lease.id && r['propertyId'] == property.id,
        )) {
          continue;
        }
        records.add(
          LandlordConversation(
            id: 'demo-chat-${lease.id}',
            propertyId: property.id,
            leaseId: lease.id,
            tenantId: lease.tenantId,
            tenantName: lease.tenantName,
            landlordName: property.ownerName,
            propertyName: property.name,
            room: lease.room,
            unread: 1,
            tenantUnread: 1,
            messages: const [
              LandlordMessage(
                text:
                    'Anh chị cho em hỏi lịch vệ sinh khu vực chung tuần này ạ?',
                time: '09:00',
                fromLandlord: false,
              ),
              LandlordMessage(
                text: 'Nhà mình vệ sinh sáng thứ Bảy nhé. Cảm ơn em! (Tin nhắn mẫu)',
                time: '09:05',
                fromLandlord: true,
              ),
            ],
          ).toMap(),
        );
      }
    }
    conversations['records'] = records;
    input['conversations'] = conversations;
    final admin = Map<String, dynamic>.from(input['admin'] as Map);
    final tickets = List<dynamic>.of(admin['tickets'] as List);
    for (final role in [AppRole.tenant, AppRole.landlord]) {
      final id = 'demo-support-${role.name}';
      if (tickets.any((t) => t['id'] == id)) continue;
      tickets.add(
        SupportTicket(
          id: id,
          role: role,
          title: role == AppRole.tenant
              ? 'Hướng dẫn xem hóa đơn'
              : 'Hỗ trợ đăng ảnh phòng',
          content: 'Nhờ quản trị viên hướng dẫn thao tác trong ứng dụng. (Yêu cầu mẫu)',
          createdAt: DateTime.now(),
          reply: role == AppRole.tenant
              ? 'Vào mục Hóa đơn để xem chi tiết từng khoản thu nhé.'
              : '',
          closed: role == AppRole.tenant,
        ).toMap(),
      );
    }
    admin['tickets'] = tickets;
    final logs = List<dynamic>.of(admin['logs'] as List);
    if (!logs.any(
      (l) => l['action'] == 'Bổ sung dữ liệu minh họa cho ba vai trò',
    )) {
      logs.insert(0, {
        'action': 'Bổ sung dữ liệu minh họa cho ba vai trò',
        'at': DateTime.now().toIso8601String(),
        'actor': 'Hệ thống',
      });
    }
    admin['logs'] = logs;
    input['admin'] = admin;
    for (final store in portfolio.stores) {
      expect(store.payments, isNotEmpty);
      expect(store.incidents, isNotEmpty);
      for (final payment in store.payments) {
        expect(store.invoices.any((i) => i.id == payment.invoiceId), isTrue);
      }
    }
    await File('${directory.path}/prepared.json')
        .writeAsString(jsonEncode(input));
  });
}
