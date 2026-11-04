import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

import 'local_database.dart';
import 'rental_cloud_codec.dart';

/// Cloud Firestore implementation of [RentalRepository].
/// Saves application documents in the 'app_documents' collection.
class FirestoreRentalRepository implements RentalRepository {
  FirestoreRentalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _roomHashes = <String, String>{};
  static const String collectionName = 'app_documents';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async {
    try {
      final snapshot = await _collection.get();
      final result = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        if (doc.id == 'admin_demo' || doc.id.startsWith('admin_demo:')) {
          continue;
        }
        final data = doc.data();
        if (data.containsKey('payload') && data['payload'] is String) {
          try {
            result[doc.id] = Map<String, dynamic>.from(
              jsonDecode(data['payload'] as String) as Map,
            );
          } catch (_) {
            result[doc.id] = data;
          }
        } else {
          result[doc.id] = data;
        }
      }
      final manifest = result.remove('catalog_manifest');
      if (manifest != null) {
        _roomHashes.addAll(Map<String, String>.from(manifest));
      }
      return result;
    } catch (e) {
      debugPrint('Firestore readAll error: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    try {
      final batch = _firestore.batch();
      for (final entry in documents.entries) {
        final docRef = _collection.doc(entry.key);
        final docData = <String, dynamic>{
          'id': entry.key,
          'payload': jsonEncode(entry.value),
          'updated_at': DateTime.now().toIso8601String(),
        };
        batch.set(docRef, docData, SetOptions(merge: true));
      }
      await batch.commit();
      if (documents['portfolio'] != null) {
        final owners = {
          for (final store in documents['portfolio']!['properties'] as List)
            (store['property'] as Map)['id'] as String: 'legacy-demo',
        };
        final public = encodeCloudDocuments(documents, owners: owners)
          ..removeWhere((path, _) => !path.startsWith('public_rooms/'));
        final hashes = {
          for (final entry in public.entries)
            entry.key: sha256
                .convert(utf8.encode(cloudFingerprint(entry.value)))
                .toString(),
        };
        final changed = public.entries
            .where((e) => _roomHashes[e.key] != hashes[e.key])
            .toList();
        for (var index = 0; index < changed.length; index += 100) {
          final publish = _firestore.batch();
          for (final row in changed.skip(index).take(100)) {
            publish.set(_firestore.doc(row.key), row.value);
          }
          await publish.commit();
        }
        // Phòng đã xóa không được tiếp tục hiện trong kết quả tìm kiếm online.
        final removed = _roomHashes.keys
            .where((path) => !hashes.containsKey(path))
            .toList();
        for (var index = 0; index < removed.length; index += 100) {
          final hide = _firestore.batch();
          for (final path in removed.skip(index).take(100)) {
            hide.update(_firestore.doc(path), {
              'published': false,
              'available': false,
            });
          }
          await hide.commit();
        }
        if (changed.isNotEmpty || removed.isNotEmpty) {
          await _collection.doc('catalog_manifest').set({
            'payload': jsonEncode(hashes),
          });
          _roomHashes
            ..clear()
            ..addAll(hashes);
        }
      }
    } catch (e) {
      debugPrint('Firestore saveAll error: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {}
}

/// Hybrid repository that saves locally to SQLite first (ensuring zero latency
/// and offline support) and synchronizes with Firebase Cloud Firestore in the background.
class HybridRentalRepository implements RentalRepository {
  HybridRentalRepository({
    required this.local,
    required this.remote,
    this.isOnline = true,
    this.strictRemote = false,
  });

  final RentalRepository local;
  final RentalRepository remote;
  bool isOnline;
  final bool strictRemote;
  bool lastSaveReachedRemote = false;

  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async {
    final localData = await local.readAll();
    if (!isOnline) return localData;

    try {
      final remoteData = {...await remote.readAll()}..remove('adminDemo');
      if (remoteData.isNotEmpty) {
        // Update local with remote data
        await local.saveAll(remoteData);
        return remoteData;
      } else if (localData.isNotEmpty) {
        // Push initial local data to remote
        await remote.saveAll({...localData}..remove('adminDemo'));
      }
    } catch (e) {
      if (strictRemote) rethrow;
      debugPrint('Sync remote to local warning: $e');
    }
    return localData;
  }

  @override
  Future<void> saveAll(
    Map<String, Map<String, dynamic>> documents, {
    bool requireRemote = false,
  }) async {
    // Always save locally first for instant UI response and persistence
    lastSaveReachedRemote = false;
    await local.saveAll(documents);

    // Sync to remote in background if connected
    if (isOnline) {
      try {
        await remote
            .saveAll({...documents}..remove('adminDemo'))
            .timeout(const Duration(seconds: 20));
        lastSaveReachedRemote = true;
      } catch (e) {
        if (strictRemote || requireRemote) rethrow;
        debugPrint('Sync to Firestore background error: $e');
      }
    } else if (requireRemote) {
      throw StateError('Firebase chưa kết nối. Dữ liệu đã được giữ trên máy.');
    }
  }

  @override
  Future<void> close() async {
    await local.close();
    await remote.close();
  }
}
