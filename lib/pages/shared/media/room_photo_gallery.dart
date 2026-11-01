import 'package:flutter/material.dart';

import 'room_photo.dart';

class RoomPhotoImage extends StatelessWidget {
  const RoomPhotoImage({
    super.key,
    required this.photo,
    this.label = 'Ảnh phòng',
    this.fit = BoxFit.cover,
  });
  final RoomPhoto photo;
  final String label;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget failed(BuildContext context, Object error, StackTrace? stack) =>
        const RoomPhotoPlaceholder(failed: true);
    if (photo.bytes != null) {
      return Image.memory(
        photo.bytes!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: fit == BoxFit.cover ? 1200 : null,
        semanticLabel: label,
        errorBuilder: failed,
      );
    }
    if (photo.assetPath.isNotEmpty) {
      return Image.asset(
        photo.assetPath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: fit == BoxFit.cover ? 1200 : null,
        semanticLabel: label,
        errorBuilder: failed,
      );
    }
    if (photo.url.isNotEmpty) {
      return Image.network(
        photo.url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: fit == BoxFit.cover ? 1200 : null,
        semanticLabel: label,
        frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
            wasSynchronouslyLoaded || frame != null
            ? child
            : const RoomPhotoPlaceholder(loading: true),
        errorBuilder: failed,
      );
    }
    return const RoomPhotoPlaceholder();
  }
}

class RoomPhotoPlaceholder extends StatelessWidget {
  const RoomPhotoPlaceholder({
    super.key,
    this.failed = false,
    this.loading = false,
  });
  final bool failed;
  final bool loading;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFE7EEE9), Color(0xFFD4DFED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          right: -18,
          bottom: -24,
          child: Icon(
            Icons.chair_outlined,
            size: 140,
            color: Color(0x30FFFFFF),
          ),
        ),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: failed
                      ? 'Không tải được ảnh'
                      : loading
                      ? 'Đang tải ảnh...'
                      : 'Chưa có ảnh loại phòng',
                  child: Icon(
                    failed
                        ? Icons.broken_image_outlined
                        : loading
                        ? Icons.cloud_download_outlined
                        : Icons.add_photo_alternate_outlined,
                    color: const Color(0xFF698579),
                    size: constraints.maxHeight < 100 ? 24 : 30,
                  ),
                ),
                if (constraints.maxWidth >= 150 &&
                    constraints.maxHeight >= 100) ...[
                  const SizedBox(height: 8),
                  Text(
                    failed
                        ? 'Không tải được ảnh'
                        : loading
                        ? 'Đang tải ảnh...'
                        : 'Chưa có ảnh loại phòng',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4B665C),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class RoomPhotoGallery extends StatefulWidget {
  const RoomPhotoGallery({
    super.key,
    required this.photos,
    required this.label,
    this.height = 210,
    this.interactive = false,
    this.onTap,
    this.topLeft,
    this.topRight,
  });
  final List<RoomPhoto> photos;
  final String label;
  final double height;
  final bool interactive;
  final VoidCallback? onTap;
  final Widget? topLeft;
  final Widget? topRight;

  @override
  State<RoomPhotoGallery> createState() => _RoomPhotoGalleryState();
}

class _RoomPhotoGalleryState extends State<RoomPhotoGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(RoomPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.photos, widget.photos)) {
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
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (widget.photos.isEmpty)
          const RoomPhotoPlaceholder()
        else
          GestureDetector(
            onTap:
                widget.onTap ??
                (widget.interactive
                    ? () => showRoomPhotoViewer(
                        context,
                        photos: widget.photos,
                        title: widget.label,
                        initialIndex: _index,
                      )
                    : null),
            child: widget.interactive
                ? PageView.builder(
                    controller: _controller,
                    itemCount: widget.photos.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (_, index) => RoomPhotoImage(
                      photo: widget.photos[index],
                      label: '${widget.label}, ảnh ${index + 1}',
                    ),
                  )
                : RoomPhotoImage(
                    photo: widget.photos.first,
                    label: widget.label,
                  ),
          ),
        if (widget.photos.isNotEmpty)
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .5, 1],
                  colors: [
                    Color(0x20000000),
                    Colors.transparent,
                    Color(0x55000000),
                  ],
                ),
              ),
            ),
          ),
        if (widget.topLeft != null)
          Positioned(top: 12, left: 12, child: widget.topLeft!),
        if (widget.topRight != null)
          Positioned(top: 8, right: 8, child: widget.topRight!),
        if (widget.photos.isNotEmpty &&
            widget
                .photos[_index.clamp(0, widget.photos.length - 1)]
                .isIllustration)
          const Positioned(
            bottom: 12,
            left: 14,
            child: Text(
              'Ảnh minh họa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        if (widget.photos.isNotEmpty)
          Positioned(
            bottom: 10,
            right: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x80000000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.interactive
                          ? '${_index + 1}/${widget.photos.length}'
                          : '${widget.photos.length} ảnh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.interactive && widget.photos.length > 1) ...[
          if (_index > 0)
            Positioned(
              left: 4,
              top: widget.height / 2 - 24,
              child: IconButton.filledTonal(
                tooltip: 'Ảnh trước',
                onPressed: () => _controller.previousPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
          if (_index < widget.photos.length - 1)
            Positioned(
              right: 4,
              top: widget.height / 2 - 24,
              child: IconButton.filledTonal(
                tooltip: 'Ảnh tiếp theo',
                onPressed: () => _controller.nextPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
        ],
      ],
    ),
  );
}

Future<void> showRoomPhotoViewer(
  BuildContext context, {
  required List<RoomPhoto> photos,
  required String title,
  int initialIndex = 0,
}) async {
  if (photos.isEmpty) return;
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => _RoomPhotoViewer(
        photos: photos,
        title: title,
        initialIndex: initialIndex,
      ),
    ),
  );
}

class _RoomPhotoViewer extends StatefulWidget {
  const _RoomPhotoViewer({
    required this.photos,
    required this.title,
    required this.initialIndex,
  });
  final List<RoomPhoto> photos;
  final String title;
  final int initialIndex;
  @override
  State<_RoomPhotoViewer> createState() => _RoomPhotoViewerState();
}

class _RoomPhotoViewerState extends State<_RoomPhotoViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF101B20),
    appBar: AppBar(
      backgroundColor: const Color(0xFF101B20),
      foregroundColor: Colors.white,
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Center(child: Text('${_index + 1}/${widget.photos.length}')),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (_, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: RoomPhotoImage(
                  photo: widget.photos[index],
                  label: '${widget.title}, ảnh ${index + 1}',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (widget.photos[_index].isIllustration)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Ảnh minh họa loại phòng',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Ảnh trước',
                color: Colors.white,
                onPressed: _index == 0
                    ? null
                    : () => _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
              const Expanded(
                child: Text(
                  'Vuốt để xem · Chụm để phóng to',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'Ảnh tiếp theo',
                color: Colors.white,
                onPressed: _index == widget.photos.length - 1
                    ? null
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
