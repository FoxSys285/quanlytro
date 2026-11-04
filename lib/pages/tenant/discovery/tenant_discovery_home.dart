import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tenant_ui.dart';
import '../../shared/media/room_photo_gallery.dart';
import '../../shared/widgets/list_pagination.dart';
import 'components/tenant_room_card.dart';
import 'models/tenant_room_listing.dart';
import 'tenant_favorites_store.dart';

class TenantDiscoveryHome extends StatelessWidget {
  const TenantDiscoveryHome({
    super.key,
    required this.resultsOnly,
    required this.localRooms,
    required this.visibleRooms,
    required this.remote,
    required this.loading,
    required this.hasError,
    required this.offline,
    required this.query,
    required this.sort,
    required this.selectedCity,
    required this.searchController,
    required this.activeFilterCount,
    required this.currentPage,
    required this.localPage,
    required this.pageSize,
    required this.remoteHasNext,
    required this.activeFilters,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilter,
    required this.onOpenSearch,
    required this.onFavorites,
    required this.onFavoriteToggle,
    required this.onRoomTap,
    required this.onSelectArea,
    required this.onSortChanged,
    required this.onLocalPageChanged,
    required this.onRemotePrevious,
    required this.onRemoteNext,
    required this.onRetry,
    required this.onUseOffline,
    required this.onReloadOnline,
    required this.onNearby,
    required this.onDeals,
  });

  final bool resultsOnly;
  final List<TenantRoomListing> localRooms;
  final List<TenantRoomListing> visibleRooms;
  final bool remote;
  final bool loading;
  final bool hasError;
  final bool offline;
  final String query;
  final String sort;
  final String? selectedCity;
  final TextEditingController searchController;
  final int activeFilterCount;
  final int currentPage;
  final int localPage;
  final int pageSize;
  final bool remoteHasNext;
  final Widget? activeFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilter;
  final VoidCallback onOpenSearch;
  final VoidCallback onFavorites;
  final ValueChanged<TenantRoomListing> onFavoriteToggle;
  final ValueChanged<TenantRoomListing> onRoomTap;
  final ValueChanged<TenantRoomListing> onSelectArea;
  final ValueChanged<String?> onSortChanged;
  final ValueChanged<int> onLocalPageChanged;
  final VoidCallback onRemotePrevious;
  final VoidCallback onRemoteNext;
  final VoidCallback onRetry;
  final VoidCallback onUseOffline;
  final VoidCallback onReloadOnline;
  final VoidCallback onNearby;
  final VoidCallback onDeals;

