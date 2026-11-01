import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';

void main() {
  test('Export independent Firestore room and rental documents', () async {
    const base = '.dart_tool/demo_data';
    final input = Map<String, Map<String, dynamic>>.from(
      (jsonDecode(await File('$base/prepared.json').readAsString()) as Map).map(
        (k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
      ),
    );
    final configFile = File('$base/provisioning.json');
    final config = configFile.existsSync()
        ? jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>
        : <String, dynamic>{};
    final owner = config['landlordUid'] as String? ?? 'legacy-demo';
    final output = encodeCloudDocuments(
      input,
      owners: {
        for (final store in input['portfolio']!['properties'] as List)
          (store['property'] as Map)['id'] as String: owner,
      },
    );
    if (config.isEmpty) {
      output.removeWhere((path, _) => !path.startsWith('public_rooms/'));
    } else {
      for (final role in ['landlord', 'tenant', 'admin']) {
        final uid = config['${role}Uid'] as String;
        output['users/$uid'] = {
          'role': role,
          'disabled': false,
          if (role == 'tenant') 'tenantId': 'tenant-demo',
        };
      }
      output['management/system'] = {'admin': {...?input['admin'], 'tickets': <dynamic>[]}};
      output['public_settings/viewings'] = {'acceptingViewings': input['admin']?['acceptingViewings'] ?? true};
      for (final ticket in input['admin']?['tickets'] as List? ?? []) {
        output['support_tickets/${ticket['id']}'] = {
          'accountUid': config['${ticket['role']}Uid'], 'data': ticket,
        };
      }
      output['management/$owner'] = {'staff': input['staff']};
    }
    expect(output.keys.any((key) => key.startsWith('public_rooms/')), isTrue);
    await File('$base/cloud_documents.json').writeAsString(jsonEncode(output));
  });
}
