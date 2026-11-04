import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/conversations/models/landlord_cuoctrochuyen.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';

void main() {
  test(
    'Open chat source receives refresh in place and keeps history on send',
    () {
      final portfolio = RentalPortfolio.seeded();
      addTearDown(portfolio.dispose);
      final source = LandlordConversation(
        id: 'open-chat',
        propertyId: 'may',
        tenantId: 'tenant-demo',
        tenantName: 'Tenant',
        room: 'A.302',
        messages: [
          const LandlordMessage(
            text: 'Before refresh',
            time: '09:00',
            fromLandlord: true,
          ),
        ],
      );
      final store = ConversationStore(
        records: [source],
        rental: portfolio.byId('may'),
      );
      addTearDown(store.dispose);
      final messagesReference = source.messages;
      final remote = {
        ...source.toMap(),
        'tenantName': 'Updated tenant',
        'room': 'A.303',
        'unread': 3,
        'tenantUnread': 2,
        'messages': [
          ...source.messages.map((message) => message.toMap()),
          const LandlordMessage(
            id: 'remote-message',
            index: 1,
            text: 'Remote update',
            time: '09:01',
            fromLandlord: false,
          ).toMap(),
        ],
      };
      store.restore({
        'records': [remote],
      });
      expect(store.conversations.single, same(source));
      expect(source.messages, same(messagesReference));
      expect(source.messages.last.id, 'remote-message');
      expect(source.tenantName, 'Updated tenant');
      expect(source.room, 'A.303');
      expect(source.unread, 3);
      expect(source.tenantUnread, 2);
      store.send(
        source,
        text: 'After refresh',
        time: '09:02',
        fromLandlord: true,
      );
      expect(
        store.conversations.single.messages.map((message) => message.text),
        ['Before refresh', 'Remote update', 'After refresh'],
      );
      expect(source.messages.last.index, 2);
      store.restore({
        'records': [
          {...remote, 'tenantId': 'different-tenant'},
        ],
      });
      expect(store.conversations.single, isNot(same(source)));
      expect(source.tenantId, 'tenant-demo');
    },
  );

  test('Concurrent chat appends use distinct stable documents and round-trip metadata', () {
    final portfolio = RentalPortfolio.seeded();
    addTearDown(portfolio.dispose);
    final rental = portfolio.byId('may')!;
    LandlordConversation conversation() => LandlordConversation(
      id: 'parallel-chat',
      propertyId: 'may',
      tenantId: 'tenant-demo',
      tenantName: 'Tenant',
      room: 'A.302',
      messages: [
        const LandlordMessage(
          text: 'Legacy',
          time: '09:00',
          fromLandlord: true,
        ),
      ],
    );
    final tenant = conversation();
    final owner = conversation();
    final tenantStore = ConversationStore(records: [tenant], rental: rental);
    final ownerStore = ConversationStore(records: [owner], rental: rental);
    addTearDown(tenantStore.dispose);
    addTearDown(ownerStore.dispose);
    tenantStore.send(
      tenant,
      text: 'Tenant reply',
      time: '09:01',
      fromLandlord: false,
    );
    ownerStore.send(
      owner,
      text: 'Owner reply',
      time: '09:01',
      fromLandlord: true,
    );
    Map<String, Map<String, dynamic>> encode(LandlordConversation chat) =>
        encodeCloudDocuments(
          {
            'portfolio': {
              'properties': [rental.toMap()],
            },
            'conversations': {
              'records': [chat.toMap()],
            },
          },
          owners: {'may': 'owner'},
        );
    final tenantDocs = encode(tenant);
    final ownerDocs = encode(owner);
    Map<String, Map<String, dynamic>> messages(
      Map<String, Map<String, dynamic>> docs,
    ) => {
      for (final entry in docs.entries)
        if (entry.value['kind'] == 'messages') entry.key: entry.value,
    };
    final merged = {...messages(tenantDocs), ...messages(ownerDocs)};
    expect(merged, hasLength(3));
    expect(merged, contains('rental_records/may:messages:parallel-chat%3A0'));
    expect(tenant.messages.last.id, isNot(owner.messages.last.id));
    expect(tenant.messages.last.createdAt, isNotNull);
    final decoded = decodeCloudMessages(
      merged.values.map((row) => Map<String, dynamic>.from(row['data'] as Map)),
      'may:conversations:parallel-chat',
    );
    expect(decoded.first['text'], 'Legacy');
    final restored = LandlordConversation.fromMap({
      ...tenant.toMap(),
      'messages': decoded,
    });
    expect(
      restored.messages
          .map((message) => message.id)
          .whereType<String>()
          .toSet(),
      {tenant.messages.last.id, owner.messages.last.id},
    );
    expect(messages(encode(restored)), merged);
  });

  test('Independent fields merge; concurrent financial edits fail', () {
    final before = <String, dynamic>{
      'data': {'paidAmount': 0, 'tenantUnread': 2},
    };
    final local = <String, dynamic>{
      'data': {'paidAmount': 0, 'tenantUnread': 0},
    };
    final live = <String, dynamic>{
      'data': {'paidAmount': 500, 'tenantUnread': 2},
    };
    expect(mergeCloudDocument(before, local, live), {
      'data': {'paidAmount': 500, 'tenantUnread': 0},
    });
    expect(
      () => mergeCloudDocument(before, {
        'data': {'paidAmount': 200, 'tenantUnread': 2},
      }, live),
      throwsStateError,
    );
    // Two approvals may calculate the same invoice total from a stale balance.
    expect(
      () => mergeCloudDocument(before, live, live, atomic: true),
      throwsStateError,
    );
    expect(
      () => mergeCloudDocument(
        null,
        {'id': 'same', 'value': 1},
        {'id': 'same', 'value': 2},
      ),
      throwsStateError,
    );
  });

  test('Normalized client values never delete untouched server fields', () {
    expect(
      mergeCloudDocument(
        {
          'data': {'reads': <String>[]},
        },
        {
          'data': {
            'reads': ['announcement-1'],
          },
        },
        {
          'data': {'serverOnly': true},
        },
        serverBefore: {
          'data': {'serverOnly': true},
        },
      ),
      {
        'data': {
          'reads': ['announcement-1'],
          'serverOnly': true,
        },
      },
    );
  });

  test(
    'Landlord sends a new notice without erasing a concurrent tenant read',
    () {
      final before = <String, dynamic>{
        'data': {
          'sent': ['notice-1'],
          'readByTenant': {'tenant-a': <String>[]},
        },
      };
      expect(
        mergeCloudDocument(
          before,
          {
            'data': {
              'sent': ['notice-1', 'notice-2'],
              'readByTenant': {'tenant-a': <String>[]},
            },
          },
          {
            'data': {
              'sent': ['notice-1'],
              'readByTenant': {
                'tenant-a': ['notice-1'],
              },
            },
          },
        ),
        {
          'data': {
            'sent': ['notice-1', 'notice-2'],
            'readByTenant': {
              'tenant-a': ['notice-1'],
            },
          },
        },
      );
    },
  );

  test('Announcement read state is keyed by tenant and stays isolated', () {
    final portfolio = RentalPortfolio.seeded();
    addTearDown(portfolio.dispose);
    final store = portfolio.byId('may')!;
    final announcements = AnnouncementStore(rental: store);
    addTearDown(announcements.dispose);
    final item = announcements.forTenant('tenant-demo').first;
    announcements.markTenantRead(item.id, 'tenant-demo');
    final docs = encodeCloudDocuments(
      {
        'portfolio': portfolio.toMap(),
        'announcements:may': announcements.toMap(),
      },
      owners: {for (final s in portfolio.stores) s.property.id: 'owner'},
    );
    final own =
        docs['rental_records/may:tenantAnnouncements:tenant-demo']!['data']
            as Map;
    expect(own['readByTenant'], {
      'tenant-demo': [item.id],
    });
    final others = docs.entries.where(
      (e) =>
          e.key.contains(':tenantAnnouncements:') &&
          !e.key.endsWith(':tenant-demo'),
    );
    for (final other in others) {
      expect(
        (other.value['data'] as Map)['readByTenant'],
        isNot(contains('tenant-demo')),
      );
    }
  });
}
