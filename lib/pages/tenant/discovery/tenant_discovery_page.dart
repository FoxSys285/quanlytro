import '../../../data/admin_store.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';

import 'components/tenant_discovery_filter_sheet.dart';
import 'components/tenant_room_card.dart';
import 'components/tenant_area_picker_card.dart';
import 'components/tenant_room_details_sheet.dart';
import 'models/tenant_room_listing.dart';
import '../../shared/viewings/viewing_store.dart';
import 'tenant_favorites_page.dart';
import 'tenant_favorites_store.dart';
import '../tenant_ui.dart';
import '../viewings/components/tenant_viewing_request_sheet.dart';
import '../viewings/models/tenant_viewing_request.dart';

class TenantDiscoveryPage extends StatefulWidget {
  const TenantDiscoveryPage({
    super.key,
    this.viewingStore,
    this.tenantId = ViewingStore.demoTenantId,
  });

  final ViewingStore? viewingStore;
  final String tenantId;

  @override
  State<TenantDiscoveryPage> createState() => _TenantDiscoveryPageState();
}

class _TenantDiscoveryPageState extends State<TenantDiscoveryPage> {
  ViewingStore get _viewingStore =>
      widget.viewingStore ?? ViewingStore.instance;
  String _query = '';
  int _maxRent = 20000000;
  RangeValues _electricityRange = const RangeValues(0, 5);
  String? _selectedCity;
  String? _selectedWard;
  String? _selectedArea;
  String _waterType = 'Tất cả';
  int _visibleCount = 10;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  static const _popularSearches = [
    'Studio',
    'Có gác',
    'Bình Thạnh',
    'Ban công',
    'Máy lạnh',
    'Thang máy',
  ];

  @override
  void dispose() {
    RentalPortfolio.instance.removeListener(_refreshListings);
    AdminStore.instance.removeListener(_refreshListings);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    RentalPortfolio.instance.addListener(_refreshListings);
    AdminStore.instance.addListener(_refreshListings);
  }

  void _refreshListings() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final minimumElectricity = (_electricityRange.start * 1000).round();
    final maximumElectricity = (_electricityRange.end * 1000).round();
    final rooms = TenantRoomDemoData.allListings.where((room) {
      final searchableText =
          '${room.name} ${room.address} ${room.roomType} ${room.tags.join(' ')} ${room.city} ${room.ward}'
              .toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
      final matchesLocation =
          (_selectedCity == null || room.city == _selectedCity) &&
          (_selectedWard == null || room.ward == _selectedWard);
      final matchesElectricity =
          room.electricityPrice >= minimumElectricity &&
          room.electricityPrice <= maximumElectricity;
      final matchesWater =
          _waterType == 'Tất cả' || room.waterType == _waterType;
      final matchesArea =
          _selectedArea == null || _areaMatches(room, _selectedArea!);
      return matchesQuery &&
          room.price <= _maxRent &&
          matchesLocation &&
          matchesElectricity &&
          matchesWater &&
          matchesArea;
    }).toList();
    final visibleRooms = rooms.take(_visibleCount).toList();

