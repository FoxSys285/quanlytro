import 'package:flutter/material.dart';

import '../../landlord/room_types/models/landlord_room_type.dart';

/// The same room-type photos are used by both rental roles.
class RoomImageGallery extends StatefulWidget {
  const RoomImageGallery({super.key, required this.images, this.height = 220});

  final List<RoomTypeImage> images;
  final double height;

  @override
  State<RoomImageGallery> createState() => _RoomImageGalleryState();
}

class _RoomImageGalleryState extends State<RoomImageGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant RoomImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: images.isEmpty
            ? const ColoredBox(
                color: Color(0xFFEDF2F7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 36,
                        color: Colors.blueGrey,
                      ),
                      SizedBox(height: 8),
                      Text('Chưa có ảnh loại phòng'),
                    ],
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => _RoomImageViewer(
                          images: images,
                          initialIndex: index,
                        ),
                      ),
                      child: _photo(images[index], BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_index + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (images.length > 1) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        tooltip: 'Ảnh trước',
                        onPressed: _index == 0
                            ? null
                            : () => _controller.previousPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.filledTonal(
                        tooltip: 'Ảnh tiếp theo',
                        onPressed: _index == images.length - 1
                            ? null
                            : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

Widget _photo(RoomTypeImage image, BoxFit fit) => Image.memory(
  image.bytes,
  fit: fit,
  semanticLabel: image.name,
  errorBuilder: (_, _, _) => const Center(
    child: Text('Không tải được ảnh', style: TextStyle(color: Colors.blueGrey)),
  ),
);

class _RoomImageViewer extends StatefulWidget {
  const _RoomImageViewer({required this.images, required this.initialIndex});
  final List<RoomTypeImage> images;
  final int initialIndex;

  @override
  State<_RoomImageViewer> createState() => _RoomImageViewerState();
}

class _RoomImageViewerState extends State<_RoomImageViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.black,
    child: Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          itemBuilder: (_, i) => InteractiveViewer(
            child: Center(child: _photo(widget.images[i], BoxFit.contain)),
          ),
        ),
        SafeArea(
          child: IconButton(
            tooltip: 'Đóng ảnh',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
