import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../layouts/role_layout.dart';
import 'firebase_account_gateway.dart';
import 'firebase_media_store.dart';
import 'local_database.dart';
import 'rental_cloud_codec.dart';

/// Chỉ tải nghiệp vụ của chủ trọ hoặc người thuê đã được Firebase cấp quyền.
class ScopedFirestoreRentalRepository
    implements RentalRepository, RentalChangeSource {
  ScopedFirestoreRentalRepository({
    required this.session,
    FirebaseFirestore? firestore,
    FirebaseMediaStore? mediaStore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _mediaStore = mediaStore ?? FirebaseMediaStore();
  final FirebaseAccountSession session;
  final FirebaseFirestore _firestore;
  final FirebaseMediaStore _mediaStore;
  final _baseline = <String, Map<String, dynamic>>{};
  final _owners = <String, String>{};
  final _ticketAuthors = <String, String>{};
  final _localBaseline = <String, Map<String, dynamic>>{};
  Map<String, Map<String, dynamic>>? _lastReadSnapshot;

  static List<List<String>> tenantPropertyGroups(
    Iterable<Map<String, dynamic>> records,
  ) {
    final ids =
        records
            .where((record) => record['archived'] != true)
            .map((record) => record['propertyId'])
            .whereType<String>()
            .where((id) => id.isNotEmpty && !id.contains('/'))
            .toSet()
            .toList()
          ..sort();
    return [
      for (var i = 0; i < ids.length; i += 10)
        ids.sublist(i, (i + 10).clamp(0, ids.length)),
    ];
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _tenantProperties(
    QuerySnapshot<Map<String, dynamic>> records,
  ) async {
    final groups = tenantPropertyGroups(records.docs.map((doc) => doc.data()));
    final snapshots = await Future.wait(
      groups.map(
        (ids) => _firestore
            .collection('rental_properties')
            .where(FieldPath.documentId, whereIn: ids)
            .get(const GetOptions(source: Source.server)),
      ),
    );
    return [for (final snapshot in snapshots) ...snapshot.docs];
  }

  @override
  Stream<void> get changes => Stream<void>.multi((controller) {
    Query<Map<String, dynamic>> properties = _firestore.collection(
      'rental_properties',
    );
    Query<Map<String, dynamic>> records = _firestore.collection(
      'rental_records',
    );
    Query<Map<String, dynamic>> tickets = _firestore.collection(
      'support_tickets',
    );
    if (session.role == AppRole.landlord) {
      properties = properties.where('ownerUid', isEqualTo: session.uid);
      records = records.where('ownerUid', isEqualTo: session.uid);
    } else if (session.role == AppRole.tenant) {
      records = records.where('tenantIds', arrayContains: session.tenantId);
    }
    if (session.role != AppRole.admin) {
      tickets = tickets.where('accountUid', isEqualTo: session.uid);
    }
    final subscriptions = <StreamSubscription<dynamic>>[];
    StreamSubscription<dynamic> watch(Stream<dynamic> stream) {
      final subscription = stream
          .skip(1)
          .listen(
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
          );
      subscriptions.add(subscription);
      return subscription;
    }

    if (session.role == AppRole.tenant) {
      var previousGroups = '';
      var firstRecords = true;
      final propertySubscriptions = <StreamSubscription<dynamic>>[];
      subscriptions.add(
        records.snapshots().listen(
          (snapshot) {
            final groups = tenantPropertyGroups(
              snapshot.docs.map((doc) => doc.data()),
            );
            final key = groups.map((ids) => ids.join('|')).join(';');
            if (key != previousGroups) {
              previousGroups = key;
              for (final subscription in propertySubscriptions) {
                unawaited(subscription.cancel());
              }
              propertySubscriptions.clear();
              for (final ids in groups) {
                propertySubscriptions.add(
                  watch(
                    _firestore
                        .collection('rental_properties')
                        .where(FieldPath.documentId, whereIn: ids)
                        .snapshots(),
                  ),
                );
              }
            }
            if (!firstRecords && !controller.isClosed) controller.add(null);
            firstRecords = false;
          },
          onError: (Object error) {
            if (!controller.isClosed) controller.addError(error);
          },
        ),
      );
    } else {
      watch(properties.snapshots());
      watch(records.snapshots());
    }
    watch(tickets.snapshots());
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
    const server = GetOptions(source: Source.server);
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
    Query<Map<String, dynamic>> tickets = _firestore.collection(
      'support_tickets',
    );
    if (session.role != AppRole.admin) {
      tickets = tickets.where('accountUid', isEqualTo: session.uid);
    }

    final recordRequest = records.get(server);
    final propertyRequest = session.role == AppRole.tenant
        ? recordRequest.then(_tenantProperties)
        : properties.get(server).then((snapshot) => snapshot.docs);
    final futures = <Future<dynamic>>[
      propertyRequest,
      recordRequest,
      _firestore.collection('user_state').doc(session.uid).get(server),
      tickets.get(server),
      _firestore.doc('public_settings/viewings').get(server),
      if (session.role == AppRole.admin)
        _firestore.doc('management/system').get(server)
      else if (session.role == AppRole.landlord)
        _firestore.doc('management/${session.uid}').get(server),
    ];
    final results = await Future.wait(futures);
    final propertyDocs =
        results[0] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
    final recordSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final own = results[2] as DocumentSnapshot<Map<String, dynamic>>;
    final savedTickets = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final viewingSettings =
        results[4] as DocumentSnapshot<Map<String, dynamic>>;
    final settings = results.length > 5
        ? results[5] as DocumentSnapshot<Map<String, dynamic>>
        : null;

    final stores = <String, Map<String, dynamic>>{};
    _baseline.clear();
    _owners.clear();
    _ticketAuthors.clear();
    for (final doc in propertyDocs) {
      final data = doc.data();
      _baseline[doc.reference.path] = data;
      final ownerUid = data['ownerUid'] as String?;
      if (ownerUid != null) _owners[doc.id] = ownerUid;
      if (data['archived'] == true || data['data'] is! Map) continue;
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
    for (final doc in recordSnap.docs) {
      final envelope = doc.data();
      _baseline[doc.reference.path] = envelope;
      if (envelope['archived'] == true) continue;
      final id = envelope['propertyId'] as String?;
      final kind = envelope['kind'] as String?;
      final rawData = envelope['data'];
      if (id == null || kind == null || rawData is! Map) continue;
      final store = stores[id];
      if (store == null) continue;
      final data = Map<String, dynamic>.from(rawData);
      if (kind == 'settings') {
        store.addAll(data);
      } else if (kind == 'messages') {
        messages.add(data);
      } else if (kind == 'tenantAnnouncements' &&
          session.role != AppRole.tenant) {
        final reads = announcementReads.putIfAbsent(id, () => {});
        if (data['readByTenant'] is Map) {
          reads.addAll(Map<String, dynamic>.from(data['readByTenant'] as Map));
        }
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
      if (announcements != null && announcements['readByTenant'] is Map) {
        (announcements['readByTenant'] as Map).addAll(entry.value);
      }
    }
    for (final conversation in snapshot['conversations']!['records'] as List) {
      final propId = conversation['propertyId'] as String?;
      final convId = conversation['id'] as String?;
      if (propId == null || convId == null) continue;
      conversation['messages'] = decodeCloudMessages(
        messages,
        '${Uri.encodeComponent(propId)}:conversations:${Uri.encodeComponent(convId)}',
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
      'selectedId': ordered.isEmpty
          ? ''
          : (ordered.first['property'] as Map)['id'],
      'properties': ordered,
    };
    if (own.exists && own.data() != null) {
      _baseline[own.reference.path] = own.data()!;
      final data = own.data()!;
      for (final key in ['accounts', 'favorites']) {
        if (data[key] is Map) {
          snapshot[key] = Map<String, dynamic>.from(data[key] as Map);
        }
      }
    }
    if (settings != null && settings.exists && settings.data() != null) {
      _baseline[settings.reference.path] = settings.data()!;
      if (session.role == AppRole.admin && settings.data()!['admin'] is Map) {
        snapshot['admin'] = Map<String, dynamic>.from(
          settings.data()!['admin'] as Map,
        );
      } else if (session.role == AppRole.landlord &&
          settings.data()!['staff'] is Map) {
        snapshot['staff'] = Map<String, dynamic>.from(
          settings.data()!['staff'] as Map,
        );
      }
    }
    if (viewingSettings.exists && viewingSettings.data() != null) {
      _baseline[viewingSettings.reference.path] = viewingSettings.data()!;
      snapshot['admin']!['acceptingViewings'] = viewingSettings
          .data()!['acceptingViewings'];
    }
    restoreCloudPropertyVerification(
      snapshot['admin']!,
      propertyDocs.map((document) => document.data()),
    );
    snapshot['admin']!['tickets'] = [
      for (final doc in savedTickets.docs)
        if (doc.data()['data'] != null) doc.data()['data'],
    ];
    for (final doc in savedTickets.docs) {
      _baseline[doc.reference.path] = doc.data();
      final author = doc.data()['accountUid'] as String?;
      if (author != null) _ticketAuthors[doc.id] = author;
    }
    _localBaseline.clear();
    _lastReadSnapshot = snapshot;
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
          entry.value['verified'] = _baseline[entry.key]?['verified'] ?? false;
          entry.value['verificationProof'] =
              _baseline[entry.key]?['verificationProof'] ?? '';
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
    if (_localBaseline.isEmpty && _lastReadSnapshot != null) {
      _localBaseline.addAll(_encode(_lastReadSnapshot!));
    }
    final prepared = await _mediaStore.prepareForCloud(
      documents,
      uploadPropertyMedia: session.role != AppRole.tenant,
    );
    if (session.role == AppRole.tenant) {
      await _prepareTenantRequestTargets(prepared);
    }
    final encoded = _encode(prepared);
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

  /// A new chat/viewing can target a property not rented by this tenant. Load
  /// just that property when saving the request, rather than preloading the
  /// entire public portfolio at sign-in. The temporary store is never published.
  Future<void> _prepareTenantRequestTargets(
    Map<String, Map<String, dynamic>> documents,
  ) async {
    final stores = documents['portfolio']?['properties'] as List?;
    if (stores == null) return;
    final loaded = {
      for (final store in stores) (store['property'] as Map)['id'],
    };
    final targets = <String>{
      for (final kind in ['conversations', 'viewings'])
        for (final row in documents[kind]?['records'] as List? ?? [])
          if (row['propertyId'] is String) row['propertyId'] as String,
    }..removeAll(loaded);
    for (final id in targets) {
      if (id.isEmpty || id.contains('/')) {
        throw ArgumentError('Mã nhà trọ chưa hợp lệ.');
      }
      final path = 'rental_properties/$id';
      var property = _baseline[path];
      if (property == null) {
        final document = await _firestore
            .doc(path)
            .get(const GetOptions(source: Source.server));
        property = document.data();
        if (property == null) {
          throw ArgumentError('Nhà trọ này không còn tồn tại.');
        }
        _baseline[path] = property;
      }
      final owner = property['ownerUid'];
      if (owner is! String || property['data'] is! Map) {
        throw ArgumentError(
          'Chưa tải được thông tin chủ trọ. Vui lòng thử lại.',
        );
      }
      _owners[id] = owner;
      stores.add({
        ...Map<String, dynamic>.from(property['data'] as Map),
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
      });
    }
  }

  @override
  Future<void> close() async {}
}
