import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';

void main() {
  test(
    'Operating seed round-trips through the app models with valid links',
    () {
      final input = File('.local-backups/operating-demo/import.json');
      final map = jsonDecode(input.readAsStringSync()) as Map<String, dynamic>;
      final snapshot = map['snapshot'] as Map<String, dynamic>;
      final portfolio = RentalPortfolio.fromMap(
        Map<String, dynamic>.from(snapshot['portfolio'] as Map),
      );
      addTearDown(portfolio.dispose);
      expect(portfolio.stores, hasLength(680));
      final tenantIds = <String>{};
      for (final store in portfolio.stores) {
        final rooms = store.catalog.map((r) => r.code).toSet();
        for (final lease in store.leases) {
          expect(rooms, contains(lease.room));
          expect(tenantIds.add(lease.tenantId), isTrue);
          expect(lease.status.name == 'terminated' || lease.isCurrent, isTrue);
          expect(store.membersForLease(lease.id), isNotEmpty);
          if (lease.isCurrent) {
            expect(
              store.membersForLease(lease.id).length,
              lessThanOrEqualTo(store.roomByCode(lease.room)!.capacity),
            );
          }
        }
        for (final invoice in store.invoices) {
          expect(store.leaseById(invoice.leaseId), isNotNull);
          expect(invoice.paidAmount, lessThanOrEqualTo(invoice.total));
        }
      }
      final chats = ConversationStore(rental: portfolio.stores.first);
      chats.restore(
        Map<String, dynamic>.from(snapshot['conversations'] as Map),
      );
      addTearDown(chats.dispose);
      final viewings = ViewingStore([], rental: portfolio.stores.first);
      viewings.restore(Map<String, dynamic>.from(snapshot['viewings'] as Map));
      addTearDown(viewings.dispose);
      snapshot['portfolio'] = portfolio.toMap();
      File('.local-backups/operating-demo/normalized.json')
          .writeAsStringSync(jsonEncode(map));
    },
  );
}
