import 'package:flutter/material.dart';

import 'components/tenant_room_card.dart';
import 'components/tenant_room_details_sheet.dart';
import 'models/tenant_room_listing.dart';
import 'tenant_favorites_store.dart';
import '../tenant_ui.dart';

class TenantFavoritesPage extends StatefulWidget {
  const TenantFavoritesPage({super.key});

  @override
  State<TenantFavoritesPage> createState() => _TenantFavoritesPageState();
}

class _TenantFavoritesPageState extends State<TenantFavoritesPage> {
  String _roomType = 'Tất cả';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final favoriteRooms = TenantRoomDemoData.allListings.where((room) {
      final isFavorite = TenantFavoritesStore.contains(room.name);
      final matchesType = _roomType == 'Tất cả' || room.roomType == _roomType;
      final matchesQuery =
          _query.isEmpty ||
          '${room.name} ${room.address}'.toLowerCase().contains(
            _query.toLowerCase(),
          );
      return isFavorite && matchesType && matchesQuery;
    }).toList();
    final roomTypes = TenantRoomDemoData.allListings
        .where((room) => TenantFavoritesStore.contains(room.name))
        .map((room) => room.roomType)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: tenantCanvas,
      appBar: AppBar(
        backgroundColor: tenantCanvas,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Yêu thích',
          style: TextStyle(color: tenantInk, fontWeight: FontWeight.w800),
        ),
      ),
      body: TenantPageFrame(
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: 'Tìm trong danh sách yêu thích',
              prefixIcon: const Icon(Icons.search_rounded, color: tenantGreen),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: tenantLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: tenantLine),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final type in ['Tất cả', ...roomTypes])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: _roomType == type,
                      onSelected: (_) => setState(() => _roomType = type),
                      selectedColor: tenantGreen.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: _roomType == type ? tenantGreen : tenantLine,
                      ),
                      labelStyle: TextStyle(
                        color: _roomType == type
                            ? tenantGreenDark
                            : tenantMuted,
                        fontSize: 11,
                      ),
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
          TenantSectionHeading(
            '${favoriteRooms.length} chỗ ở đã lưu',
            trailing: favoriteRooms.isEmpty
                ? null
                : TextButton.icon(
                    onPressed: () =>
                        setState(() => TenantFavoritesStore.roomNames.clear()),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Xóa tất cả'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB65050),
                    ),
                  ),
          ),
          if (favoriteRooms.isEmpty)
            const TenantEmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Chưa có chỗ ở phù hợp',
              subtitle: 'Lưu tin bạn quan tâm để xem lại ở đây.',
            )
          else
            for (final room in favoriteRooms) ...[
              TenantRoomCard(
                room: room,
                isFavorite: true,
                onFavoriteToggle: () =>
                    setState(() => TenantFavoritesStore.toggle(room.name)),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => TenantRoomDetailsSheet(
                    room: room,
                    onBook: () => showTenantPreviewNotice(context),
                    isFavorite: TenantFavoritesStore.contains(room.name),
                    onFavoriteToggle: () =>
                        setState(() => TenantFavoritesStore.toggle(room.name)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}
