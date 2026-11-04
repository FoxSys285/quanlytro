import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../layouts/role_layout.dart';
import 'firebase_account_gateway.dart';
import 'local_database.dart';
import 'rental_cloud_codec.dart';

/// Chỉ tải nghiệp vụ của chủ trọ hoặc người thuê đã được Firebase cấp quyền.
class ScopedFirestoreRentalRepository
    implements RentalRepository, RentalChangeSource {
  ScopedFirestoreRentalRepository({
    required this.session,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseAccountSession session;
  final FirebaseFirestore _firestore;
  final _baseline = <String, Map<String, dynamic>>{};
  final _owners = <String, String>{};
  final _ticketAuthors = <String, String>{};
  final _localBaseline = <String, Map<String, dynamic>>{};

  @override
  Stream<void> get changes => Stream<void>.multi((controller) {
    Query<Map<String, dynamic>> records = _firestore.collection(
      'rental_records',
    );
    Query<Map<String, dynamic>> properties = _firestore.collection(
      'rental_properties',
    );
    Query<Map<String, dynamic>> tickets = _firestore.collection(
      'support_tickets',
    );
    if (session.role == AppRole.landlord) {
      records = records.where('ownerUid', isEqualTo: session.uid);
      properties = properties.where('ownerUid', isEqualTo: session.uid);
    } else if (session.role == AppRole.tenant) {
      records = records.where('tenantIds', arrayContains: session.tenantId);
    }
    if (session.role != AppRole.admin) {
      tickets = tickets.where('accountUid', isEqualTo: session.uid);
    }
    final subscriptions = <StreamSubscription<dynamic>>[];
    void watch(Stream<dynamic> stream) {
      subscriptions.add(
        stream.listen(
          (_) {
            if (!controller.isClosed) controller.add(null);
          },
          onError: (Object error) {
            debugPrint('Firestore stream warning: $error');
            if (error is FirebaseException &&
                error.code == 'permission-denied' &&
                session.role == AppRole.admin) {
              return;
            }
            if (!controller.isClosed) controller.addError(error);
          },
        ),
      );
    }

    watch(properties.snapshots());
    watch(records.snapshots());
    watch(tickets.snapshots());
    if (session.role != AppRole.tenant) {
      Query<Map<String, dynamic>> rooms = _firestore.collection('public_rooms');
      if (session.role == AppRole.landlord) {
        rooms = rooms.where('ownerUid', isEqualTo: session.uid);
      }
      watch(rooms.snapshots());
    }
    watch(_firestore.doc('user_state/${session.uid}').snapshots());
    watch(_firestore.doc('public_settings/viewings').snapshots());
    watch(_firestore.doc('users/${session.uid}').snapshots());
    if (session.role != AppRole.tenant) {
      watch(
        _firestore
            .doc(
              'management/${session.role == AppRole.admin ? 'system' : session.uid}',
            )
            .snapshots(),
      );
    }
    controller.onCancel = () async {
      await Future.wait(
        subscriptions.map((subscription) => subscription.cancel()),
      );
    };
  });

  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async {
    Query<Map<String, dynamic>> properties = _firestore.collection(
      'rental_properties',
    );
    Query<Map<String, dynamic>> records = _firestore.collection(
      'rental_records',
    );
    if (session.role == AppRole.landlord) {
      properties = properties.where('ownerUid', isEqualTo: session.uid);
      records = records.where('ownerUid', isEqualTo: session.uid);
    } else if (session.role == AppRole.tenant) {
      if (session.tenantId == null) {
        throw ArgumentError('Tài khoản chưa có mã người thuê.');
      }
      records = records.where('tenantIds', arrayContains: session.tenantId);
    }
    final results = await Future.wait([
      properties.get(),
      records.get(),
    ]);
    final stores = <String, Map<String, dynamic>>{};
    _baseline.clear();
    _owners.clear();
    _ticketAuthors.clear();
    for (final doc in results[0].docs) {
      final data = doc.data();
      _baseline[doc.reference.path] = data;
      _owners[doc.id] = data['ownerUid'] as String;
      if (data['archived'] == true) continue;
      stores[doc.id] = {
        ...Map<String, dynamic>.from(data['data'] as Map),
        for (final kind in [
          'leases',
          'invoices',
          'payments',
          'members',
          'incidents',
          'readings',
          'paymentAccounts',
        ])
          kind: <dynamic>[],
        'counters': List.filled(7, 1),
      };
    }
    if (stores.isEmpty) {
      throw ArgumentError('Tài khoản chưa được cấp dữ liệu nhà trọ.');
    }
    if (session.role != AppRole.tenant) {
      Query<Map<String, dynamic>> rooms = _firestore.collection('public_rooms');
      if (session.role == AppRole.landlord) {
        rooms = rooms.where('ownerUid', isEqualTo: session.uid);
      }
      final public = await rooms.get();
      for (final doc in public.docs) {
        _baseline[doc.reference.path] = doc.data();
      }
    }
    final snapshot = <String, Map<String, dynamic>>{
      'viewings': {'records': <dynamic>[], 'nextId': 1},
      'conversations': {'records': <dynamic>[]},
      'staff': {'nextId': 1, 'staff': <dynamic>[]},
      'admin': {
        'verified': <String, bool>{},
        'hidden': <String>[],
        'tickets': <dynamic>[],
        'logs': <dynamic>[],
        'acceptingViewings': true,
      },
    };
    final messages = <Map<String, dynamic>>[];
    final announcementReads = <String, Map<String, dynamic>>{};
    for (final doc in results[1].docs) {
      final envelope = doc.data();
      _baseline[doc.reference.path] = envelope;
      if (envelope['archived'] == true) continue;
      final id = envelope['propertyId'] as String;
      final store = stores[id];
      if (store == null) continue;
      final kind = envelope['kind'] as String;
      final data = Map<String, dynamic>.from(envelope['data'] as Map);
      if (kind == 'settings') {
        store.addAll(data);
      } else if (kind == 'messages') {
        messages.add(data);
      } else if (kind == 'tenantAnnouncements' &&
          session.role != AppRole.tenant) {
        final reads = announcementReads.putIfAbsent(id, () => {});
        reads.addAll(Map<String, dynamic>.from(data['readByTenant'] as Map));
      } else if (kind == 'conversations' || kind == 'viewings') {
        (snapshot[kind]!['records'] as List).add(data);
      } else if ((kind == 'announcements' && session.role != AppRole.tenant) ||
          (kind == 'tenantAnnouncements' && session.role == AppRole.tenant)) {
        snapshot['announcements:$id'] = data;
      } else if (store[kind] is List) {
        (store[kind] as List).add(data);
      }
    }
    for (final entry in announcementReads.entries) {
      final announcements = snapshot['announcements:${entry.key}'];
      if (announcements != null) {
        (announcements['readByTenant'] as Map).addAll(entry.value);
      }
    }
    for (final conversation in snapshot['conversations']!['records'] as List) {
      conversation['messages'] = decodeCloudMessages(
        messages,
        '${Uri.encodeComponent(conversation['propertyId'] as String)}:conversations:${Uri.encodeComponent(conversation['id'] as String)}',
      );
    }
    for (final id in stores.keys) {
      snapshot.putIfAbsent(
        'announcements:$id',
        () => {
          'sent': <dynamic>[],
          'recipients': <String, dynamic>{},
          'readByTenant': <String, dynamic>{},
          'landlordRead': <dynamic>[],
          'nextId': 1,
        },
      );
    }
    final ordered = stores.values.toList();
    if (session.role == AppRole.tenant) {
      ordered.sort(
        (a, b) => (b['leases'] as List).length.compareTo(
          (a['leases'] as List).length,
        ),
      );
    }
    snapshot['portfolio'] = {
      'selectedId': (ordered.first['property'] as Map)['id'],
      'properties': ordered,
    };
    final own = await _firestore
        .collection('user_state')
        .doc(session.uid)
        .get();
    if (own.exists) {
      _baseline[own.reference.path] = own.data()!;
      final data = own.data()!;
      for (final key in ['accounts', 'favorites']) {
        if (data[key] is Map) {
          snapshot[key] = Map<String, dynamic>.from(data[key] as Map);
        }
      }
    }
    if (session.role == AppRole.admin) {
      final settings = await _firestore.doc('management/system').get();
      if (settings.exists) {
        _baseline[settings.reference.path] = settings.data()!;
        snapshot['admin'] = Map<String, dynamic>.from(
          settings.data()!['admin'] as Map,
        );
      }
    } else if (session.role == AppRole.landlord) {
      final settings = await _firestore.doc('management/${session.uid}').get();
      if (settings.exists) {
        _baseline[settings.reference.path] = settings.data()!;
        snapshot['staff'] = Map<String, dynamic>.from(
          settings.data()!['staff'] as Map,
        );
      }
    }
    Query<Map<String, dynamic>> tickets = _firestore.collection(
      'support_tickets',
    );
    if (session.role != AppRole.admin) {
      tickets = tickets.where('accountUid', isEqualTo: session.uid);
    }
    final savedTickets = await tickets.get();
    final viewingSettings = await _firestore
        .doc('public_settings/viewings')
        .get();
    if (viewingSettings.exists) {
      _baseline[viewingSettings.reference.path] = viewingSettings.data()!;
      snapshot['admin']!['acceptingViewings'] = viewingSettings
          .data()!['acceptingViewings'];
    }
    snapshot['admin']!['tickets'] = [
      for (final doc in savedTickets.docs) doc.data()['data'],
    ];
    for (final doc in savedTickets.docs) {
      _baseline[doc.reference.path] = doc.data();
      _ticketAuthors[doc.id] = doc.data()['accountUid'] as String;
    }
    _localBaseline
      ..clear()
      ..addAll(_encode(snapshot));
    return snapshot;
  }

  Map<String, Map<String, dynamic>> _encode(
    Map<String, Map<String, dynamic>> documents,
  ) {
    if (session.role == AppRole.landlord) {
      for (final store
          in documents['portfolio']?['properties'] as List? ?? []) {
        _owners.putIfAbsent(
          (store['property'] as Map)['id'] as String,
          () => session.uid,
        );
      }
    }
    final encoded = encodeCloudDocuments(documents, owners: _owners);
    if (session.role == AppRole.landlord) {
      // Only admin controls publication; landlord edits must preserve moderation.
      for (final entry in encoded.entries) {
        if (entry.key.startsWith('rental_properties/')) {
          entry.value['published'] = _baseline[entry.key]?['published'] ?? true;
        } else if (entry.key.startsWith('public_rooms/')) {
          final property =
              _baseline['rental_properties/${entry.value['propertyId']}'];
          entry.value['published'] =
              property?['published'] != false &&
              (_baseline[entry.key]?['published'] ?? true);
        }
      }
    }
    if (session.role == AppRole.tenant) {
      // Không xuất bản lại phòng/thiết lập/chứng từ của chủ trọ từ bản chiếu người thuê.
      encoded.removeWhere(
        (path, row) =>
            !path.startsWith('rental_records/') ||
            ![
              'payments',
              'members',
              'incidents',
              'viewings',
              'conversations',
              'messages',
              'tenantAnnouncements',
            ].contains(row['kind']),
      );
      for (final entry in encoded.entries) {
        final saved = _baseline[entry.key];
        if (entry.value['kind'] == 'conversations' && saved != null) {
          final data = entry.value['data'] as Map;
          // Rental-derived names are display data; tenants only change counters.
          entry.value['data'] = {
            ...Map<String, dynamic>.from(saved['data'] as Map),
            'unread': data['unread'],
            'tenantUnread': data['tenantUnread'],
          };
        }
      }
    } else {
      for (final entry in _baseline.entries) {
        if (encoded.containsKey(entry.key)) continue;
        if (entry.key.startsWith('public_rooms/')) {
          encoded[entry.key] = {
            ...entry.value,
            'published': false,
            'available': false,
          };
        } else if (entry.key.startsWith('rental_properties/')) {
          encoded[entry.key] = {...entry.value, 'archived': true};
        } else if (entry.key.startsWith('rental_records/') &&
            entry.value['kind'] != 'messages') {
          encoded[entry.key] = {...entry.value, 'archived': true};
        }
      }
    }
    final ownPath = 'user_state/${session.uid}';
    encoded[ownPath] = {
      'accounts':
          documents['accounts'] ?? {'contacts': {}, 'notifications': {}},
      'favorites': documents['favorites'] ?? {'ids': []},
    };
    if (session.role == AppRole.admin) {
      encoded['management/system'] = {
        'admin': {...?documents['admin'], 'tickets': <dynamic>[]},
      };
      encoded['public_settings/viewings'] = {
        'acceptingViewings': documents['admin']?['acceptingViewings'] ?? true,
      };
    } else if (session.role == AppRole.landlord) {
      encoded['management/${session.uid}'] = {'staff': documents['staff']};
    }
    for (final ticket in documents['admin']?['tickets'] as List? ?? []) {
      final id = ticket['id'] as String;
      encoded['support_tickets/$id'] = {
        'accountUid': _ticketAuthors[id] ?? session.uid,
        'data': ticket,
      };
    }
    return encoded;
  }

  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    final encoded = _encode(documents);
    final changed = encoded.entries
        .where(
          (e) =>
              cloudFingerprint(e.value) !=
              cloudFingerprint(_localBaseline[e.key]),
        )
        .toList();
    if (changed.isEmpty) return;
    // One operation is atomic: never save an approval without its invoice.
    if (changed.length > 400) {
      throw StateError(
        'Thay đổi quá lớn. Chia nhỏ thao tác hoặc dùng công cụ nhập dữ liệu.',
      );
    }
    final committed = await _firestore.runTransaction((transaction) async {
      final live = await Future.wait(
        changed.map((e) => transaction.get(_firestore.doc(e.key))),
      );
      final merged = <String, Map<String, dynamic>>{};
      for (var i = 0; i < changed.length; i++) {
        final entry = changed[i];
        final value = mergeCloudDocument(
          _localBaseline[entry.key],
          entry.value,
          live[i].data(),
          serverBefore: _baseline[entry.key],
          atomic: [
            'leases',
            'invoices',
            'payments',
          ].contains(entry.value['kind']),
        );
        // Preserve moderation even when admin hides a room after our read.
        if (session.role == AppRole.landlord &&
            entry.key.startsWith('public_rooms/') &&
            live[i].exists) {
          value['published'] =
              entry.value['published'] != false &&
              live[i].data()!['published'] == true;
        }
        merged[entry.key] = value;
        transaction.set(_firestore.doc(entry.key), value);
      }
      return merged;
    });
    _baseline.addAll(committed);
    _localBaseline.addAll(encoded);
  }

  @override
  Future<void> close() async {}
}
