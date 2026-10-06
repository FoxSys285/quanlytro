import 'dart:async';

import 'package:flutter/material.dart';

import 'components/tenant_discovery_filter_sheet.dart';
import 'components/tenant_room_card.dart';
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
  bool _locationEnabled = false;
  bool _nearbyOnly = false;
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
      final ignoreAutoFilledWard =
          _nearbyOnly &&
          _locationEnabled &&
          _selectedWard == TenantRoomDemoData.currentWard;
      final matchesLocation =
          (_selectedCity == null || room.city == _selectedCity) &&
          (_selectedWard == null ||
              ignoreAutoFilledWard ||
              room.ward == _selectedWard);
      final matchesNearby = !_nearbyOnly || room.distanceMeters <= 5000;
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
          matchesNearby &&
          matchesElectricity &&
          matchesWater &&
          matchesArea;
    }).toList();
    if (_nearbyOnly) {
      rooms.sort(
        (first, second) =>
            first.distanceMeters.compareTo(second.distanceMeters),
      );
    }
    final visibleRooms = rooms.take(_visibleCount).toList();

    return TenantPageFrame(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào Nam Đẹp Trai',
                    style: TextStyle(
                      color: tenantGreenDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Trọ hợp lý, giá vừa ý!',
                    style: TextStyle(
                      color: Color.fromARGB(255, 47, 108, 58),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openFavorites,
              icon: const Icon(Icons.favorite_rounded, size: 16),
              label: const Text('Yêu thích'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBC5362),
                side: const BorderSide(color: Color(0xFFF0D5D9)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
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
          _nearbyOnly ? 'Phòng gần bạn' : 'Chỗ ở phù hợp với bạn',
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
          for (final room in visibleRooms) ...[
            TenantRoomCard(
              room: room,
              isFavorite: TenantFavoritesStore.contains(room.name),
              onFavoriteToggle: () => _toggleFavorite(room),
              onTap: () => _showRoomDetails(context, room),
            ),
            const SizedBox(height: 14),
          ],
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
    if (_nearbyOnly) count++;
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
      final location = [
        if (_selectedWard != null) _selectedWard!,
        if (_selectedCity != null) _selectedCity!,
      ].join(' · ');
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
    if (_nearbyOnly) {
      filters.add(MapEntry('nearby', 'Phòng gần bạn · 5 km'));
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
        case 'nearby':
          _nearbyOnly = false;
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
      _nearbyOnly = false;
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

  Widget _locationCard(BuildContext context) {
    return TenantSurface(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tenantGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _locationEnabled
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  size: 19,
                  color: tenantGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vị trí hiện tại của bạn',
                      style: TextStyle(
                        color: tenantInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _locationEnabled
                          ? '${TenantRoomDemoData.currentWard}, Bình Thạnh · TP. Hồ Chí Minh'
                          : 'Bật vị trí để tìm phòng ở gần bạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: tenantMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _requestLocationAccess(context),
                style: TextButton.styleFrom(
                  foregroundColor: tenantGreenDark,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  _locationEnabled ? 'Cập nhật' : 'Bật vị trí',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_locationEnabled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: tenantLine),
            ),
            Row(
              children: [
                const Icon(
                  Icons.near_me_outlined,
                  size: 16,
                  color: tenantGreen,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Ưu tiên phòng trong bán kính 5 km',
                    style: TextStyle(color: tenantInk, fontSize: 10),
                  ),
                ),
                Switch.adaptive(
                  value: _nearbyOnly,
                  activeTrackColor: tenantGreen,
                  onChanged: (value) {
                    setState(() {
                      _nearbyOnly = value;
                      if (!value &&
                          _locationEnabled &&
                          _selectedCity == TenantRoomDemoData.currentCity &&
                          _selectedWard == TenantRoomDemoData.currentWard) {
                        _selectedCity = null;
                        _selectedWard = null;
                      }
                      _visibleCount = 10;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestLocationAccess(BuildContext context) async {
    final allowed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.location_on_rounded, color: tenantGreen),
        title: const Text('Cho phép truy cập vị trí?'),
        content: const Text(
          'An Cư sẽ dùng vị trí để điền sẵn khu vực lọc và ưu tiên phòng gần bạn. Bản xem trước sẽ dùng vị trí mẫu tại Phường 25, Bình Thạnh.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: tenantGreen),
            child: const Text('Cho phép'),
          ),
        ],
      ),
    );
    if (!mounted || allowed != true) return;
    setState(() {
      _locationEnabled = true;
      _nearbyOnly = true;
      _selectedCity = TenantRoomDemoData.currentCity;
      _selectedWard = TenantRoomDemoData.currentWard;
      _visibleCount = 10;
    });
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final filters = await showModalBottomSheet<TenantDiscoveryFilterSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TenantDiscoveryFilterSheet(
        initialRent: _maxRent,
        initialCity:
            _selectedCity ??
            (_locationEnabled ? TenantRoomDemoData.currentCity : null),
        initialWard:
            _selectedWard ??
            (_locationEnabled ? TenantRoomDemoData.currentWard : null),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TenantRoomDetailsSheet(
        room: room,
        onBook: () => _openViewingRequest(room),
        isFavorite: TenantFavoritesStore.contains(room.name),
        onFavoriteToggle: () => _toggleFavorite(room),
      ),
    );
  }

  Future<void> _openViewingRequest(TenantRoomListing room) async {
    final request = await showModalBottomSheet<TenantViewingRequest>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TenantViewingRequestSheet(
        room: room,
        initialName: 'Trần Hoàng Nam',
        initialPhone: '0900000002',
      ),
    );
    if (!mounted || request == null) return;
    try {
      final viewing = _viewingStore.createRequest(
        propertyId: room.propertyId,
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
    setState(() => TenantFavoritesStore.toggle(room.name));
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