  @override
  Widget build(BuildContext context) {
    if (resultsOnly) return _resultsPage(context);

    final homeRooms = remote
        ? visibleRooms
        : (visibleRooms.isNotEmpty
              ? visibleRooms
              : localRooms.take(8).toList());
    final goodPriceRooms = [...homeRooms]
      ..sort((a, b) => a.price.compareTo(b.price));
    final nearbyRooms = [...homeRooms]
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    final trustedListings = homeRooms
        .where((room) => room.ownerPropertyId != null || room.roomCode != null)
        .toList();
    final trustedRooms = trustedListings.isEmpty ? homeRooms : trustedListings;
    final areas = <String, List<TenantRoomListing>>{};
    for (final room in homeRooms) {
      final name = room.ward.isNotEmpty ? room.ward : room.city;
      if (name.isNotEmpty) areas.putIfAbsent(name, () => []).add(room);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: const Color(0xFFFCFCFC),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(context),
              SizedBox(
                height: 37,
                child: Transform.translate(
                  offset: const Offset(0, -29),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _searchBar(context),
                  ),
                ),
              ),
              if (activeFilters != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 7, 18, 2),
                  child: activeFilters!,
                ),
              if (remote && loading)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang cập nhật tin đăng...',
                        style: TextStyle(color: tenantMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _quickCategories(context),
              ),
              const SizedBox(height: 21),
              _sectionHeading(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF04F3E),
                title: 'Nhà trọ nổi bật',
                onSeeAll: onOpenSearch,
              ),
              const SizedBox(height: 11),
              _roomCarousel(context, homeRooms, badge: '🔥 Hot'),
              const SizedBox(height: 22),
              _sectionHeading(
                icon: Icons.sell_rounded,
                color: const Color(0xFF08A94F),
                title: 'NHÀ TRỌ GIÁ TỐT',
                onSeeAll: onOpenSearch,
              ),
              const SizedBox(height: 11),
              _roomCarousel(
                context,
                goodPriceRooms.take(6).toList(),
                badge: 'Giá tốt',
              ),
              const SizedBox(height: 22),
              _sectionHeading(
                icon: Icons.map_rounded,
                color: const Color(0xFF315F55),
                title: 'Khám phá theo khu vực',
                onSeeAll: onOpenSearch,
              ),
              const SizedBox(height: 11),
              _areaCarousel(areas),
              const SizedBox(height: 22),
              _sectionHeading(
                icon: Icons.verified_user_rounded,
                color: const Color(0xFF0B8950),
                title: 'NHÀ TRỌ ĐÁNG TIN CẬY',
                onSeeAll: onOpenSearch,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(19, 3, 18, 10),
                child: Text(
                  'Tin đăng có thông tin chủ trọ và tiện ích rõ ràng',
                  style: TextStyle(color: tenantMuted, fontSize: 10),
                ),
              ),
              _roomCarousel(
                context,
                trustedRooms.take(6).toList(),
                badge: '✓ Tin rõ ràng',
              ),
              const SizedBox(height: 22),
              _sectionHeading(
                icon: Icons.location_on_rounded,
                color: const Color(0xFF315F55),
                title: 'Nhà trọ gần bạn',
                onSeeAll: onOpenSearch,
              ),
              const SizedBox(height: 11),
              _roomCarousel(
                context,
                nearbyRooms.take(6).toList(),
                compact: true,
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _safetyBanner(context),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultsPage(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: const Color(0xFFFCFCFC),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12, topInset + 5, 18, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Quay lại khám phá',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Danh sách phòng trọ',
                        style: TextStyle(
                          color: Color(0xFF202332),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _searchBar(context),
              ),
              if (activeFilters != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 9, 18, 0),
                  child: activeFilters!,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 19, 18, 8),
                child: TenantSectionHeading(
                  'Danh sách phòng',
                  trailing: Text(
                    remote
                        ? 'Trang ${currentPage + 1}'
                        : '${localRooms.length} phòng',
                    style: const TextStyle(color: tenantMuted, fontSize: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DropdownButtonFormField<String>(
                  initialValue: sort,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Sắp xếp danh sách',
                    prefixIcon: const Icon(Icons.sort_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: tenantLine),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Mặc định')),
                    DropdownMenuItem(
                      value: 'rentAsc',
                      child: Text('Giá thuê tăng dần'),
                    ),
                    DropdownMenuItem(
                      value: 'rentDesc',
                      child: Text('Giá thuê giảm dần'),
                    ),
                    DropdownMenuItem(
                      value: 'areaAsc',
                      child: Text('Diện tích tăng dần'),
                    ),
                    DropdownMenuItem(
                      value: 'areaDesc',
                      child: Text('Diện tích giảm dần'),
                    ),
                  ],
                  onChanged: onSortChanged,
                ),
              ),
              const SizedBox(height: 12),
              if (remote && hasError)
                _catalogError()
              else if (remote && loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleRooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: TenantEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Chưa tìm thấy phòng phù hợp',
                    subtitle: 'Thử đổi từ khóa hoặc bộ lọc nhé.',
                  ),
                )
              else
                _roomGrid(context),
              const SizedBox(height: 12),
              if (remote && !loading && !hasError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      tooltip: 'Trang trước',
                      onPressed: currentPage == 0 ? null : onRemotePrevious,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Trang ${currentPage + 1}'),
                    ),
                    IconButton.outlined(
                      tooltip: 'Trang tiếp theo',
                      onPressed: remoteHasNext ? onRemoteNext : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                )
              else if (!remote)
                ListPagination(
                  total: localRooms.length,
                  page: localPage,
                  pageSize: pageSize,
                  onChanged: onLocalPageChanged,
                ),
              if (offline)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      const Text(
                        'Đang xem dữ liệu đã lưu trên thiết bị; tình trạng phòng có thể thay đổi.',
                        style: TextStyle(color: tenantMuted, fontSize: 10),
                      ),
                      TextButton(
                        onPressed: onReloadOnline,
                        child: const Text('Tải lại trực tuyến'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomGrid(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final room in visibleRooms)
              SizedBox(
                width: width,
                child: TenantRoomCard(
                  room: room,
                  isFavorite: TenantFavoritesStore.contains(room.id),
                  onFavoriteToggle: () => onFavoriteToggle(room),
                  onTap: () => onRoomTap(room),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _hero(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 244,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/tenant_discovery_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0, 0.48, 1],
                colors: [
                  Color(0xEAF8FCF9),
                  Color(0xB8F4FAF8),
                  Color(0x18FFFFFF),
                ],
              ),
            ),
          ),
          Positioned(
            top: topInset + 26,
            left: 18,
            right: 18,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.87),
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: onFilter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 19,
                              color: Color(0xFF06A651),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                selectedCity ?? 'TP. Tuy Hòa',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF202332),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF555A66),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Material(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onFavorites,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            color: Color(0xFF08783B),
                            size: 17,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Yêu thích',
                            style: TextStyle(
                              color: Color(0xFF08783B),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Material(
                  color: Colors.white.withValues(alpha: 0.94),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => showTenantPreviewNotice(context),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF202332),
                            size: 23,
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Color(0xFFE43C3C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 80,
            left: 22,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Khám phá\nnhà trọ lý tưởng',
                        style: TextStyle(
                          color: Color(0xFF073B25),
                          fontSize: 30,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.65,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF08A94F),
                      size: 24,
                    ),
                  ],
                ),
                SizedBox(height: 7),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'An cư dễ dàng  –  Cuộc sống an yên',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF113B2B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFF08A94F),
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A102820),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        const SizedBox(width: 13),
        IconButton(
          tooltip: 'Tìm nhà trọ',
          onPressed: resultsOnly ? null : onOpenSearch,
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF5C6070),
            size: 27,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: TextField(
            controller: searchController,
            readOnly: !resultsOnly,
            onTap: resultsOnly ? null : onOpenSearch,
            onChanged: resultsOnly ? onSearchChanged : null,
            style: const TextStyle(color: Color(0xFF222433), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhà trọ, khu vực...',
              hintStyle: const TextStyle(
                color: Color(0xFF9498A2),
                fontSize: 14,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: onSearchClear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Material(
          color: const Color(0xFFE1F4E8),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onFilter,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF073B25),
                    size: 24,
                  ),
                  if (activeFilterCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE7A92D),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          activeFilterCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _quickCategories(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(7, 13, 7, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10101824),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        _quickCategory(
          icon: Icons.home_rounded,
          label: 'Nhà trọ\ngần tôi',
          color: const Color(0xFF08A94F),
          background: const Color(0xFFE1F4E8),
          onTap: onNearby,
        ),
        _quickCategory(
          icon: Icons.map_outlined,
          label: 'Theo khu vực',
          color: const Color(0xFF08A94F),
          background: const Color(0xFFE1F4E8),
          onTap: onFilter,
        ),
        _quickCategory(
          icon: Icons.star_rounded,
          label: 'Ưu đãi hot',
          color: const Color(0xFFFFB600),
          background: const Color(0xFFFFF4D9),
          onTap: onDeals,
        ),
        _quickCategory(
          icon: Icons.grid_view_rounded,
          label: 'Bộ lọc nâng cao',
          color: const Color(0xFF08A94F),
          background: const Color(0xFFE1F4E8),
          onTap: onFilter,
        ),
      ],
    ),
  );

  Widget _quickCategory({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          children: [
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 31,
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202332),
                    fontSize: 10.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sectionHeading({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onSeeAll,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF202332),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
        ),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Color(0xFF08783B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF08783B),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _roomCarousel(
    BuildContext context,
    List<TenantRoomListing> rooms, {
    bool compact = false,
    String? badge,
  }) {
    final width = compact
        ? 150.0
        : (MediaQuery.sizeOf(context).width - 48) * 0.49;
    return SizedBox(
      height: compact ? 190 : 230,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _roomCard(
          context,
          rooms[index],
          width: width,
          compact: compact,
          badge: badge,
        ),
      ),
    );
  }

  Widget _roomCard(
    BuildContext context,
    TenantRoomListing room, {
    required double width,
    required bool compact,
    String? badge,
  }) {
    final photos = room.gallery;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10101824),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onRoomTap(room),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: compact ? 101 : 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photos.isEmpty)
                        const ColoredBox(color: Color(0xFFE8EFEB))
                      else
                        RoomPhotoImage(
                          photo: photos.first,
                          label: 'Ảnh phòng ${room.name}',
                        ),
                      if (!compact && badge != null)
                        Positioned(
                          top: 9,
                          left: 9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF079B4D),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.22),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onFavoriteToggle(room),
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(
                                TenantFavoritesStore.contains(room.id)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!compact)
                        Positioned(
                          left: 8,
                          bottom: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF079B4D),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              '${formatTenantMoney(room.price).replaceAll(' ', '')}/tháng',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 9 : 10,
                    compact ? 8 : 9,
                    compact ? 9 : 10,
                    compact ? 8 : 9,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF202332),
                          fontSize: compact ? 11 : 12,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF079B4D),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              room.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF676B78),
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.square_foot_rounded,
                              color: Color(0xFF777B86),
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              room.size,
                              style: const TextStyle(
                                color: Color(0xFF777B86),
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.meeting_room_outlined,
                              color: Color(0xFF777B86),
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                room.roomType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF777B86),
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _areaCarousel(Map<String, List<TenantRoomListing>> areas) {
    if (areas.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: areas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = areas.entries.elementAt(index);
          final room = entry.value.first;
          return Material(
            color: const Color(0xFFE7F5EC),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelectArea(room),
              child: SizedBox(
                width: 150,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF078843),
                        size: 20,
                      ),
                      const Spacer(),
                      Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF173E2A),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${entry.value.length} tin đăng',
                        style: const TextStyle(
                          color: Color(0xFF5F7567),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _catalogError() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: TenantSurface(
      child: Column(
        children: [
          const Text(
            'Không tải được danh sách phòng trực tuyến.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tenantInk, fontWeight: FontWeight.w600),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
              TextButton(
                onPressed: onUseOffline,
                child: const Text('Dùng dữ liệu đã lưu'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _safetyBanner(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFDCF2E4),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF08A94F).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF079B4D),
            size: 32,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thuê nhà an toàn, tiện lợi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF0A3D27),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Nhiều lựa chọn, chính sách bảo vệ người dùng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF52685C), fontSize: 9.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Material(
          color: const Color(0xFF064326),
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => showTenantPreviewNotice(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tìm hiểu thêm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
