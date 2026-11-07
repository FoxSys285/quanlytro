import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/admin_store.dart';
import '../../../data/discovery_catalog.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../shared/conversations/conversation_store.dart';
import '../../shared/viewings/models/room_viewing.dart';
import '../../shared/viewings/viewing_store.dart';
import '../tenant_ui.dart';
import 'components/tenant_area_picker_page.dart';
import '../../shared/media/room_photo_gallery.dart';
import '../../shared/widgets/list_pagination.dart';
import 'components/tenant_room_card.dart';
import 'models/tenant_room_listing.dart';
import 'services/tenant_location_service.dart';
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
    required this.profileName,
    required this.tenantId,
    required this.query,
    required this.sort,
    required this.searchController,
    required this.activeFilterCount,
    required this.currentPage,
    required this.localPage,
    required this.pageSize,
    required this.remoteHasNext,
    required this.activeFilters,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onSearchSubmitted,
    required this.onFilter,
    required this.onPickArea,
    required this.onAreaSelected,
    required this.onOpenSearch,
    required this.onFavorites,
    required this.onSettings,
    required this.onFavoriteToggle,
    required this.onRoomTap,
    required this.onSortChanged,
    required this.onLocalPageChanged,
    required this.onRemotePrevious,
    required this.onRemoteNext,
    required this.onRetry,
    required this.onUseOffline,
    required this.onReloadOnline,
    required this.onNearby,
    required this.onProperties,
    required this.onVerifiedProperties,
    required this.onMyLease,
    required this.onInvoices,
    required this.onViewings,
    required this.onConversations,
    this.locationService = const TenantLocationService(),
    this.homeFeed,
    this.onRefresh,
    this.onGoodPrice,
  });

  final bool resultsOnly;
  final List<TenantRoomListing> localRooms;
  final List<TenantRoomListing> visibleRooms;
  final bool remote;
  final bool loading;
  final bool hasError;
  final bool offline;
  final String profileName;
  final String tenantId;
  final String query;
  final String sort;
  final TextEditingController searchController;
  final int activeFilterCount;
  final int currentPage;
  final int localPage;
  final int pageSize;
  final bool remoteHasNext;
  final Widget? activeFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onFilter;
  final VoidCallback onPickArea;
  final ValueChanged<TenantAreaSelection> onAreaSelected;
  final VoidCallback onOpenSearch;
  final VoidCallback onFavorites;
  final VoidCallback onSettings;
  final ValueChanged<TenantRoomListing> onFavoriteToggle;
  final ValueChanged<TenantRoomListing> onRoomTap;
  final ValueChanged<String?> onSortChanged;
  final ValueChanged<int> onLocalPageChanged;
  final VoidCallback onRemotePrevious;
  final VoidCallback onRemoteNext;
  final VoidCallback onRetry;
  final VoidCallback onUseOffline;
  final VoidCallback onReloadOnline;
  final VoidCallback onNearby;
  final VoidCallback onProperties;
  final VoidCallback onVerifiedProperties;
  final VoidCallback onMyLease;
  final VoidCallback onInvoices;
  final VoidCallback onViewings;
  final VoidCallback onConversations;
  final TenantLocationService locationService;
  final DiscoveryHomeFeed? homeFeed;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onGoodPrice;

  @override
  Widget build(BuildContext context) {
    if (resultsOnly) {
      return TenantPageBackdrop(
        child: SafeArea(top: false, child: _resultsPage(context)),
      );
    }

    final homeRooms = remote
        ? visibleRooms
        : (visibleRooms.isNotEmpty
              ? visibleRooms
              : localRooms.take(10).toList());
    final noListings = remote && !loading && !hasError && homeRooms.isEmpty;
    final goodPriceRooms = [...(homeFeed?.goodPrice ?? homeRooms)]
      ..sort((a, b) => a.price.compareTo(b.price));
    final nearbyRooms = [...homeRooms]
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    final trustedRooms =
        homeFeed?.trusted ??
        homeRooms
            .where((room) => AdminStore.instance.isVerified(room.propertyId))
            .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: TenantPageBackdrop(
        child: RefreshIndicator(
          key: const ValueKey('discovery-pull-to-refresh'),
          color: tenantGreen,
          onRefresh: onRefresh ?? () async {},
          child: SingleChildScrollView(
            key: const PageStorageKey('discovery-home-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(context),
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
                        Expanded(
                          child: Text(
                            'Đang cập nhật tin đăng...',
                            style: TextStyle(color: tenantMuted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _quickCategories(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _TenantQuickOverview(
                    tenantId: tenantId,
                    onMyLease: onMyLease,
                    onInvoices: onInvoices,
                    onViewings: onViewings,
                    onConversations: onConversations,
                  ),
                ),
                if (noListings)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
                    child: TenantEmptyState(
                      icon: Icons.home_work_outlined,
                      title: 'Chưa có nhà trọ nào',
                      subtitle: 'Hiện chưa có nhà trọ được đăng. Vui lòng quay lại sau.',
                    ),
                  ),
                if (!noListings) ...[
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
                    onSeeAll: onGoodPrice ?? onOpenSearch,
                  ),
                  const SizedBox(height: 11),
                  _roomCarousel(
                    context,
                    goodPriceRooms.take(10).toList(),
                    badge: 'Giá tốt',
                  ),
                  const SizedBox(height: 22),
                ],
                _sectionHeading(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF315F55),
                  title: 'V\u1ecb tr\u00ed',
                ),
                const SizedBox(height: 11),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 410,
                    child: TenantAreaPickerPage(
                      embedded: true,
                      onSelected: onAreaSelected,
                      locationService: locationService,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (!noListings) ...[
                  _sectionHeading(
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF0B8950),
                    title: 'NHÀ TRỌ ĐÁNG TIN CẬY',
                    onSeeAll: onVerifiedProperties,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(19, 3, 18, 10),
                    child: Text(
                      'Các nhà trọ đã được xác minh thông tin',
                      style: TextStyle(color: tenantMuted, fontSize: 10),
                    ),
                  ),
                  if (trustedRooms.isNotEmpty)
                    _roomCarousel(
                      context,
                      trustedRooms.take(10).toList(),
                      badge: '✓ Đã xác minh',
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: OutlinedButton.icon(
                        onPressed: onVerifiedProperties,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Khám phá nhà trọ đã xác minh'),
                      ),
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
                    nearbyRooms.take(10).toList(),
                    compact: true,
                  ),
                  const SizedBox(height: 22),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _safetyBanner(context),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultsPage(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TenantHeader(
              profileName: profileName,
              onAvatarTap: () => Navigator.of(context).maybePop(),
              onFavoritesTap: onFavorites,
              onSettingsTap: onSettings,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 18, 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPickArea,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Chọn trên bản đồ'),
                  ),
                  TextButton.icon(
                    onPressed: onNearby,
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Vị trí hiện tại'),
                  ),
                ],
              ),
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: TenantEmptyState(
                  icon: Icons.home_work_outlined,
                  title:
                      remote && query.trim().isEmpty && activeFilterCount == 0
                      ? 'Chưa có nhà trọ nào'
                      : 'Chưa tìm thấy phòng phù hợp',
                  subtitle: remote && remoteHasNext
                      ? 'Xem trang tiếp theo hoặc thay đổi bộ lọc để tiếp tục tìm.'
                      : remote && query.trim().isEmpty && activeFilterCount == 0
                      ? 'Hiện chưa có nhà trọ được đăng. Vui lòng quay lại sau.'
                      : 'Thử đổi từ khóa hoặc bộ lọc nhé.',
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

  Widget _hero(BuildContext context) => SizedBox(
    height: 281,
    width: double.infinity,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 244,
          child: _heroArtwork(context),
        ),
        Positioned(left: 16, right: 16, top: 215, child: _searchBar(context)),
      ],
    ),
  );

  Widget _heroArtwork(BuildContext context) {
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
            top: 0,
            left: 0,
            right: 0,
            child: TenantHeader(
              profileName: profileName,
              onAvatarTap: () => Scaffold.maybeOf(context)?.openDrawer(),
              onFavoritesTap: onFavorites,
              onSettingsTap: onSettings,
              overlay: true,
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
    height: 46,
    padding: const EdgeInsets.all(4),
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
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Tìm nhà trọ',
          onPressed: onSearchSubmitted,
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF5C6070),
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            onSubmitted: (_) => onSearchSubmitted(),
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Color(0xFF222433), fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhà trọ, khu vực...',
              hintStyle: const TextStyle(
                color: Color(0xFF9498A2),
                fontSize: 11,
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
        const SizedBox(width: 3),
        Material(
          key: ValueKey(resultsOnly ? 'rental-list-filter' : 'explore-filter'),
          color: const Color(0xFFE1F4E8),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onFilter,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF073B25),
                    size: 20,
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
          id: 'rooms',
          icon: Icons.home_rounded,
          label: 'Danh sách\nphòng trọ',
          color: const Color(0xFF08A94F),
          background: const Color(0xFFE1F4E8),
          onTap: onOpenSearch,
        ),
        _quickCategory(
          id: 'properties',
          icon: Icons.apartment_rounded,
          label: 'Danh sách\nnhà trọ',
          color: const Color(0xFF08A94F),
          background: const Color(0xFFE1F4E8),
          onTap: onProperties,
        ),
        _quickCategory(
          id: 'verified',
          icon: Icons.verified_user_rounded,
          label: 'Nhà trọ\nđáng tin cậy',
          color: const Color(0xFF08783B),
          background: const Color(0xFFE1F4E8),
          onTap: onVerifiedProperties,
        ),
        _quickCategory(
          id: 'location',
          icon: Icons.map_outlined,
          label: 'Vị trí',
          color: const Color(0xFF08A94F),
          background: const Color(0xFFE1F4E8),
          onTap: onPickArea,
        ),
      ],
    ),
  );

  Widget _quickCategory({
    required String id,
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) => Expanded(
    child: InkWell(
      key: ValueKey('discovery-category-$id'),
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
              height: 36,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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
    VoidCallback? onSeeAll,
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
        if (onSeeAll != null)
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

class _TenantQuickOverview extends StatelessWidget {
  const _TenantQuickOverview({
    required this.tenantId,
    required this.onMyLease,
    required this.onInvoices,
    required this.onViewings,
    required this.onConversations,
  });

  final String tenantId;
  final VoidCallback onMyLease;
  final VoidCallback onInvoices;
  final VoidCallback onViewings;
  final VoidCallback onConversations;

  @override
  Widget build(BuildContext context) {
    final rental = LandlordDemoStore.instance;
    final conversations = ConversationStore.instance;
    final viewings = ViewingStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([rental, conversations, viewings]),
      builder: (context, _) {
        final leaseCount = rental.currentLeaseForTenant(tenantId) == null
            ? 0
            : 1;
        final unpaidCount = rental
            .invoicesForTenant(tenantId)
            .where((invoice) => !invoice.cancelled && invoice.remaining > 0)
            .length;
        final now = DateTime.now();
        final viewingCount = viewings
            .forTenant(tenantId)
            .where(
              (item) =>
                  item.status != ViewingStatus.cancelled &&
                  item.startsAt.isAfter(now),
            )
            .length;
        final unreadCount = conversations
            .forTenant(tenantId)
            .fold<int>(0, (sum, item) => sum + item.tenantUnread);
        final metrics = [
          _TenantOverviewMetricData(
            icon: Icons.home_rounded,
            value: '$leaseCount',
            label: 'Chỗ ở đang thuê',
            onTap: onMyLease,
          ),
          _TenantOverviewMetricData(
            icon: Icons.receipt_long_rounded,
            value: '$unpaidCount',
            label: 'Hóa đơn chờ',
            onTap: onInvoices,
          ),
          _TenantOverviewMetricData(
            icon: Icons.event_available_rounded,
            value: '$viewingCount',
            label: 'Lịch xem sắp tới',
            onTap: onViewings,
          ),
          _TenantOverviewMetricData(
            icon: Icons.chat_bubble_rounded,
            value: '$unreadCount',
            label: 'Tin nhắn mới',
            onTap: onConversations,
          ),
        ];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF08763B), Color(0xFF099B4C), Color(0xFF37B96D)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26348E5C),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(
              painter: const _TenantOverviewDecorationPainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(17, 15, 17, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.dashboard_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tổng quan của bạn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LỐI TẮT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Expanded(child: _metric(metrics[0])),
                        _divider(),
                        Expanded(child: _metric(metrics[1])),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.23),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: _metric(metrics[2])),
                        _divider(),
                        Expanded(child: _metric(metrics[3])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 43,
    color: Colors.white.withValues(alpha: 0.24),
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );

  Widget _metric(_TenantOverviewMetricData data) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.17),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(data.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TenantOverviewMetricData {
  const _TenantOverviewMetricData({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
}

class _TenantOverviewDecorationPainter extends CustomPainter {
  const _TenantOverviewDecorationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(size.width - 12, 14), 49, paint);
    canvas.drawCircle(Offset(size.width - 12, 14), 66, paint);
    canvas.drawCircle(Offset(size.width - 12, 14), 83, paint);
  }

  @override
  bool shouldRepaint(covariant _TenantOverviewDecorationPainter oldDelegate) =>
      false;
}
