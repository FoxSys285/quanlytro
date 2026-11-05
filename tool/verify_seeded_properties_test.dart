import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_property_listing.dart';

void main() {
  test('All 400 planned demo approvals are accepted by the public catalogue and admin models', () {
    const work = '.local-backups/verified-properties-400';
    final documents = Map<String, dynamic>.from(
      jsonDecode(File('$work/before-decoded.json').readAsStringSync()) as Map,
    );
    final plan = jsonDecode(File('$work/plan.json').readAsStringSync()) as Map;
    for (final change in plan['changes'] as List) {
      final target = documents.putIfAbsent(
        change['path'] as String,
        () => <String, dynamic>{},
      ) as Map;
      for (final entry in (change['fields'] as Map).entries) {
        final parts = (entry.key as String).split('.');
        var cursor = target;
        for (final part in parts.take(parts.length - 1)) {
          cursor = cursor.putIfAbsent(part, () => <String, dynamic>{}) as Map;
        }
        cursor[parts.last] = entry.value;
      }
    }
    final selected = List<String>.from(plan['selected'] as List);
    expect(selected, hasLength(400));
    final stores = <LandlordDemoStore>[];
    for (final path in selected) {
      final document = Map<String, dynamic>.from(documents[path] as Map);
      final listing = TenantPropertyListing.fromMap(document);
      expect(listing.verified, isTrue, reason: path);
      expect(listing.isDemoVerification, isTrue, reason: path);
      final store = LandlordDemoStore.empty();
      store.restore({
        ...store.toMap(),
        ...Map<String, dynamic>.from(document['data'] as Map),
      });
      expect(AdminStore.verificationIssues(store), isEmpty, reason: path);
      stores.add(store);
    }
    final portfolio = RentalPortfolio(stores);
    addTearDown(portfolio.dispose);
    final admin = AdminStore(portfolio: portfolio);
    addTearDown(admin.dispose);
    final state = <String, dynamic>{
      'hidden': <String>[],
      'tickets': [],
      'logs': [],
      'acceptingViewings': true,
      ...Map<String, dynamic>.from(
        documents['management/system']['admin'] as Map,
      ),
    };
    restoreCloudPropertyVerification(
      state,
      selected.map((p) => Map<String, dynamic>.from(documents[p] as Map)),
    );
    admin.restore(state);
    for (final store in stores) {
      expect(
        admin.isVerified(store.property.id),
        isTrue,
        reason: store.property.id,
      );
    }
    final after = File('$work/after-decoded.json');
    if (after.existsSync()) {
      final live = Map<String, dynamic>.from(
        jsonDecode(after.readAsStringSync()) as Map,
      );
      expect(
        live.entries.where(
          (entry) =>
              entry.key.startsWith('rental_properties/') &&
              TenantPropertyListing.fromMap(
                Map<String, dynamic>.from(entry.value as Map),
              ).verified,
        ),
        hasLength(400),
      );
    }
  });
}
