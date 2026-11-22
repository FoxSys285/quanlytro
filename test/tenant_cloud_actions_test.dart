import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/firebase_media_store.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/data/scoped_firestore_repository.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';

import 'support/memory_firestore_queries.dart';

class _Media extends Fake implements FirebaseMediaStore {
  @override
  Future<Map<String, Map<String, dynamic>>> prepareForCloud(
    Map<String, Map<String, dynamic>> snapshot, {
    bool uploadPropertyMedia = true,
    bool uploadPaymentProofs = true,
    String? uploaderUid,
  }) async => snapshot;
}

Map<String, Map<String, dynamic>> _copy(
  Map<String, Map<String, dynamic>> data,
) => (jsonDecode(jsonEncode(data)) as Map).map(
  (k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
);

void main() {
  test('Tenant reads chat, favorites a room, starts a chat and books another owner', () async {
    final source = LandlordDemoStore.demo();
    addTearDown(source.dispose);
    final own = source.toMap();
    for (final key in [
      'leases',
      'members',
      'invoices',
      'payments',
      'incidents',
      'readings',
    ]) {
      own[key] = <dynamic>[];
    }
    final foreign = _copy({'store': own})['store']!;
    foreign['property'] = {...foreign['property'] as Map, 'id': 'foreign'};
    final encoded = encodeCloudDocuments(
      {
        'portfolio': {
          'properties': [own, foreign],
        },
        'conversations': {
          'records': [
            {
              'id': 'existing-chat',
              'propertyId': 'may',
              'tenantId': 'TENANT01',
              'tenantName': 'Người thuê',
              'landlordName': 'Chủ trọ',
              'propertyName': 'Mây House',
              'room': '101',
              'leaseId': null,
              'unread': 0,
              'tenantUnread': 1,
              'messages': [
                {
                  'id': 'existing-message',
                  'text': 'Chào bạn',
                  'time': '09:00',
                  'fromLandlord': true,
                  'index': 0,
                  'createdAt': '2026-11-21T09:00:00+07:00',
                },
              ],
            },
          ],
        },
      },
      owners: {'may': 'owner-a', 'foreign': 'owner-b'},
    );
    final docs = <String, Map<String, Json>>{};
    for (final entry in encoded.entries) {
      final parts = entry.key.split('/');
      docs.putIfAbsent(parts[0], () => {})[parts[1]] = {
        ...entry.value,
        'importBatch': 'operating-demo',
        'isDemo': true,
      };
    }
    docs['user_state'] = {
      'tenant': {
        'accounts': {'contacts': {}, 'notifications': {}},
        'favorites': {'ids': []},
      },
    };
    final db = MemoryFirestore(docs);
    final repository = ScopedFirestoreRentalRepository(
      session: const FirebaseAccountSession(
        uid: 'tenant',
        role: AppRole.tenant,
        tenantId: 'TENANT01',
      ),
      firestore: db,
      mediaStore: _Media(),
    );
    final loaded = await repository.readAll();
    final portfolio = RentalPortfolio.fromMap(loaded['portfolio']!);
    addTearDown(portfolio.dispose);
    loaded['portfolio'] = portfolio.toMap();
    final chats = ConversationStore(rental: portfolio.active);
    addTearDown(chats.dispose);
    chats.restore(loaded['conversations']!);
    loaded['conversations'] = chats.toMap();
    repository.setLocalSnapshotBaseline(loaded);

    // Reading may change only counters, including when seed metadata is present.
    final before = _copy({
      'chat':
          db.documents['rental_records']!['may:conversations:existing-chat']!,
    })['chat']!;
    chats.markRead(chats.conversations.single, landlord: false);
    var edited = _copy(loaded)..['conversations'] = chats.toMap();
    await repository.saveAll(edited);
    expect(db.writes, ['rental_records/may:conversations:existing-chat']);
    final after =
        db.documents['rental_records']!['may:conversations:existing-chat']!;
    expect(after['data'], {...before['data'] as Map, 'tenantUnread': 0});
    expect({...after}..remove('data'), {...before}..remove('data'));

    db.writes.clear();
    edited = _copy(edited)
      ..['favorites'] = {
        'ids': ['foreign:101'],
      };
    await repository.saveAll(edited);
    expect(db.writes, ['user_state/tenant']);
    expect(db.documents['user_state']!['tenant']!['favorites'], {
      'ids': ['foreign:101'],
    });

    db.writes.clear();
    final newChat = chats.forRoom(
      propertyId: 'foreign',
      roomId: 'foreign:101',
      tenantId: 'TENANT01',
      tenantName: 'Người thuê',
      landlordName: 'Chủ mới',
      propertyName: 'Nhà mới',
      roomName: '101',
    );
    chats.send(
      newChat,
      text: 'Em muốn xem phòng',
      time: '10:00',
      fromLandlord: false,
      tenantId: 'TENANT01',
    );
    edited = _copy(edited)..['conversations'] = chats.toMap();
    await repository.saveAll(edited);
    expect(db.writes, hasLength(2));
    expect(
      db.writes.every((p) => p.startsWith('rental_records/foreign:')),
      isTrue,
    );
    for (final path in db.writes) {
      final row = db.documents['rental_records']![path.split('/').last]!;
      expect(row['ownerUid'], 'owner-b');
      expect(row['tenantIds'], ['TENANT01']);
    }

    db.writes.clear();
    final viewings = ViewingStore([], rental: portfolio.active);
    addTearDown(viewings.dispose);
    viewings.createRequest(
      propertyId: 'foreign',
      tenantId: 'TENANT01',
      roomName: '101',
      address: 'Địa chỉ',
      startsAt: DateTime.now().add(const Duration(days: 2)),
      customerName: 'Người thuê',
      phone: '0901234567',
      personalNeeds: 'Xem phòng',
      attendeeCount: 1,
    );
    edited = _copy(edited)..['viewings'] = viewings.toMap();
    await repository.saveAll(edited);
    expect(db.writes, hasLength(1));
    final row =
        db.documents['rental_records']![db.writes.single.split('/').last]!;
    expect(row['kind'], 'viewings');
    expect(row['ownerUid'], 'owner-b');
    expect(row['tenantIds'], ['TENANT01']);
    expect(row['data']['status'], 'pending');
  });
}
