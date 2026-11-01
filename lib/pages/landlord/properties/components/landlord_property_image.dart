import 'dart:typed_data';

import 'package:flutter/material.dart';

class LandlordPropertyImage extends StatelessWidget {
  const LandlordPropertyImage({
    super.key,
    this.url = '',
    this.bytes,
    this.height = 240,
    this.semanticLabel = 'Ảnh nhà trọ',
  });
  final String url;
  final Uint8List? bytes;
  final double height;
  final String semanticLabel;

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
              semanticLabel: semanticLabel,
              errorBuilder: (_, _, _) => _placeholder(failed: true),
            )
          : url.startsWith('assets/')
          ? Image.asset(
              url,
              fit: BoxFit.cover,
              semanticLabel: semanticLabel,
              errorBuilder: (_, _, _) => _placeholder(failed: true),
            )
          : url.isEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/room_types/interior.webp',
                  fit: BoxFit.cover,
                  semanticLabel: 'Nội thất phòng · ảnh minh họa',
                  errorBuilder: (_, _, _) => _placeholder(),
                ),
                const Positioned(
                  bottom: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Text(
                        'Ảnh minh họa',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Image.network(
              url,
              semanticLabel: semanticLabel,
              fit: BoxFit.cover,
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
        Icon(
          Icons.apartment_rounded,
          size: height < 180 ? 48 : 100,
          color: Color(0xFF3769D6),
        ),
        const SizedBox(height: 12),
        Text(
          failed ? 'Không tải được ảnh nhà trọ' : 'Ảnh minh họa nhà trọ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (height >= 180) const SizedBox(height: 6),
        if (height >= 180)
          const Text(
            'Thêm hoặc đổi ảnh trong phần chỉnh sửa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
      ],
    ),
  );
}
