import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/data/property_catalog.dart';
import 'package:quanlytro/data/firebase_account_gateway.dart';
import 'package:quanlytro/data/firebase_media_store.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/data/scoped_firestore_repository.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';

import 'support/memory_firestore_queries.dart';

Json _room(int index, {String name = 'Phòng trọ', String propertyId = 'may'}) =>
    {
      'published': true,
      'available': true,
      'propertyId': propertyId,
      'roomCode': 'P.$index',
      'name': '$name $index',
      'address': 'Địa chỉ',
      'price': 1000000 + index * 10000,
      'area': 20 + index,
      'capacity': 2,
      'roomType': 'Studio',
      'city': 'TP. Hồ Chí Minh',
      'ward': 'Phường 25',
      'electricityPrice': 3500,
      'waterType': 'Theo m³',
      'waterPrice': 20000,
      'photos': [],
      'tags': [],
    };

class _Media extends Fake implements FirebaseMediaStore {
  @override
  Future<Map<String, Map<String, dynamic>>> prepareForCloud(
    Map<String, Map<String, dynamic>> snapshot, {
    bool uploadPropertyMedia = true,
  }) async => snapshot;
}

void main() {
  test('Room pagination reads page + one lookahead and continues without duplicates', () async {
    final db = MemoryFirestore({
      'public_rooms': {
        for (var i = 0; i < 1000; i++)
          'room-${i.toString().padLeft(4, '0')}': _room(i),
      },
    });
    final source = FirestoreTenantCatalogSource(firestore: db);
    final first = await source.fetch(const TenantCatalogQuery(), limit: 10);
    expect(first.items, hasLength(10));
    expect(db.documentsRead, 11);
    final second = await source.fetch(
      const TenantCatalogQuery(),
      after: first.nextCursor,
      limit: 10,
    );
    expect(second.items, hasLength(10));
    expect(
      second.items
          .map((r) => r.id)
          .toSet()
          .intersection(first.items.map((r) => r.id).toSet()),
      isEmpty,
    );
    expect(db.documentsRead, 22);
    expect(db.reads.every((read) => read.limit == 11), isTrue);
  });

  test('A rare keyword never scans the full collection and the continuation finds later matches', () async {
    final db = MemoryFirestore({
      'public_rooms': {
        for (var i = 0; i < 1000; i++)
          'room-${i.toString().padLeft(4, '0')}': _room(
            i,
            name: i == 70 ? 'needle' : 'Phòng',
          ),
      },
    });
    final source = FirestoreTenantCatalogSource(firestore: db);
    final first = await source.fetch(const TenantCatalogQuery(query: 'needle'));
    expect(first.items, isEmpty);
    expect(first.nextCursor, isNotNull);
    expect(db.documentsRead, 64);
    final next = await source.fetch(
      const TenantCatalogQuery(query: 'needle'),
      after: first.nextCursor,
    );
    expect(next.items, hasLength(1));
    expect(next.items.single.name, 'needle 70');
    expect(db.documentsRead, 128);
  });

  test('Property and availability filters reach Firestore before sorted pagination', () async {
    final db = MemoryFirestore({
      'public_rooms': {
        for (var i = 0; i < 1000; i++)
          'room-${i.toString().padLeft(4, '0')}': _room(
            i,
            propertyId: i < 980 ? 'other' : 'may',
          ),
      },
    });
    final page = await FirestoreTenantCatalogSource(firestore: db)
        .fetch(const TenantCatalogQuery(propertyId: 'may', sort: 'rentDesc'));
    expect(page.items.first.name, 'Phòng trọ 999');
    expect(db.documentsRead, 9);
    expect(db.reads.single.filters, {
      'published': true,
      'available': true,
      'propertyId': 'may',
    });
  });

  test('Verified property pagination reads a bounded page instead of every property', () async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final raw = rental.toMap();
    final db = MemoryFirestore({
      'rental_properties': {
        for (var i = 0; i < 680; i++)
          'property-${i.toString().padLeft(4, '0')}': {
            'published': true,
            'verified': i >= 280,
            'data': raw,
            'verificationProof': propertyVerificationProof(raw),
          },
      },
    });
    final source = FirestoreTenantPropertyCatalogSource(firestore: db);
    final page = await source.fetch(
      const TenantPropertyQuery(verifiedOnly: true),
      limit: 10,
    );
    expect(page.items, hasLength(10));
    expect(db.documentsRead, 11);
    expect(db.reads.single.filters, {'published': true, 'verified': true});
  });

  test('GPS city aliases and wards filter on the server instead of scanning other provinces', () async {
    final db = MemoryFirestore({
      'public_rooms': {
        for (var i = 0; i < 1000; i++)
          'room-${i.toString().padLeft(4, '0')}': {
            ..._room(i),
            'city': i < 980 ? 'Thành phố Hà Nội' : 'TP. Hồ Chí Minh',
          },
      },
    });
    final page = await FirestoreTenantCatalogSource(firestore: db).fetch(
      const TenantCatalogQuery(city: 'Ho Chi Minh City', ward: 'Phường 25'),
    );
    expect(page.items, hasLength(8));
    expect(db.documentsRead, 9);
    expect(db.reads.single.filters['city'], contains('TP. Hồ Chí Minh'));
    expect(db.reads.single.filters['ward'], contains('Phường 25'));
  });

  test('Tenant business sync reads only properties referenced by their own records', () async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final db = MemoryFirestore({
      'rental_properties': {
        'may': {
          'ownerUid': 'owner-a',
          'published': true,
          'data': rental.toMap(),
        },
        for (var i = 0; i < 680; i++)
          'unrelated-$i': {'ownerUid': 'owner-$i', 'data': rental.toMap()},
      },
      'rental_records': {
        'lease-a': {
          'propertyId': 'may',
          'ownerUid': 'owner-a',
          'tenantIds': ['tenant-a'],
          'kind': 'leases',
          'archived': false,
          'data': {'id': 'lease-a'},
        },
        'lease-other': {
          'propertyId': 'unrelated-1',
          'tenantIds': ['someone-else'],
          'kind': 'leases',
          'data': {},
        },
      },
    });
    final repository = ScopedFirestoreRentalRepository(
      session: const FirebaseAccountSession(
        uid: 'account-a',
        role: AppRole.tenant,
        tenantId: 'tenant-a',
      ),
      firestore: db,
      mediaStore: _Media(),
    );
    final snapshot = await repository.readAll();
    expect(snapshot['portfolio']!['properties'], hasLength(1));
    final propertyReads = db.reads
        .where((read) => read.collection == 'rental_properties')
        .toList();
    expect(propertyReads, hasLength(1));
    expect(propertyReads.single.filters['__name__'], ['may']);
    expect(propertyReads.single.count, 1);
  });

  test('Home fetches ten rooms per section without loading the whole property portfolio', () async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final raw = rental.toMap();
    final db = MemoryFirestore({
      'public_rooms': {
        for (var i = 0; i < 1000; i++)
          'room-${i.toString().padLeft(4, '0')}': _room(i),
      },
      'rental_properties': {
        'may': {
          'data': raw,
          'verified': true,
          'published': true,
          'verificationProof': propertyVerificationProof(raw),
        },
        for (var i = 0; i < 680; i++)
          'unverified-$i': {'verified': false, 'published': true},
      },
    });
    final feed = await FirestoreTenantCatalogSource(firestore: db).fetchHome();
    expect(feed.featured, hasLength(10));
    expect(feed.goodPrice, hasLength(10));
    expect(feed.trusted, hasLength(10));
    expect(db.documentsRead, 33);
    expect(
      db.reads.every((read) => read.limit != null && read.limit! <= 11),
      isTrue,
    );
  });

  test(
    'Tenant with no records does not read the public property collection',
    () async {
      final db = MemoryFirestore({});
      final repository = ScopedFirestoreRentalRepository(
        session: const FirebaseAccountSession(
          uid: 'new',
          role: AppRole.tenant,
          tenantId: 'tenant-new',
        ),
        firestore: db,
        mediaStore: _Media(),
      );
      await repository.readAll();
      expect(
        db.reads.where((read) => read.collection == 'rental_properties'),
        isEmpty,
      );
    },
  );

  test('Starting a new chat and viewing loads one target and still saves messages without publishing property data', () async {
    final rental = LandlordDemoStore.demo();
    addTearDown(rental.dispose);
    final db = MemoryFirestore({
      'rental_properties': {
        'may': {
          'ownerUid': 'owner-a',
          'published': true,
          'data': rental.toMap(),
        },
      },
    });
    final repository = ScopedFirestoreRentalRepository(
      session: const FirebaseAccountSession(
        uid: 'new',
        role: AppRole.tenant,
        tenantId: 'tenant-new',
      ),
      firestore: db,
      mediaStore: _Media(),
    );
    final initial = await repository.readAll();
    expect(initial['portfolio']!['properties'], isEmpty);
    final edited = <String, Map<String, dynamic>>{
      ...initial,
      'portfolio': {'properties': <dynamic>[], 'selectedId': ''},
      'conversations': {
        'records': [
          {
            'id': 'chat-new',
            'propertyId': 'may',
            'tenantId': 'tenant-new',
            'messages': [
              {'text': 'Chào chủ trọ', 'time': '09:00', 'fromLandlord': false},
            ],
          },
        ],
      },
      'viewings': {
        'records': [
          {
            'id': 'view-new',
            'propertyId': 'may',
            'tenantId': 'tenant-new',
            'status': 'pending',
          },
        ],
      },
    };
    await repository.saveAll(edited);
    expect(
      db.reads.where((read) => read.collection == 'rental_properties'),
      hasLength(1),
    );
    expect(db.writes, contains('rental_records/may:conversations:chat-new'));
    expect(db.writes, contains('rental_records/may:messages:chat-new%3A0'));
    expect(db.writes, contains('rental_records/may:viewings:view-new'));
    expect(
      db.writes.any(
        (path) =>
            path.startsWith('rental_properties/') ||
            path.startsWith('public_rooms/'),
      ),
      isFalse,
    );
    final conversation =
        db.documents['rental_records']!['may:conversations:chat-new']!;
    expect(conversation['ownerUid'], 'owner-a');
    expect(conversation['tenantIds'], ['tenant-new']);
    expect(conversation['data']['messages'], isEmpty);
  });
}
