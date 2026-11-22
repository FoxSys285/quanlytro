import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/firebase_media_store.dart';

class PrivateStorageImage extends StatelessWidget {
  const PrivateStorageImage({
    super.key,
    required this.reference,
    required this.height,
    required this.width,
    required this.fit,
  });

  final String reference;
  final double height;
  final double width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (reference.startsWith('http://') || reference.startsWith('https://')) {
      return Image.network(
        reference,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
      );
    }
    return FutureBuilder<Uint8List?>(
      future: FirebaseMediaStore().downloadPrivateAsset(reference),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            width: width,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (bytes == null) {
          return SizedBox(
            height: height,
            width: width,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}
