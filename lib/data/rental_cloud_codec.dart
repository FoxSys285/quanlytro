import 'dart:convert';

import 'package:crypto/crypto.dart';

String propertyVerificationProof(Map<String, dynamic> store) => sha256
    .convert(
      utf8.encode(
        cloudFingerprint({
          'property': Map<String, dynamic>.from(store['property'] as Map)
            ..remove('verificationDocuments')
            ..remove('verificationSubmittedAt')
            ..remove('verificationIsOwner'),
          'rooms': store['rooms'],
          'types': store['roomTypes'],
        }),
      ),
    )
    .toString();

/// Property documents carry the approval used by public catalogue readers.
/// Restore the same state for landlord/tenant sessions and stale admin caches.
void restoreCloudPropertyVerification(
  Map<String, dynamic> admin,
  Iterable<Map<String, dynamic>> documents,
) {
  final flags = Map<String, bool>.from(admin['verified'] as Map? ?? {});
  final proofs = Map<String, String>.from(
    admin['verificationProofs'] as Map? ?? {},
  );
  for (final document in documents) {
    final data = document['data'];
    if (data is! Map || data['property'] is! Map) continue;
    final id = data['property']['id'];
    if (id is! String) continue;
    final proof = document['verificationProof'] as String? ?? '';
    flags[id] =
        document['verified'] == true &&
        proof == propertyVerificationProof(Map<String, dynamic>.from(data));
    proofs[id] = proof;
  }
  admin['verified'] = flags;
  admin['verificationProofs'] = proofs;
}

