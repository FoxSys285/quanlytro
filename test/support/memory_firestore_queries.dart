// Test doubles intentionally implement the Firestore SDK's sealed interfaces.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Json = Map<String, dynamic>;

class MemoryRead {
  MemoryRead(this.collection, this.filters, this.limit, this.count);
  final String collection;
  final Map<String, Object?> filters;
  final int? limit;
  final int count;
}

/// Small query fake which measures the documents returned by actual repository
/// calls. It implements only the Firestore surface exercised by these tests.
class MemoryFirestore extends Fake implements FirebaseFirestore {
  MemoryFirestore(this.documents);
  final Map<String, Map<String, Json>> documents;
  final reads = <MemoryRead>[];
  int get documentsRead => reads.fold(0, (total, read) => total + read.count);
  final writes = <String>[];

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async => transactionHandler(_Transaction(this));

  @override
  CollectionReference<Json> collection(String path) => _Collection(this, path);
  @override
  DocumentReference<Json> doc(String path) => _Reference(this, path);
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final MemoryFirestore db;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async => (await db.doc(reference.path).get()) as DocumentSnapshot<T>;
  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    final parts = reference.path.split('/');
    db.documents.putIfAbsent(parts.first, () => {})[parts.last] =
        Map<String, dynamic>.from(data as Map);
    db.writes.add(reference.path);
    return this;
  }
}

class _Query extends Fake implements Query<Json> {
  _Query(
    this.db,
    this.path, {
    this.filters = const {},
    this.predicates = const [],
    this.order = '__name__',
    this.descending = false,
    this.pageLimit,
    this.cursor,
  });
  final MemoryFirestore db;
  final String path;
  final Map<String, Object?> filters;
  final List<bool Function(String, Json)> predicates;
  final String order;
  final bool descending;
  final int? pageLimit;
  final String? cursor;

  _Query _copy({
    Map<String, Object?>? filters,
    List<bool Function(String, Json)>? predicates,
    String? order,
    bool? descending,
    int? limit,
    String? cursor,
  }) => _Query(
    db,
    path,
    filters: filters ?? this.filters,
    predicates: predicates ?? this.predicates,
    order: order ?? this.order,
    descending: descending ?? this.descending,
    pageLimit: limit ?? pageLimit,
    cursor: cursor ?? this.cursor,
  );

  @override
  Query<Json> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    final key = field is String ? field : '__name__';
    return _copy(
      filters: {...filters, key: whereIn ?? arrayContains ?? isEqualTo},
      predicates: [
        ...predicates,
        (id, row) {
          final value = key == '__name__' ? id : row[key];
          if (whereIn != null) return whereIn.contains(value);
          if (arrayContains != null) {
            return (value as List? ?? []).contains(arrayContains);
          }
          return value == isEqualTo;
        },
      ],
    );
  }

  @override
  Query<Json> orderBy(Object field, {bool descending = false}) => _copy(
    order: field is String ? field : '__name__',
    descending: descending,
  );
  @override
  Query<Json> limit(int limit) => _copy(limit: limit);
  @override
  Query<Json> startAfterDocument(DocumentSnapshot documentSnapshot) =>
      _copy(cursor: documentSnapshot.id);
  @override
  Future<QuerySnapshot<Json>> get([GetOptions? options]) async {
    var rows = (db.documents[path] ?? {}).entries
        .where(
          (row) =>
              predicates.every((predicate) => predicate(row.key, row.value)),
        )
        .toList();
    rows.sort((a, b) {
      final dynamic left = order == '__name__' ? a.key : a.value[order];
      final dynamic right = order == '__name__' ? b.key : b.value[order];
      final result = (left as Comparable).compareTo(right);
      final comparison = result == 0 ? a.key.compareTo(b.key) : result;
      return descending ? -comparison : comparison;
    });
    if (cursor != null) {
      final index = rows.indexWhere((row) => row.key == cursor);
      rows = rows.skip(index + 1).toList();
    }
    rows = rows.take(pageLimit ?? rows.length).toList();
    db.reads.add(MemoryRead(path, filters, pageLimit, rows.length));
    return _Snapshot(
      rows.map((row) => _Document(db, '$path/${row.key}', row.value)).toList(),
    );
  }
}

class _Collection extends _Query implements CollectionReference<Json> {
  _Collection(super.db, super.path);
  @override
  DocumentReference<Json> doc([String? path]) =>
      _Reference(db, '${this.path}/$path');
}

class _Reference extends Fake implements DocumentReference<Json> {
  _Reference(this.db, this.path);
  final MemoryFirestore db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  Future<DocumentSnapshot<Json>> get([GetOptions? options]) async {
    final parts = path.split('/');
    final row = db.documents[parts.first]?[parts.last];
    db.reads.add(
      MemoryRead(parts.first, {'__name__': parts.last}, 1, row == null ? 0 : 1),
    );
    return row == null ? _MissingDocument() : _Document(db, path, row);
  }
}

class _Snapshot extends Fake implements QuerySnapshot<Json> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Json>> docs;
}

class _Document extends Fake implements QueryDocumentSnapshot<Json> {
  _Document(this.db, this.path, this.row);
  final MemoryFirestore db;
  final String path;
  final Json row;
  @override
  String get id => path.split('/').last;
  @override
  Json data() => row;
  @override
  bool get exists => true;
  @override
  DocumentReference<Json> get reference => _Reference(db, path);
}

class _MissingDocument extends Fake implements DocumentSnapshot<Json> {
  @override
  Json? data() => null;
  @override
  bool get exists => false;
}
