import '../../shared/profile/account_store.dart';
import '../../../layouts/role_layout.dart';
import '../../../data/admin_store.dart';

import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';

import 'components/tenant_room_card.dart';
import 'components/tenant_room_details_page.dart';
import 'models/tenant_room_listing.dart';
import 'tenant_favorites_store.dart';
import '../tenant_ui.dart';
import '../tenant_feature_ui.dart';
import '../tenant_detail_ui.dart';
import '../../shared/viewings/viewing_store.dart';
import '../viewings/components/tenant_viewing_request_sheet.dart';
import '../viewings/models/tenant_viewing_request.dart';

class TenantFavoritesPage extends StatefulWidget {
  const TenantFavoritesPage({super.key});

  @override
  State<TenantFavoritesPage> createState() => _TenantFavoritesPageState();
}

class _TenantFavoritesPageState extends State<TenantFavoritesPage> {
  String _roomType = 'Tất cả';
  String _query = '';

  List<TenantRoomListing> get _knownRooms {
    final roomsById = {
      for (final room in TenantRoomDemoData.allListings) room.id: room,
      for (final room in TenantFavoritesStore.savedListings) room.id: room,
    };
    return roomsById.values.toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    RentalPortfolio.instance.addListener(_refreshListings);
    AdminStore.instance.addListener(_refreshListings);
    TenantFavoritesStore.changes.addListener(_refreshListings);
  }

  void _refreshListings() {
    if (!mounted) return;
    setState(() {
      if (_roomType != 'Tất cả' &&
          !_knownRooms.any(
            (room) =>
                TenantFavoritesStore.contains(room.id) &&
                room.roomType == _roomType,
          )) {
        _roomType = 'Tất cả';
      }
    });
  }

  @override
  void dispose() {
    RentalPortfolio.instance.removeListener(_refreshListings);
    AdminStore.instance.removeListener(_refreshListings);
    TenantFavoritesStore.changes.removeListener(_refreshListings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final knownRooms = _knownRooms;
    final favoriteRooms = knownRooms.where((room) {
      final isFavorite = TenantFavoritesStore.contains(room.id);
      final matchesType = _roomType == 'Tất cả' || room.roomType == _roomType;
      final matchesQuery =
          _query.isEmpty ||
          '${room.name} ${room.address}'.toLowerCase().contains(
            _query.toLowerCase(),
          );
      return isFavorite && matchesType && matchesQuery;
    }).toList();
    final roomTypes = knownRooms
        .where((room) => TenantFavoritesStore.contains(room.id))
        .map((room) => room.roomType)
        .toSet()
        .toList();

    return TenantSubpageScaffold(
      title: 'Yêu thích',
      child: TenantFeatureFrame(
        artwork: TenantFeatureArtwork.favorites,
        title: 'Phòng đã lưu',
        subtitle: 'Giữ lại những chỗ ở bạn yêu thích và đặt lịch khi sẵn sàng.',
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: 'Tìm trong danh sách yêu thích',
              prefixIcon: const Icon(Icons.search_rounded, color: tenantGreen),
              filled: true,
              fillColor: const Color(0xFFF4F9F6),
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
                    onPressed: TenantFavoritesStore.clear,
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
                    setState(() => TenantFavoritesStore.toggle(room.id)),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => TenantRoomDetailsPage(
                      room: room,
                      onBook: () => _openViewingRequest(room),
                      isFavorite: TenantFavoritesStore.contains(room.id),
                      onFavoriteToggle: () => setState(() {
                        TenantFavoritesStore.remember(room);
                        TenantFavoritesStore.toggle(room.id);
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          const SizedBox(height: 10),
          const TenantFeatureBanner(
            icon: Icons.favorite_rounded,
            title: 'Chọn chỗ ở phù hợp với bạn',
            subtitle:
                'Mở tin đã lưu để xem thông tin phòng và gửi yêu cầu đặt lịch.',
          ),
        ],
      ),
    );
  }

  Future<void> _openViewingRequest(TenantRoomListing room) async {
    final request = await showModalBottomSheet<TenantViewingRequest>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TenantViewingRequestSheet(
        room: room,
        initialName:
            LandlordDemoStore.instance
                .currentLeaseForTenant(TenantSession.currentTenantId)
                ?.tenantName ??
            AccountStore.instance.profile(AppRole.tenant).name,
        initialPhone:
            LandlordDemoStore.instance
                .currentLeaseForTenant(TenantSession.currentTenantId)
                ?.phone ??
            AccountStore.instance.profile(AppRole.tenant).phone,
      ),
    );
    if (!mounted || request == null) return;
    try {
      final viewing = ViewingStore.instance.createRequest(
        propertyId: room.propertyId,
        roomId: room.id,
        tenantId: TenantSession.currentTenantId,
        roomName: room.name,
        address: room.address,
        startsAt: request.startsAt,
        customerName: request.customerName,
        phone: request.phone,
        attendeeCount: request.attendeeCount,
        personalNeeds: request.personalNeeds,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi yêu cầu xem ${viewing.roomName}. Chờ chủ trọ xác nhận lịch.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
