import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanlytro/pages/shared/payments/vietqr_service.dart';

const banks = [
  {
    'bin': '970436',
    'code': 'VCB',
    'shortName': 'Vietcombank',
    'name': 'Ngân hàng TMCP Ngoại Thương Việt Nam',
  },
  {
    'bin': '970422',
    'code': 'MB',
    'shortName': 'MBBank',
    'name': 'Ngân hàng TMCP Quân đội',
  },
  {
    'bin': '970415',
    'code': 'ICB',
    'shortName': 'VietinBank',
    'name': 'Ngân hàng TMCP Công thương Việt Nam',
  },
];

http.Response bankResponse() => http.Response.bytes(
  utf8.encode(jsonEncode({'code': '00', 'data': banks})),
  200,
);

void main() {
  test(
    'Bank names, codes, BINs and Vietnamese legal names resolve exactly',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return bankResponse();
      });
      addTearDown(client.close);
      final service = VietQrService(client: client);
      for (final name in [
        'MB Bank',
        ' mb ',
        '970422',
        'Ngân hàng TMCP Quân đội',
        'ngan hang tmcp quan doi',
      ]) {
        final uri = await service.paymentUri(
          bankName: name,
          accountNumber: '0012 3456',
        );
        expect(uri.host, 'img.vietqr.io');
        expect(uri.path, '/image/970422-00123456-qr_only.svg');
        expect(uri.queryParameters.containsKey('amount'), isFalse);
      }
      expect(
        requests,
        1,
        reason: 'Successful bank lists are cached for one day',
      );
    },
  );

  test(
    'Unknown or ambiguous bank never guesses a transfer destination',
    () async {
      final client = MockClient((_) async => bankResponse());
      addTearDown(client.close);
      final service = VietQrService(client: client);
      for (final name in ['Viet', 'Vietcombank sai', '', 'Vietcombank/MB']) {
        await expectLater(
          service.paymentUri(bankName: name, accountNumber: '0123456789'),
          throwsA(isA<VietQrException>()),
        );
      }
    },
  );

  test(
    'Invalid accounts and amounts are rejected before any network request',
    () async {
      final client = MockClient(
        (_) async => fail('Invalid inputs must not be sent'),
      );
      addTearDown(client.close);
      final service = VietQrService(client: client);
      for (final account in [
        '',
        '../123',
        '123&amount=1',
        '12345678901234567890',
      ]) {
        await expectLater(
          service.paymentUri(bankName: 'VCB', accountNumber: account),
          throwsA(isA<VietQrException>()),
        );
      }
      for (final amount in [0, -1, 10000000000000]) {
        await expectLater(
          service.paymentUri(
            bankName: 'VCB',
            accountNumber: '001234',
            amount: amount,
          ),
          throwsA(isA<VietQrException>()),
        );
      }
    },
  );

  test(
    'Reference is normalized, bounded and encoded; account zeros are retained',
    () async {
      final client = MockClient((_) async => bankResponse());
      addTearDown(client.close);
      final service = VietQrService(client: client);
      final uri = await service.paymentUri(
        bankName: 'VCB',
        accountNumber: '001234',
        reference: 'Thanh toán HD-2026-0302 & phòng A.302',
        amount: 3500000,
      );
      expect(uri.path, '/image/970436-001234-qr_only.svg');
      expect(
        uri.queryParameters['addInfo'],
        'Thanh toan HD 2026 0302 phong A 302',
      );
      expect(uri.queryParameters['amount'], '3500000');
      final long = await service.paymentUri(
        bankName: 'VCB',
        accountNumber: '001234',
        reference: List.filled(20, 'Hop dong ').join(),
      );
      expect(long.queryParameters['addInfo']!.length, lessThanOrEqualTo(50));
    },
  );

  test(
    'Concurrent requests share the bank lookup and failed lookups can retry',
    () async {
      final response = Completer<http.Response>();
      var requests = 0;
      final client = MockClient((_) {
        requests++;
        return response.future;
      });
      addTearDown(client.close);
      final service = VietQrService(client: client);
      final first = service.paymentUri(
        bankName: 'VCB',
        accountNumber: '001234',
      );
      final second = service.paymentUri(
        bankName: 'MB',
        accountNumber: '998877',
      );
      response.complete(bankResponse());
      final result = await Future.wait([first, second]);
      expect(requests, 1);
      expect(result.last.path, contains('970422-998877'));

      var retries = 0;
      final retryClient = MockClient(
        (_) async =>
            ++retries == 1 ? http.Response('unavailable', 503) : bankResponse(),
      );
      addTearDown(retryClient.close);
      final retryService = VietQrService(client: retryClient);
      await expectLater(
        retryService.paymentUri(bankName: 'MB', accountNumber: '998877'),
        throwsA(isA<VietQrException>()),
      );
      expect(
        (await retryService.paymentUri(
          bankName: 'MB',
          accountNumber: '998877',
        )).path,
        contains('970422-998877'),
      );
      expect(retries, 2);
    },
  );

  test('Quick Link SVG is fetched, while HTML responses and network errors fail clearly', () async {
    var valid = true;
    final client = MockClient((request) async {
      if (request.url.host == 'api.vietqr.io') return bankResponse();
      return http.Response(
        valid
            ? '<svg xmlns="http://www.w3.org/2000/svg"/>'
            : '<html>Error</html>',
        200,
      );
    });
    addTearDown(client.close);
    final service = VietQrService(client: client);
    final image = await service.load(bankName: 'VCB', accountNumber: '001234');
    expect(image.svg, startsWith('<svg'));
    valid = false;
    await expectLater(
      service.load(bankName: 'VCB', accountNumber: '001234'),
      throwsA(isA<VietQrException>()),
    );
    final offline = MockClient(
      (_) async => throw http.ClientException('Offline'),
    );
    addTearDown(offline.close);
    await expectLater(
      VietQrService(client: offline)
          .load(bankName: 'VCB', accountNumber: '001234'),
      throwsA(isA<VietQrException>()),
    );
  });
}
