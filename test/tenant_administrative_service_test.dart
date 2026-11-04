import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanlytro/pages/tenant/discovery/services/tenant_administrative_service.dart';

http.Response _json(Object? value) =>
    http.Response.bytes(utf8.encode(jsonEncode(value)), 200);

void main() {
  test('Loads UTF-8 provinces and only the selected province wards; caches results', () async {
    final requests = <Uri>[];
    final service = TenantAdministrativeService(
      client: MockClient((request) async {
        requests.add(request.url);
        if (request.url.path == '/api/v2/p/') {
          return _json([
            {'code': 79, 'name': 'Thành phố Hồ Chí Minh'},
            {'code': 1, 'name': 'Thành phố Hà Nội'},
          ]);
        }
        expect(request.url.path, '/api/v2/p/79');
        expect(request.url.queryParameters, {'depth': '2'});
        return _json({
          'code': 79,
          'wards': [
            {'code': 26734, 'name': 'Phường Thủ Đức'},
          ],
        });
      }),
    );
    expect((await service.provinces()).first.name, 'Thành phố Hồ Chí Minh');
    expect((await service.wards(79)).single.name, 'Phường Thủ Đức');
    await service.provinces();
    await service.wards(79);
    expect(requests, hasLength(2));
    expect(requests.every((uri) => uri.scheme == 'https'), isTrue);
  });

  test(
    'Concurrent calls share requests; failed requests can be retried',
    () async {
      var calls = 0;
      final response = Completer<http.Response>();
      final service = TenantAdministrativeService(
        client: MockClient((_) {
          calls++;
          return response.future;
        }),
      );
      final first = service.provinces();
      final second = service.provinces();
      response.complete(
        _json([
          {'code': 1, 'name': 'Thành phố Hà Nội'},
        ]),
      );
      expect(await first, same(await second));
      expect(calls, 1);

      var retries = 0;
      final retryService = TenantAdministrativeService(
        client: MockClient((_) async {
          return ++retries == 1
              ? http.Response('Unavailable', 503)
              : _json([
                  {'code': 1, 'name': 'Thành phố Hà Nội'},
                ]);
        }),
      );
      await expectLater(
        retryService.provinces(),
        throwsA(isA<TenantAdministrativeFailure>()),
      );
      expect((await retryService.provinces()).single.code, 1);
      expect(retries, 2);
    },
  );

  test(
    'Rejects malformed payloads and keeps ward caches separate by province',
    () async {
      for (final payload in [
        null,
        {},
        [],
        [
          {'code': '1', 'name': 'Hà Nội'},
        ],
      ]) {
        final service = TenantAdministrativeService(
          client: MockClient((_) async => _json(payload)),
        );
        await expectLater(
          service.provinces(),
          throwsA(isA<TenantAdministrativeFailure>()),
        );
      }
      final codes = <String>[];
      final service = TenantAdministrativeService(
        client: MockClient((request) async {
          final code = request.url.pathSegments.last;
          codes.add(code);
          return _json({
            'wards': [
              {'code': int.parse(code), 'name': 'Phường $code'},
            ],
          });
        }),
      );
      expect((await service.wards(79)).single.name, 'Phường 79');
      expect((await service.wards(1)).single.name, 'Phường 1');
      expect((await service.wards(79)).single.name, 'Phường 79');
      expect(codes, ['79', '1']);
    },
  );
}