    return TenantPageFrame(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF145E52), Color(0xFF218C74)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2016836F),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 42,
                top: -47,
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KHÁM PHÁ CHỖ Ở',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Tìm nơi ở\nvừa ý bạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            height: 1.13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.45,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Lọc nhanh theo giá, khu vực và tiện ích.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openFavorites,
                    icon: const Icon(Icons.favorite_rounded, size: 15),
                    label: const Text('Yêu thích'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tên nhà, khu vực, loại phòng...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF98A3AC),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: tenantGreen,
                    size: 21,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _visibleCount = 10;
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: tenantMuted,
                          ),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: tenantLine),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: tenantLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: tenantGreen,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Material(
              color: tenantGreen,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _showFilterSheet(context),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.tune_rounded, color: Colors.white),
                      if (_activeFilterCount > 0)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            width: 17,
                            height: 17,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFCE69),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(
                                color: tenantInk,
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
        if (_activeFilterCount > 0) ...[
          const SizedBox(height: 10),
          _activeFiltersBar(),
        ],
        const SizedBox(height: 12),
        _locationCard(context),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 17, color: tenantGreen),
            SizedBox(width: 6),
            Text(
              'Từ khóa hay tìm',
              style: TextStyle(
                color: tenantInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final keyword in _popularSearches)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchController.value = TextEditingValue(
                        text: keyword,
                        selection: TextSelection.collapsed(
                          offset: keyword.length,
                        ),
                      );
                      setState(() {
                        _query = keyword;
                        _visibleCount = 10;
                      });
                    },
                    avatar: const Icon(
                      Icons.search_rounded,
                      size: 14,
                      color: tenantGreenDark,
                    ),
                    label: Text(keyword),
                    labelStyle: const TextStyle(
                      color: tenantGreenDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: const Color(0xFFEBF5F1),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TenantSectionHeading(
          'Chỗ ở phù hợp với bạn',
          trailing: Text(
            '${rooms.length} phòng',
            style: const TextStyle(color: tenantMuted, fontSize: 12),
          ),
        ),
        if (visibleRooms.isEmpty)
          const TenantEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Chưa tìm thấy phòng phù hợp',
            subtitle: 'Thử đổi từ khóa hoặc bộ lọc nhé.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 18) / columns;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final room in visibleRooms)
                    SizedBox(
                      width: width,
                      child: TenantRoomCard(
                        room: room,
                        isFavorite: TenantFavoritesStore.contains(room.id),
                        onFavoriteToggle: () => _toggleFavorite(room),
                        onTap: () => _showRoomDetails(context, room),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 14),
        if (rooms.length > visibleRooms.length) ...[
          const SizedBox(height: 2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _visibleCount += 10),
              icon: const Icon(Icons.expand_more_rounded, size: 19),
              label: Text(
                'Xem thêm ${rooms.length - visibleRooms.length} phòng',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: tenantGreenDark,
                side: const BorderSide(color: tenantLine),
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
        ],
        const SizedBox(height: 4),
        const Text(
          'Thông tin phòng trong bản xem trước',
          style: TextStyle(color: Color(0xFFA2ACB4), fontSize: 10),
        ),
      ],
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_maxRent < 20000000) count++;
    if (_selectedCity != null || _selectedWard != null) count++;
    if (_electricityRange.start > 0 || _electricityRange.end < 5) count++;
    if (_waterType != 'Tất cả') count++;
    if (_selectedArea != null) count++;
    return count;
  }

  Widget _activeFiltersBar() {
    final filters = <MapEntry<String, String>>[];
    if (_maxRent < 20000000) {
      filters.add(
        MapEntry('rent', 'Tiền trọ ≤ ${formatTenantMoney(_maxRent)}'),
      );
    }
    if (_selectedCity != null || _selectedWard != null) {
      final location = [?_selectedWard, ?_selectedCity].join(' · ');
      filters.add(MapEntry('location', location));
    }
    if (_electricityRange.start > 0 || _electricityRange.end < 5) {
      final minimum = (_electricityRange.start * 1000).round();
      final maximum = (_electricityRange.end * 1000).round();
      filters.add(
        MapEntry(
          'electricity',
          'Điện ${formatTenantMoney(minimum)} – ${formatTenantMoney(maximum)}/kWh',
        ),
      );
    }
    if (_waterType != 'Tất cả') {
      filters.add(MapEntry('water', 'Nước: $_waterType'));
    }
    if (_selectedArea != null) {
      filters.add(MapEntry('area', 'Diện tích: $_selectedArea'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Đang áp dụng',
                style: TextStyle(
                  color: tenantMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Xóa bộ lọc'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB65050),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 7,
          runSpacing: 2,
          children: [
            for (final filter in filters)
              InputChip(
                label: Text(filter.value),
                onDeleted: () => _removeFilter(filter.key),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                deleteIconColor: tenantMuted,
                backgroundColor: Colors.white,
                side: const BorderSide(color: tenantLine),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                labelStyle: const TextStyle(
                  color: tenantGreenDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ],
    );
  }

  void _removeFilter(String filter) {
    setState(() {
      switch (filter) {
        case 'rent':
          _maxRent = 20000000;
          break;
        case 'location':
          _selectedCity = null;
          _selectedWard = null;
          break;
        case 'electricity':
          _electricityRange = const RangeValues(0, 5);
          break;
        case 'water':
          _waterType = 'Tất cả';
          break;
        case 'area':
          _selectedArea = null;
          break;
      }
      _visibleCount = 10;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _maxRent = 20000000;
      _selectedCity = null;
      _selectedWard = null;
      _electricityRange = const RangeValues(0, 5);
      _waterType = 'Tất cả';
      _selectedArea = null;
      _visibleCount = 10;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _visibleCount = 10;
      });
    });
  }

  Widget _locationCard(BuildContext context) => TenantAreaPickerCard(
    city: _selectedCity,
    ward: _selectedWard,
    onPressed: () => _showFilterSheet(context),
  );

  Future<void> _showFilterSheet(BuildContext context) async {
    final filters = await showModalBottomSheet<TenantDiscoveryFilterSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TenantDiscoveryFilterSheet(
        initialRent: _maxRent,
        initialCity: _selectedCity,
        initialWard: _selectedWard,
        initialElectricityRange: _electricityRange,
        initialWaterType: _waterType,
        initialArea: _selectedArea,
      ),
    );
    if (!mounted || filters == null) return;
    setState(() {
      _maxRent = filters.maxRent;
      _selectedCity = filters.city;
      _selectedWard = filters.ward;
      _electricityRange = filters.electricityRange;
      _waterType = filters.waterType;
      _selectedArea = filters.area;
      _visibleCount = 10;
    });
  }

  void _showRoomDetails(BuildContext context, TenantRoomListing room) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TenantRoomDetailsSheet(
        room: room,
        onBook: () => _openViewingRequest(room),
        isFavorite: TenantFavoritesStore.contains(room.id),
        onFavoriteToggle: () => _toggleFavorite(room),
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
                .currentLeaseForTenant(TenantSession.tenantId)
                ?.tenantName ??
            TenantSession.name,
        initialPhone:
            LandlordDemoStore.instance
                .currentLeaseForTenant(TenantSession.tenantId)
                ?.phone ??
            TenantSession.phone,
      ),
    );
    if (!mounted || request == null) return;
    try {
      final viewing = _viewingStore.createRequest(
        propertyId: room.propertyId,
        roomId: room.id,
        tenantId: widget.tenantId,
        roomName: room.name,
        address: room.address,
        startsAt: request.startsAt,
        customerName: request.customerName,
        phone: request.phone,
        attendeeCount: request.attendeeCount,
        personalNeeds: request.personalNeeds,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Đã gửi yêu cầu xem ${viewing.roomName}. Chờ chủ trọ xác nhận lịch.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _toggleFavorite(TenantRoomListing room) {
    setState(() => TenantFavoritesStore.toggle(room.id));
  }

  Future<void> _openFavorites() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TenantFavoritesPage()),
    );
    if (mounted) setState(() {});
  }
}

bool _areaMatches(TenantRoomListing room, String range) {
  final area = int.tryParse(room.size.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  return switch (range) {
    'Dưới 20 m²' => area < 20,
    '20–30 m²' => area >= 20 && area < 30,
    '30–40 m²' => area >= 30 && area < 40,
    '40–50 m²' => area >= 40 && area <= 50,
    'Trên 50 m²' => area > 50,
    _ => true,
  };
}
