import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/incidents/models/landlord_suco.dart';
import 'package:quanlytro/pages/landlord/meter_readings/models/landlord_chisodiennuoc.dart';
import 'package:quanlytro/pages/shared/rental/lease_member.dart';
import 'package:quanlytro/pages/shared/viewings/models/room_viewing.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_cuoctrochuyen.dart';
import 'package:quanlytro/pages/landlord/announcements/models/landlord_announcement.dart';

void main() {
  test('Firebase samples load through the actual app models', () async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final directory = Directory('.dart_tool/sample_schema_check');
    directory.createSync(recursive: true);
    final source = <String, dynamic>{
      'rental_properties/may': {'ownerUid': 'owner', 'data': rental.toMap()},
      for (final lease in rental.leases)
        'rental_records/${lease.id}': {
          'propertyId': 'may',
          'ownerUid': 'owner',
          'kind': 'leases',
          'tenantIds': [lease.tenantId],
          'data': lease.toMap(),
        },
    };
    File('${directory.path}/input.json').writeAsStringSync(jsonEncode(source));
    final result = await Process.run('python', [
      '-c',
      '''
import json
from pathlib import Path
from datetime import datetime
from tool.supplement_firebase_samples import plan
folder=Path('.dart_tool/sample_schema_check')
current=json.loads((folder/'input.json').read_text(encoding='utf-8'))
output=plan(current,datetime(2026,11,5),'admin')
(folder/'output.json').write_text(json.dumps(output,ensure_ascii=False),encoding='utf-8')
''',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final output = jsonDecode(
      File('${directory.path}/output.json').readAsStringSync(),
    ) as Map;
    final kinds = <String>{};
    for (final raw in output.values) {
      final data = Map<String, dynamic>.from(raw['data'] as Map);
      switch (raw['kind']) {
        case 'leases':
          LandlordLease.fromMap(data);
        case 'invoices':
          LandlordInvoice.fromMap(data);
        case 'payments':
          LandlordPayment.fromMap(data);
        case 'members':
          LeaseMember.fromMap(data);
        case 'incidents':
          LandlordIncident.fromMap(data);
        case 'readings':
          LandlordMeterReading.fromMap(data);
        case 'viewings':
          RoomViewing.fromMap(data);
        case 'conversations':
          LandlordConversation.fromMap(data);
        case 'messages':
          LandlordMessage.fromMap(data);
        case 'announcements' || 'tenantAnnouncements':
          for (final item in data['sent'] as List) {
            LandlordAnnouncement.fromMap(
              Map<String, dynamic>.from(item as Map),
            );
          }
      }
      if (raw['kind'] is String) kinds.add(raw['kind'] as String);
    }
    expect(
      kinds,
      containsAll([
        'leases',
        'invoices',
        'payments',
        'members',
        'incidents',
        'readings',
        'viewings',
        'conversations',
        'messages',
        'announcements',
        'tenantAnnouncements',
      ]),
    );
  });
}