/// Các document nhỏ dùng chung cho bước chuyển dữ liệu và repository Firebase.
Map<String, Map<String, dynamic>> encodeCloudDocuments(
  Map<String, Map<String, dynamic>> snapshot, {
  required Map<String, String> owners,
}) {
  final output = <String, Map<String, dynamic>>{};
  final stores = snapshot['portfolio']?['properties'] as List? ?? [];
  final hidden = List<String>.from(snapshot['admin']?['hidden'] as List? ?? []);
  for (final raw in stores) {
    final store = Map<String, dynamic>.from(raw as Map);
    final property = Map<String, dynamic>.from(store['property'] as Map);
    final id = property['id'] as String;
    final owner = owners[id];
    if (owner == null) {
      throw ArgumentError('Chưa cấp chủ sở hữu cho nhà trọ $id.');
    }
    final leases = (store['leases'] as List).cast<Map>();
    final proof = propertyVerificationProof(store);
    final verified =
        snapshot['admin']?['verified']?[id] == true &&
        snapshot['admin']?['verificationProofs']?[id] == proof;
    final publicProperty = Map<String, dynamic>.from(property)
      ..remove('verificationDocuments')
      ..remove('verificationSubmittedAt')
      ..remove('verificationIsOwner');
    final activeMemberRows = (store['members'] as List? ?? const [])
        .whereType<Map>()
        .where((member) => member['status'] == 'active')
        .toList();
    final tenants = <String>{
      ...leases.map((lease) => lease['tenantId'] as String),
      ...activeMemberRows.map((member) => member['tenantId'] as String),
    }.toList();
    void record(
      String kind,
      String key,
      Map<String, dynamic> data,
      List<String> readers,
    ) {
      output['rental_records/${Uri.encodeComponent(id)}:$kind:${Uri.encodeComponent(key)}'] =
          {
            'kind': kind,
            'propertyId': id,
            'ownerUid': owner,
            'tenantIds': readers,
            'archived': false,
            'data': data,
          };
    }

    output['rental_properties/$id'] = {
      'ownerUid': owner,
      'published': !hidden.contains(id),
      'verified': verified,
      'verificationProof': verified ? proof : '',
      'data': {
        if (store['schemaVersion'] != null)
          'schemaVersion': store['schemaVersion'],
        'property': publicProperty,
        'rooms': store['rooms'],
        'roomTypes': store['roomTypes'],
        'services': store['services'],
      },
    };
    record('settings', id, {
      'counters': store['counters'],
      'paymentAccounts': store['paymentAccounts'],
    }, tenants);
    if (property['verificationSubmittedAt'] != null ||
        (property['verificationDocuments'] as List? ?? const []).isNotEmpty) {
      record('verification', id, {
        'submittedAt': property['verificationSubmittedAt'],
        'isOwner': property['verificationIsOwner'] != false,
        'documents': property['verificationDocuments'] ?? const [],
      }, const []);
    }
    final readersForLease = <String, List<String>>{};
    for (final lease in leases) {
      final leaseId = lease['id'] as String;
      readersForLease[leaseId] = <String>{
        lease['tenantId'] as String,
        ...activeMemberRows
            .where((member) => member['leaseId'] == leaseId)
            .map((member) => member['tenantId'] as String),
      }.toList();
    }
    final invoices = (store['invoices'] as List).cast<Map>();
    final invoiceLease = {for (final i in invoices) i['id']: i['leaseId']};
    for (final kind in [
      'leases',
      'invoices',
      'payments',
      'members',
      'incidents',
      'readings',
    ]) {
      for (final row in store[kind] as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final leaseId = kind == 'leases'
            ? data['id']
            : kind == 'payments'
            ? invoiceLease[data['invoiceId']]
            : data['leaseId'];
        final readers = readersForLease[leaseId] ?? <String>[];
        final key =
            data['id']?.toString() ?? '${data['room']}:${data['period']}';
        record(kind, key, data, readers);
      }
    }
    final types = {
      for (final t in store['roomTypes'] as List) (t as Map)['id']: t,
    };
    final services = {
      for (final s in store['services'] as List) (s as Map)['id']: s,
    };
    for (final rawRoom in store['rooms'] as List) {
      final room = rawRoom as Map;
      final type = types[room['roomTypeId']];
      if (type == null) continue;
      final code = room['leaseRoomCode'] ?? room['code'];
      final taken = leases.any(
        (l) =>
            l['room'] == code &&
            l['status'] == 'active' &&
            !DateTime.parse(l['endDate'] as String).isBefore(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            ),
      );
      final electricity = services['electricity'];
      final water = services['water'];
      final typeServiceIds = List<String>.from(type['serviceIds'] ?? const []);
      final typeServicePrices = Map<String, dynamic>.from(
        type['servicePrices'] ?? const {},
      );
      Map? configuredService({required bool isWater}) {
        for (final serviceId in typeServiceIds) {
          final candidate = services[serviceId];
          if (candidate == null) continue;
          final name = (candidate['name'] as String? ?? '').toLowerCase();
          if (isWater
              ? serviceId == 'water' || name.contains('nước')
              : serviceId == 'electricity' || name.contains('điện')) {
            return candidate;
          }
        }
        return isWater ? water : electricity;
      }

      final roomElectricity = configuredService(isWater: false);
      final roomWater = configuredService(isWater: true);
      final roomElectricityPrice =
          typeServicePrices[roomElectricity?['id']] ??
          roomElectricity?['price'] ??
          4000;
      final roomWaterPrice =
          typeServicePrices[roomWater?['id']] ?? roomWater?['price'] ?? 15000;
      final publicServiceRates = <Map<String, dynamic>>[];
      for (final serviceId in typeServiceIds) {
        final service = services[serviceId];
        if (service == null || service['active'] == false) continue;
        publicServiceRates.add({
          'id': serviceId,
          'name': service['name'] as String? ?? 'Dịch vụ',
          'unit': service['unit'] as String? ?? '',
          'basis': service['basis'] as String? ?? '',
          'price': typeServicePrices[serviceId] ?? service['price'] ?? 0,
        });
      }
      final waterBasis = roomWater?['basis'] as String? ?? '';
      final waterUnit = roomWater?['unit'] as String? ?? '';
      output['public_rooms/${Uri.encodeComponent('$id:${room['code']}')}'] = {
        'propertyId': id,
        'ownerUid': owner,
        'roomCode': code,
        'name': '${property['name']} · Phòng ${room['code']} · ${type['name']}',
        'address': property['address'],
        'price': type['monthlyRent'],
        'area': room['area'],
        'capacity': room['capacity'],
        'roomType': type['name'],
        'city': property['city'],
        'ward': property['ward'],
        'description': property['description'],
        'photos': type['photos'] ?? [],
        'tags': [
          ...?property['amenities'] as List?,
          'Tầng ${room['floor']}',
          'Giờ tự do',
        ],
        'electricityPrice': roomElectricityPrice,
        'waterType':
            waterUnit.toLowerCase().contains('người') ||
                waterBasis.toLowerCase().contains('người')
            ? 'Theo người'
            : waterUnit.toLowerCase().contains('tháng') ||
                  waterUnit.toLowerCase().contains('phòng') ||
                  waterBasis.toLowerCase().contains('tháng') ||
                  waterBasis.toLowerCase().contains('phòng')
            ? 'Theo tháng'
            : 'Theo m³',
        'waterPrice': roomWaterPrice,
        'services': publicServiceRates,
        'published': !hidden.contains(id),
        'available': !taken,
      };
    }
    final announcements = snapshot['announcements:$id'];
    if (announcements != null) {
      record('announcements', id, announcements, []);
      for (final tenant in tenants) {
        final recipients = announcements['recipients'] as Map;
        final ids = recipients.entries
            .where((e) => (e.value as List).contains(tenant))
            .map((e) => e.key)
            .toSet();
        final reads = announcements['readByTenant'] as Map;
        record(
          'tenantAnnouncements',
          tenant,
          {
            'sent': (announcements['sent'] as List)
                .where((a) => ids.contains((a as Map)['id']))
                .toList(),
            'recipients': {
              for (final key in ids) key: [tenant],
            },
            'readByTenant': {
              tenant: (reads[tenant] as List? ?? [])
                  .where((announcement) => ids.contains(announcement))
                  .toList(),
            },
            'landlordRead': [],
            'nextId': announcements['nextId'],
          },
          [tenant],
        );
      }
    }
    for (final kind in ['conversations', 'viewings']) {
      for (final row in snapshot[kind]?['records'] as List? ?? []) {
        final data = Map<String, dynamic>.from(row as Map);
        if (data['propertyId'] != id) continue;
        final recipients = <String>[data['tenantId'] as String];
        if (kind == 'conversations') {
          final messages = data['messages'] as List;
          for (var index = 0; index < messages.length; index++) {
            final message = Map<String, dynamic>.from(messages[index] as Map);
            final position = message['index'] ?? index;
            record('messages', '${data['id']}:${message['id'] ?? position}', {
              ...message,
              'conversationId': data['id'],
              'index': position,
              'conversationKey':
                  '${Uri.encodeComponent(id)}:conversations:${Uri.encodeComponent(data['id'] as String)}',
            }, recipients);
          }
          data['messages'] = <dynamic>[];
        }
        record(kind, data['id'] as String, data, recipients);
      }
    }
  }
  return output;
}

