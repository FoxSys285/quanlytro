import 'dart:convert';
import 'dart:io';

import 'package:quanlytro/data/rental_cloud_codec.dart';

// Dùng đúng codec của app thay vì duy trì thêm một schema Firestore bằng Python.
void main(List<String> args) {
  if (args.length != 2) throw ArgumentError('Cần input.json output.json');
  final input = jsonDecode(File(args[0]).readAsStringSync()) as Map;
  final snapshot = (input['snapshot'] as Map).map(
    (key, value) =>
        MapEntry(key as String, Map<String, dynamic>.from(value as Map)),
  );
  final encoded = encodeCloudDocuments(
    snapshot,
    owners: Map<String, String>.from(input['owners'] as Map),
  );
  File(args[1]).writeAsStringSync(jsonEncode(encoded));
  stdout.writeln('CLOUD_DOCUMENTS_EXPORTED: ${encoded.length}');
}
