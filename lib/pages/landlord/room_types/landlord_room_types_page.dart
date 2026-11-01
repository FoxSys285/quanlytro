import 'package:flutter/material.dart';

import 'components/room_type_editor.dart';
import '../landlord_ui.dart';
import '../../shared/media/room_photo_gallery.dart';
import '../../shared/widgets/rental_section_banner.dart';

import '../landlord_demo_store.dart';
import 'models/landlord_room_type.dart';

class LandlordRoomTypesPage extends StatelessWidget {
  const LandlordRoomTypesPage({super.key, this.store});
  final LandlordDemoStore? store;
  LandlordDemoStore get _store => store ?? LandlordDemoStore.activeInstance;

  Future<void> _edit(BuildContext context, [LandlordRoomType? type]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => RoomTypeEditor(store: _store, type: type),
    );
  }

  Future<void> _delete(BuildContext context, LandlordRoomType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa loại phòng'),
        content: Text('Xóa loại phòng “${type.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        _store.deleteRoomType(type.id);
      } on ArgumentError catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => LandlordPageFrame(
      children: [
        RentalSectionBanner(
          eyebrow: 'BỘ SƯU TẬP KHÔNG GIAN',
          title: 'Loại phòng',
          subtitle:
              '${_store.property.name} · Mỗi loại phòng, một phong cách riêng.',
          footer: Text(
            '${_store.roomTypes.length} loại phòng  ·  ${_store.catalog.length} phòng đang quản lý',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          action: FilledButton.icon(
            onPressed: () => _edit(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF244C87),
            ),
            icon: const Icon(Icons.add, size: 19),
            label: const Text('Thêm loại phòng'),
          ),
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 19,
              color: landlordBlue,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Không gian của bạn',
                style: TextStyle(
                  color: landlordInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const Text(
          'Chạm vào ảnh để xem album. Chỉnh sửa để thêm ảnh và chọn ảnh bìa.',
          style: TextStyle(color: landlordMuted, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        if (_store.roomTypes.isEmpty)
          const LandlordEmptyState(message: 'Chưa có loại phòng.'),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final type in _store.roomTypes)
                  SizedBox(width: width, child: _typeCard(context, type)),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _typeCard(BuildContext context, LandlordRoomType type) {
    final roomCount = _store.catalog
        .where((room) => room.roomTypeId == type.id)
        .length;
    return Container(
      key: ValueKey(type.id),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: landlordLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07172B42),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoomPhotoGallery(
            photos: type.photos,
            label: type.name,
            height: 170,
            onTap: () => showRoomPhotoViewer(
              context,
              photos: type.photos,
              title: type.name,
            ),
            topLeft: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$roomCount phòng',
                style: const TextStyle(
                  color: landlordInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            title: Text(
              type.name,
              style: const TextStyle(
                color: landlordInk,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                formatRoomTypePrice(type.monthlyRent),
                style: const TextStyle(
                  color: landlordBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _edit(context, type),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Chỉnh sửa'),
                  style: TextButton.styleFrom(foregroundColor: landlordBlue),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Sửa ${type.name}',
                  onPressed: () => _edit(context, type),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: landlordMuted,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa ${type.name}',
                  onPressed: () => _delete(context, type),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFB6656C),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
