import 'package:flutter/material.dart';

import '../landlord_theme.dart';
import '../landlord_glass.dart';
import '../landlord_ui.dart';

import 'components/room_type_editor.dart';
import '../../shared/media/room_photo_gallery.dart';

import '../landlord_demo_store.dart';
import '../services/models/landlord_service.dart';
import 'models/landlord_room_type.dart';
import '../properties/services/property_image_picker.dart';
import '../../shared/media/room_photo.dart';
import 'services/room_type_photo_picker.dart';

class LandlordRoomTypesPage extends StatelessWidget {
  const LandlordRoomTypesPage({
    super.key,
    this.store,
    this.imagePicker,
    this.embedded = false,
  });
  final bool embedded;
  final Future<SelectedPropertyImage?> Function()? imagePicker;
  final LandlordDemoStore? store;
  LandlordDemoStore get _store => store ?? LandlordDemoStore.activeInstance;

  Future<void> _edit(BuildContext context, [LandlordRoomType? type]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => RoomTypeEditor(
        store: _store,
        type: type,
        pickPhotos: imagePicker == null
            ? pickRoomTypePhotos
            : (_) async {
                final selected = await imagePicker!();
                return selected == null
                    ? []
                    : [RoomPhoto(name: selected.name, bytes: selected.bytes)];
              },
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == null ? 'Đã lưu loại phòng.' : 'Đã cập nhật loại phòng.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, LandlordRoomType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa loại phòng'),
        content: Text('Xóa loại phòng “${type.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text('Xóa'),
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

  Widget _frame(List<Widget> children) => embedded
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        )
      : LandlordGlassPage(
          title: 'Loại phòng',
          subtitle: _store.property.name,
          kicker: 'QUẢN LÝ LOẠI PHÒNG',
          store: _store,
          children: children,
        );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => _frame([
      LandlordGlassSection(
        title: 'Loại phòng',
        subtitle:
            '${_store.roomTypes.length} loại phòng · ${_store.catalog.length} phòng đang quản lý',
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => _edit(context),
          style: FilledButton.styleFrom(
            backgroundColor: propertyBlue,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm loại phòng'),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Chạm vào ảnh để xem album. Chỉnh sửa để thêm ảnh và chọn ảnh bìa.',
        style: TextStyle(
          color: LandlordPalette.of(context).muted,
          fontSize: 12,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 16),
      if (_store.roomTypes.isEmpty)
        const LandlordGlassCard(child: Text('Chưa có loại phòng.')),
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
    ]),
  );

  Widget _typeCard(BuildContext context, LandlordRoomType type) {
    final roomCount = _store.catalog
        .where((room) => room.roomTypeId == type.id)
        .length;
    final services = type.serviceIds
        .map(_store.serviceRecordById)
        .whereType<LandlordService>()
        .toList();
    return Container(
      key: ValueKey(type.id),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LandlordPalette.of(context).surface.withValues(alpha: 0.95),
            LandlordPalette.of(context).surface.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? LandlordPalette.of(context).line
              : Colors.white,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18577EBA),
            blurRadius: 22,
            offset: Offset(0, 8),
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
                style: TextStyle(
                  color: LandlordPalette.of(context).ink,
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
              style: TextStyle(
                color: LandlordPalette.of(context).ink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatRoomTypePrice(type.monthlyRent),
                    style: TextStyle(
                      color: propertyBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (services.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Dịch vụ: ${services.map((service) => '${service.name} ${formatLandlordMoney(type.servicePrices[service.id] ?? service.price)}/${service.unit}').join(', ')}',
                        style: TextStyle(
                          color: LandlordPalette.of(context).muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _edit(context, type),
                      icon: Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        'Chỉnh sửa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: propertyBlue,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sửa ${type.name}',
                  onPressed: () => _edit(context, type),
                  icon: Icon(
                    Icons.photo_library_outlined,
                    color: LandlordPalette.of(context).muted,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa ${type.name}',
                  onPressed: () => _delete(context, type),
                  icon: Icon(
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
