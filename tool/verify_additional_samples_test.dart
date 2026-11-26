import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_cuoctrochuyen.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/incidents/models/landlord_suco.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/meter_readings/models/landlord_chisodiennuoc.dart';
import 'package:quanlytro/pages/shared/rental/lease_member.dart';
import 'package:quanlytro/pages/shared/viewings/models/room_viewing.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_property_listing.dart';

void main() {
  test('Additional sample payload validates cleanly across all app models', () async {
    final dir = Directory('.dart_tool')..createSync(recursive: true);
    final file = File('${dir.path}/additional_samples_preview.json');
    final gen = await Process.run('python', [
      '-c',
      '''
import json, datetime as dt, sys
sys.path.insert(0, 'tool')
import seed_additional_samples as s
additions, _, _ = s.build_additions({}, dt.datetime(2026, 11, 26, 17, 30, tzinfo=dt.timezone(dt.timedelta(hours=7))))
open('.dart_tool/additional_samples_preview.json', 'w', encoding='utf-8').write(json.dumps(additions, ensure_ascii=False))
''',
    ]);
    expect(gen.exitCode, 0, reason: '${gen.stderr}');
    final payload = Map<String, dynamic>.from(
      jsonDecode(file.readAsStringSync()) as Map,
    );

    final propertyDocs = <Map<String, dynamic>>[];
    final verificationByProperty = <String, Map<String, dynamic>>{};
    final stores = <LandlordDemoStore>[];

    for (final entry in payload.entries) {
      final raw = Map<String, dynamic>.from(entry.value as Map);
      if (entry.key.startsWith('rental_properties/')) {
        propertyDocs.add(raw);
        TenantPropertyListing.fromMap(raw);
      } else if (entry.key.startsWith('public_rooms/')) {
        catalogListingFromMap(entry.key.split('/')[1], raw);
      } else if (entry.key.startsWith('support_tickets/')) {
        SupportTicket.fromMap(Map<String, dynamic>.from(raw['data'] as Map));
      } else if (entry.key.startsWith('rental_records/')) {
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
          case 'verification':
            verificationByProperty[raw['propertyId'] as String] = data;
        }
      }
    }

    for (final doc in propertyDocs) {
      final data = Map<String, dynamic>.from(doc['data'] as Map);
      final prop = Map<String, dynamic>.from(data['property'] as Map);
      final pid = prop['id'] as String;
      final vdoc = verificationByProperty[pid];
      if (vdoc != null) {
        prop['verificationSubmittedAt'] = vdoc['submittedAt'];
        prop['verificationIsOwner'] = vdoc['isOwner'];
        prop['verificationDocuments'] = vdoc['documents'];
        data['property'] = prop;
      }
      final store = LandlordDemoStore.empty();
      store.restore({...store.toMap(), ...data});
      stores.add(store);
      if (pid != 'op26-02-06') {
        expect(
          AdminStore.verificationIssues(store),
          isEmpty,
          reason: '$pid should have zero verificationIssues',
        );
      }
    }

    final adminMap = <String, dynamic>{};
    restoreCloudPropertyVerification(adminMap, propertyDocs);
    final portfolio = RentalPortfolio(stores);
    addTearDown(portfolio.dispose);
    await LocalAuth.instance.initialize();
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
    addTearDown(LocalAuth.instance.signOut);
    final admin = AdminStore(portfolio: portfolio)..restore(adminMap);
    addTearDown(admin.dispose);

    for (final pid in ['op26-02-01', 'op26-02-04', 'op26-02-07', 'op26-02-08']) {
      expect(admin.isVerified(pid), isTrue, reason: '$pid should be verified');
    }
    for (final pid in ['op26-02-02', 'op26-02-03', 'op26-02-05', 'op26-02-06', 'op26-02-09']) {
      expect(admin.isVerified(pid), isFalse, reason: '$pid should be unverified');
    }
    for (final pid in ['op26-02-02', 'op26-02-05', 'op26-02-09']) {
      admin.verify(pid, true);
      expect(admin.isVerified(pid), isTrue, reason: '$pid must approve cleanly');
    }
  });
}
