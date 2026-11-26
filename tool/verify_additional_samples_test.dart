import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_commission.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_cuoctrochuyen.dart';
import 'package:quanlytro/pages/landlord/finance/landlord_finance_models.dart';
import 'package:quanlytro/pages/landlord/incidents/models/landlord_suco.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/meter_readings/models/landlord_chisodiennuoc.dart';
import 'package:quanlytro/pages/landlord/staff/landlord_staff_store.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';
import 'package:quanlytro/pages/shared/rental/lease_member.dart';
import 'package:quanlytro/pages/shared/viewings/models/room_viewing.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_property_listing.dart';

void main() {
  test('Additional sample payload and enrichment validate cleanly across all models', () async {
    final dir = Directory('.dart_tool')..createSync(recursive: true);
    final file = File('${dir.path}/additional_samples_preview.json');
    final gen = await Process.run('python', [
      '-c',
      '''
import json, datetime as dt, sys
sys.path.insert(0, 'tool')
import seed_additional_samples as s
now = dt.datetime(2026, 11, 26, 17, 30, tzinfo=dt.timezone(dt.timedelta(hours=7)))
additions, verified, proofs = s.build_additions({}, now)
enrichment = s.build_enrichment({}, {}, now)
open('.dart_tool/additional_samples_preview.json', 'w', encoding='utf-8').write(json.dumps({
    'additions': additions,
    'verified': verified,
    'proofs': proofs,
    'enrichment': enrichment,
}, ensure_ascii=False))
''',
    ]);
    expect(gen.exitCode, 0, reason: '${gen.stderr}');
    final bundle = Map<String, dynamic>.from(
      jsonDecode(file.readAsStringSync()) as Map,
    );
    final payload = Map<String, dynamic>.from(bundle['additions'] as Map);
    final enrichment = Map<String, dynamic>.from(bundle['enrichment'] as Map);

    final propertyDocs = <Map<String, dynamic>>[];
    final verificationByProperty = <String, Map<String, dynamic>>{};
    final reviewByProperty = <String, Map<String, dynamic>>{};
    final settingsByProperty = <String, Map<String, dynamic>>{};
    final staffByOwner = <String, Map<String, dynamic>>{};
    final stores = <LandlordDemoStore>[];

    var leaseCount = 0;
    var draftLeaseCount = 0;
    var terminatedLeaseCount = 0;
    var renewalLeaseCount = 0;
    var terminationReqCount = 0;
    var leaveMemberCount = 0;
    var announcementDocCount = 0;
    var paymentAccountCount = 0;

    for (final entry in payload.entries) {
      final raw = Map<String, dynamic>.from(entry.value as Map);
      if (entry.key.startsWith('rental_properties/')) {
        propertyDocs.add(raw);
        TenantPropertyListing.fromMap(raw);
      } else if (entry.key.startsWith('public_rooms/')) {
        catalogListingFromMap(entry.key.split('/')[1], raw);
      } else if (entry.key.startsWith('support_tickets/')) {
        SupportTicket.fromMap(Map<String, dynamic>.from(raw['data'] as Map));
      } else if (entry.key.startsWith('management/report-demo-owner-')) {
        staffByOwner[entry.key] = Map<String, dynamic>.from(raw['staff'] as Map);
      } else if (entry.key.startsWith('rental_records/')) {
        final data = Map<String, dynamic>.from(raw['data'] as Map);
        switch (raw['kind']) {
          case 'leases':
            final lease = LandlordLease.fromMap(data);
            leaseCount++;
            if (lease.status == LandlordLeaseStatus.draft) draftLeaseCount++;
            if (lease.status == LandlordLeaseStatus.terminated) {
              terminatedLeaseCount++;
            }
            if (lease.renewalStatus == 'pending') renewalLeaseCount++;
            if (lease.terminationRequestStatus == 'pending') {
              terminationReqCount++;
            }
          case 'invoices':
            LandlordInvoice.fromMap(data);
          case 'payments':
            LandlordPayment.fromMap(data);
          case 'members':
            final m = LeaseMember.fromMap(data);
            if (m.leaveRequestedAt != null) leaveMemberCount++;
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
          case 'settings':
            settingsByProperty[raw['propertyId'] as String] = data;
            final accounts = data['paymentAccounts'] as List? ?? const [];
            for (final acc in accounts) {
              LandlordPaymentAccount.fromMap(Map<String, dynamic>.from(acc as Map));
              paymentAccountCount++;
            }
          case 'announcements':
          case 'tenantAnnouncements':
            announcementDocCount++;
            final ann = AnnouncementStore()..restore(data);
            expect(ann.sent.length, greaterThanOrEqualTo(3));
            ann.dispose();
          case 'verification':
            verificationByProperty[raw['propertyId'] as String] = data;
          case 'verificationReview':
            reviewByProperty[raw['propertyId'] as String] = data;
        }
      }
    }

    expect(leaseCount, greaterThanOrEqualTo(30));
    expect(draftLeaseCount, greaterThanOrEqualTo(10));
    expect(terminatedLeaseCount, greaterThanOrEqualTo(10));
    expect(renewalLeaseCount, greaterThanOrEqualTo(1));
    expect(terminationReqCount, greaterThanOrEqualTo(1));
    expect(leaveMemberCount, greaterThanOrEqualTo(6));
    expect(announcementDocCount, equals(20));
    expect(paymentAccountCount, equals(20));
    expect(staffByOwner.keys.length, equals(3));

    for (final staffMap in staffByOwner.values) {
      final staffStore = LandlordStaffStore.instance..restore(staffMap);
      expect(staffStore.staff.length, equals(3));
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
      final sdoc = settingsByProperty[pid];
      if (sdoc != null) {
        data['counters'] = sdoc['counters'];
        data['paymentAccounts'] = sdoc['paymentAccounts'];
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

    final adminUpdates = Map<String, dynamic>.from(enrichment['admin_updates'] as Map);
    final roleTickets = (enrichment['role_tickets'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(roleTickets.length, equals(6));
    for (final ticket in roleTickets) {
      SupportTicket.fromMap(ticket);
    }

    final adminMap = <String, dynamic>{
      'logs': adminUpdates['logs'],
      'commissionRates': adminUpdates['commissionRates'],
      'commissionStatements': adminUpdates['commissionStatements'],
    };
    restoreCloudPropertyVerification(adminMap, propertyDocs);
    restoreCloudPropertyReviews(adminMap, [
      for (final r in reviewByProperty.entries)
        {'kind': 'verificationReview', 'propertyId': r.key, 'archived': false, 'data': r.value},
    ]);
    final portfolio = RentalPortfolio(stores);
    addTearDown(portfolio.dispose);
    await LocalAuth.instance.initialize();
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
    addTearDown(LocalAuth.instance.signOut);
    final admin = AdminStore(portfolio: portfolio)..restore(adminMap);
    addTearDown(admin.dispose);

    expect(admin.logs.length, greaterThanOrEqualTo(15));
    expect(admin.statements.length, equals(3));
    for (final st in admin.statements) {
      CommissionStatement.fromMap(st.toMap());
    }
    expect(admin.verificationResubmitted('op26-02-10'), isTrue);
    expect(admin.pendingReviewNote('op26-02-03'), isNotEmpty);

    for (final pid in ['op26-02-01', 'op26-02-04', 'op26-02-07', 'op26-02-08']) {
      expect(admin.isVerified(pid), isTrue, reason: '$pid should be verified');
    }
    for (final pid in ['op26-02-02', 'op26-02-03', 'op26-02-05', 'op26-02-06', 'op26-02-09', 'op26-02-10']) {
      expect(admin.isVerified(pid), isFalse, reason: '$pid should be unverified');
    }
    for (final pid in ['op26-02-02', 'op26-02-05', 'op26-02-09', 'op26-02-10']) {
      admin.verify(pid, true);
      expect(admin.isVerified(pid), isTrue, reason: '$pid must approve cleanly');
    }
  });
}