List<Map<String, dynamic>> decodeCloudMessages(
  Iterable<Map<String, dynamic>> messages,
  String conversationKey,
) {
  final ordered =
      messages
          .where((message) => message['conversationKey'] == conversationKey)
          .toList()
        ..sort((a, b) {
          final index = (a['index'] as int).compareTo(b['index'] as int);
          if (index != 0) return index;
          final createdAt = (a['createdAt'] as String? ?? '').compareTo(
            b['createdAt'] as String? ?? '',
          );
          return createdAt != 0
              ? createdAt
              : (a['id'] as String? ?? '').compareTo(b['id'] as String? ?? '');
        });
  return [
    for (final message in ordered)
      {
        'text': message['text'],
        'time': message['time'],
        'fromLandlord': message['fromLandlord'],
        'index': message['index'],
        if (message['id'] != null) 'id': message['id'],
        if (message['createdAt'] != null) 'createdAt': message['createdAt'],
      },
  ];
}

String cloudFingerprint(Object? value) {
  Object? canonical(Object? item) {
    if (item is Map) {
      final keys = item.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: canonical(item[key])};
    }
    if (item is List) return item.map(canonical).toList();
    return item;
  }

  return jsonEncode(canonical(value));
}

/// Merge independent fields; never silently replace another device's edit.
/// Lists (money lines, members, messages) remain atomic values.
Map<String, dynamic> mergeCloudDocument(
  Map<String, dynamic>? before,
  Map<String, dynamic> edited,
  Map<String, dynamic>? live, {
  Map<String, dynamic>? serverBefore,
  bool atomic = false,
}) {
  if (atomic &&
      cloudFingerprint(live) != cloudFingerprint(serverBefore ?? before)) {
    throw StateError(
      'Chứng từ đã thay đổi trên thiết bị khác. Tải lại trước khi sửa tiếp.',
    );
  }
  Object? merge(Object? old, Object? local, Object? remote, Object? remoteOld) {
    if (cloudFingerprint(local) == cloudFingerprint(old)) return remote;
    if (old is Map && local is Map && remote is Map && remoteOld is Map) {
      final result = Map<String, dynamic>.from(remote);
      for (final key in {...old.keys, ...local.keys}) {
        if (!local.containsKey(key)) {
          if (cloudFingerprint(remote[key]) !=
              cloudFingerprint(remoteOld[key])) {
            throw StateError(
              'Dữ liệu đã thay đổi trên thiết bị khác. Tải lại trước khi sửa tiếp.',
            );
          }
          result.remove(key);
        } else {
          result[key as String] = merge(
            old[key],
            local[key],
            remote[key],
            remoteOld[key],
          );
        }
      }
      return result;
    }
    if (cloudFingerprint(remote) == cloudFingerprint(remoteOld) ||
        cloudFingerprint(remote) == cloudFingerprint(local)) {
      return local;
    }
    throw StateError(
      'Dữ liệu đã thay đổi trên thiết bị khác. Tải lại trước khi sửa tiếp.',
    );
  }

  return Map<String, dynamic>.from(
    merge(before, edited, live, serverBefore ?? before) as Map,
  );
}
