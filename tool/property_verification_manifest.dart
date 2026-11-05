import 'dart:convert';
import 'dart:io';

import 'package:quanlytro/data/rental_cloud_codec.dart';

/// Use the app's exact canonical JSON/hash algorithm for migration proofs.
void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Expected input documents JSON and output proofs JSON.',
    );
  }
  final documents = Map<String, dynamic>.from(
    jsonDecode(File(args[0]).readAsStringSync()) as Map,
  );
  final proofs = <String, String>{};
  for (final entry in documents.entries) {
    if (!entry.key.startsWith('rental_properties/')) continue;
    final document = Map<String, dynamic>.from(entry.value as Map);
    if (document['data'] is! Map) continue;
    proofs[entry.key] = propertyVerificationProof(
      Map<String, dynamic>.from(document['data'] as Map),
    );
  }
  File(args[1]).writeAsStringSync(jsonEncode(proofs));
  stdout.writeln('PROPERTY_PROOFS_COMPUTED ${proofs.length}');
}
