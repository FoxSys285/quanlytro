import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/ai/ai_chat_controller.dart';
import 'package:quanlytro/pages/shared/ai/ai_chat_page.dart';
import 'package:quanlytro/pages/shared/ai/ai_chat_service.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';

http.Response _response(String answer) => http.Response.bytes(
  utf8.encode(jsonEncode({'answer': answer})),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

LandlordDemoStore _store() {
  final store = LandlordDemoStore.demo();
  for (final lease in store.leases) {
    lease.startDate = DateTime(2000);
    lease.endDate = DateTime(2100);
  }
  return store;
}

void main() {
  test(
    'role context excludes sensitive information and other tenants records',
    () {
      final store = _store();
      addTearDown(store.dispose);
      final context = buildAiContext(AppRole.tenant, store);
      final data = jsonDecode(context) as Map<String, dynamic>;
      expect(data['choOHienTai']['phong'], 'A.302');
      expect(data['choOHienTai']['tienThueThang'], 3500000);
      expect(context, isNot(contains('Lê Văn Khoa')));
      expect(context, isNot(contains('0987 654 321')));
      expect(context, isNot(contains('000000000002')));
      expect(context, isNot(contains('0123456789')));
      final lease = store.currentLeaseForTenant(TenantSession.tenantId)!;
      store.endLease(lease);
      expect(
        jsonDecode(buildAiContext(AppRole.tenant, store))['choOHienTai'],
        isNull,
      );
    },
  );

  test('HTTP sends bounded history as JSON and decodes Vietnamese', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/chat');
      expect(request.headers, isNot(contains('x-api-key')));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = body['messages'] as List;
      expect(body['role'], 'landlord');
      expect(messages.length, lessThanOrEqualTo(19));
      expect(messages.first['role'], 'user');
      expect(messages.last['content'], 'Câu hỏi mới');
      expect(
        messages.every((dynamic item) => item['role'] != 'system'),
        isTrue,
      );
      return _response('Mở Loại phòng → Thêm ảnh.');
    });
    addTearDown(client.close);
    final result = await AiChatService(client: client).reply(
      role: AppRole.landlord,
      context: '',
      messages: [
        for (var i = 0; i < 30; i++)
          AiMessage(
            role: i.isEven ? 'user' : 'assistant',
            content: 'Lịch sử $i',
          ),
        const AiMessage(role: 'user', content: 'Câu hỏi mới'),
      ],
    );
    expect(result.text, 'Mở Loại phòng → Thêm ảnh.');
  });

  test('retry keeps failed question and prevents concurrent sends', () async {
    final store = _store();
    addTearDown(store.dispose);
    var calls = 0;
    final pending = Completer<http.Response>();
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response.bytes(
          utf8.encode(jsonEncode({'error': 'AI đang bận'})),
          429,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      expect((jsonDecode(request.body)['messages'] as List).length, 1);
      return pending.future;
    });
    addTearDown(client.close);
    final chat = AiChatController(
      role: AppRole.tenant,
      store: store,
      service: AiChatService(client: client),
    );
    addTearDown(chat.dispose);
    await chat.send('Thêm thành viên thế nào?');
    expect(chat.error, 'AI đang bận');
    expect(chat.messages.length, 1);
    final retry = chat.retry();
    await Future<void>.delayed(Duration.zero);
    await chat.send('Câu hỏi khác');
    expect(chat.isLoading, isTrue);
    expect(calls, 2);
    pending.complete(_response('Mở Chỗ ở của tôi.'));
    await retry;
    expect(chat.messages.length, 2);
    expect(chat.error, isNull);
    chat.clear();
    expect(chat.messages, isEmpty);
    expect(
      AiChatController.forRole(AppRole.tenant),
      isNot(same(AiChatController.forRole(AppRole.landlord))),
    );
  });

  test('network and malformed responses become readable errors', () async {
    for (final client in [
      MockClient((_) async => throw http.ClientException('network')),
      MockClient((_) async => http.Response('<html>error</html>', 502)),
      MockClient((_) async => http.Response('{}', 200)),
    ]) {
      await expectLater(
        AiChatService(client: client).reply(
          role: AppRole.tenant,
          messages: [const AiMessage(role: 'user', content: 'Xin chào')],
          context: '',
        ),
        throwsA(isA<AiChatException>()),
      );
      client.close();
    }
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('chat send, follow-up, retry and clear at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = _store();
      addTearDown(store.dispose);
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 2) {
          return http.Response.bytes(
            utf8.encode(jsonEncode({'error': 'AI đang bận'})),
            429,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return _response('Bạn vào **Chỗ ở của tôi**, chọn Người ở cùng.');
      });
      addTearDown(client.close);
      final chat = AiChatController(
        role: AppRole.tenant,
        store: store,
        service: AiChatService(client: client),
      );
      addTearDown(chat.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiChatPage(role: AppRole.tenant, controller: chat),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Làm sao thêm người ở cùng?'));
      await tester.tap(find.text('Làm sao thêm người ở cùng?'));
      await tester.pumpAndSettle();
      expect(chat.messages.length, 2);
      expect(find.textContaining('Bạn vào'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Cần thông tin gì?');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi câu hỏi'));
      await tester.pumpAndSettle();
      expect(find.text('AI đang bận'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(chat.messages.length, 4);
      expect(chat.error, isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
      await tester.pumpAndSettle();
      expect(find.text('Mình có thể giúp gì cho bạn?'), findsOneWidget);
      expect(chat.messages, isEmpty);
    });
  }

  for (final role in [AppRole.tenant, AppRole.landlord]) {
    testWidgets('AI shortcut opens chat for ${role.name}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: role == AppRole.tenant
              ? const TenantLayout()
              : const LandlordLayout(),
        ),
      );
      await tester.tap(find.byTooltip('Mở trợ lý AI'));
      await tester.pumpAndSettle();
      final page = tester.widget<AiChatPage>(find.byType(AiChatPage));
      expect(page.role, role);
      expect(tester.takeException(), isNull);
    });
  }
}
