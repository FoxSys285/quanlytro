import 'dart:typed_data';

import 'package:flutter/material.dart';

class LandlordPropertyImage extends StatelessWidget {
  const LandlordPropertyImage({
    super.key,
    this.url = '',
    this.bytes,
    this.height = 240,
  });
  final String url;
  final Uint8List? bytes;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: bytes != null
          ? Image.memory(
              bytes!,
              fit: BoxFit.cover,
              semanticLabel: 'Ảnh nhà trọ',
              errorBuilder: (_, _, _) => _placeholder(failed: true),
            )
          : url.isEmpty
          ? _placeholder()
          : Image.network(
              url,
              fit: BoxFit.cover,
              semanticLabel: 'Ảnh nhà trọ',
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, _, _) => _placeholder(failed: true),
            ),
    ),
  );

  Widget _placeholder({bool failed = false}) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFDCE8FC), Color(0xFFB7D2E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.apartment_rounded,
          size: 100,
          color: Color(0xFF3769D6),
        ),
        const SizedBox(height: 12),
        Text(
          failed ? 'Không tải được ảnh nhà trọ' : 'Ảnh minh họa nhà trọ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Thêm hoặc đổi ảnh trong phần chỉnh sửa.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
