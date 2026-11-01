import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// The persistence boundary. Cloud repositories can implement the same API.
abstract interface class RentalRepository {
  Future<Map<String, Map<String, dynamic>>> readAll();
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents);
  Future<void> close();
}

class SqliteRentalRepository implements RentalRepository {
  SqliteRentalRepository._(this.database);
  final Database database;

  static Future<SqliteRentalRepository> open({
    DatabaseFactory? factory,
    String? path,
    String filename = 'quanlytro_v1.db',
  }) async {
    final selectedFactory = factory ?? _platformFactory();
    final databasePath =
        path ??
        paths.join(
          await selectedFactory.getDatabasesPath(),
          paths.basename(filename),
        );
    final database = await selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE app_documents (id TEXT PRIMARY KEY, payload TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
        },
      ),
    );
    return SqliteRentalRepository._(database);
  }

  static DatabaseFactory _platformFactory() {
    if (kIsWeb) {
      throw UnsupportedError(
        'Bản SQLite hiện hỗ trợ Android, iOS và máy tính.',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      ffi.sqfliteFfiInit();
      return ffi.databaseFactoryFfi;
    }
    return databaseFactory;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async => {
    for (final row in await database.query('app_documents'))
      row['id'] as String: Map<String, dynamic>.from(
        jsonDecode(row['payload'] as String) as Map,
      ),
  };

  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {
    // Encode before opening the transaction; a codec failure cannot partially save.
    final encoded = documents.map(
      (key, value) => MapEntry(key, jsonEncode(value)),
    );
    await database.transaction((txn) async {
      final batch = txn.batch();
      final timestamp = DateTime.now().toUtc().toIso8601String();
      for (final entry in encoded.entries) {
        batch.insert('app_documents', {
          'id': entry.key,
          'payload': entry.value,
          'updated_at': timestamp,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> close() => database.close();
}
