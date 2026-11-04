import '../../../data/admin_store.dart';

import 'dart:async';
import 'dart:convert';

import '../../../data/discovery_catalog.dart';

import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';

import 'components/tenant_discovery_filter_sheet.dart';
import 'components/tenant_room_details_page.dart';
import 'models/tenant_room_listing.dart';
import 'tenant_discovery_home.dart';
import '../../shared/viewings/viewing_store.dart';
import 'tenant_favorites_page.dart';
import 'tenant_favorites_store.dart';
import '../tenant_ui.dart';
import '../../shared/widgets/list_pagination.dart';
import '../viewings/components/tenant_viewing_request_sheet.dart';
import '../viewings/models/tenant_viewing_request.dart';

class TenantDiscoveryPage extends StatefulWidget {
  const TenantDiscoveryPage({
    super.key,
    this.viewingStore,
    this.tenantId = ViewingStore.demoTenantId,
    this.catalogSource,
    this.resultsOnly = false,
    this.initialQuery = '',
    this.initialMaxRent = 20000000,
    this.initialElectricityRange = const RangeValues(0, 5),
    this.initialCity,
    this.initialWard,
    this.initialArea,
    this.initialWaterType = 'Tất cả',
    this.initialMinArea,
    this.initialMaxArea,
    this.initialAmenities = const {},
    this.initialSort = 'default',
  });

  final ViewingStore? viewingStore;
  final String tenantId;
  final TenantCatalogSource? catalogSource;
  final bool resultsOnly;
  final String initialQuery;
  final int initialMaxRent;
  final RangeValues initialElectricityRange;
  final String? initialCity;
  final String? initialWard;
  final String? initialArea;
  final String initialWaterType;
  final double? initialMinArea;
  final double? initialMaxArea;
  final Set<String> initialAmenities;
  final String initialSort;
  static TenantCatalogSource? activeCatalogSource;

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
  static const _pageSize = 8;
  int _page = 0;
  double? _minArea;
  double? _maxArea;
  Set<String> _amenities = {};
  String _sort = 'default';
  bool _restored = false;
  TenantCatalogSource? get _catalogSource =>
      widget.catalogSource ?? TenantDiscoveryPage.activeCatalogSource;
  final List<CatalogPage> _catalogPages = [];
  int _catalogIndex = 0;
  int _catalogGeneration = 0;
  String? _catalogKey;
  bool _catalogLoading = false;
  bool _catalogError = false;
  bool _offlineFallback = false;

  TenantCatalogQuery get _catalogQuery {
    final preset = switch (_selectedArea) {
      'Dưới 20 m²' => (0.0, 19.999999),
      '20–30 m²' => (20.0, 29.999999),
      '30–40 m²' => (30.0, 39.999999),
      '40–50 m²' => (40.0, 50.0),
      'Trên 50 m²' => (50.000001, double.infinity),
      _ => (0.0, double.infinity),
    };
    final minArea = _minArea == null || _minArea! < preset.$1
        ? preset.$1
        : _minArea!;
    final maxArea = _maxArea == null || _maxArea! > preset.$2
        ? preset.$2
        : _maxArea!;
    return TenantCatalogQuery(
      query: _query,
      maxRent: _maxRent,
      minElectricity: (_electricityRange.start * 1000).round(),
      maxElectricity: (_electricityRange.end * 1000).round(),
      city: _selectedCity,
      ward: _selectedWard,
      waterType: _waterType,
      minArea: minArea,
      maxArea: maxArea.isFinite ? maxArea : null,
      amenities: _amenities,
      sort: _sort,
    );
  }

  void _syncCatalog() {
    final key = jsonEncode([
      _query,
      _maxRent,
      _electricityRange.start,
      _electricityRange.end,
      _selectedCity,
      _selectedWard,
      _waterType,
      _selectedArea,
      _minArea,
      _maxArea,
      (_amenities.toList()..sort()),
      _sort,
    ]);
    if (_catalogKey == key) return;
    _catalogKey = key;
    _catalogGeneration++;
    _catalogPages.clear();
    _catalogIndex = 0;
    _catalogError = false;
    _catalogLoading = true;
    final query = _catalogQuery;
    final generation = _catalogGeneration;
    scheduleMicrotask(() {
      if (mounted && generation == _catalogGeneration) {
        _fetchCatalog(query, generation, index: 0);
      }
    });
  }

  Future<void> _fetchCatalog(
    TenantCatalogQuery query,
    int generation, {
    required int index,
    Object? after,
  }) async {
    try {
      final result = await _catalogSource!.fetch(
        query,
        after: after,
        limit: _pageSize,
      );
      if (!mounted || generation != _catalogGeneration) return;
      setState(() {
        if (index == _catalogPages.length) _catalogPages.add(result);
        _catalogIndex = index;
        _catalogLoading = false;
        _catalogError = false;
      });
    } catch (_) {
      if (!mounted || generation != _catalogGeneration) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = true;
      });
    }
  }

  void _nextCatalogPage() {
    if (_catalogIndex + 1 < _catalogPages.length) {
      setState(() => _catalogIndex++);
      return;
    }
    setState(() => _catalogLoading = true);
    _fetchCatalog(
      _catalogQuery,
      _catalogGeneration,
      index: _catalogIndex + 1,
      after: _catalogPages[_catalogIndex].nextCursor,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    if (widget.resultsOnly) return;
    final saved = PageStorage.maybeOf(context)
        ?.readState(context, identifier: 'discovery-${widget.tenantId}');
    if (saved is! Map<String, dynamic>) return;
    _query = saved['query'] as String;
    _searchController.text = _query;
    _maxRent = saved['rent'] as int;
    _electricityRange = saved['electricity'] as RangeValues;
    _selectedCity = saved['city'] as String?;
    _selectedWard = saved['ward'] as String?;
    _selectedArea = saved['area'] as String?;
    _waterType = saved['water'] as String;
    _minArea = saved['minArea'] as double?;
    _maxArea = saved['maxArea'] as double?;
    _amenities = {...saved['amenities'] as Set<String>};
    _sort = saved['sort'] as String;
    _page = saved['page'] as int;
    _catalogKey = saved['catalogKey'] as String?;
    _catalogIndex = saved['catalogIndex'] as int? ?? 0;
    _catalogPages.addAll(
      saved['catalogPages'] as List<CatalogPage>? ?? const [],
    );
    if (_catalogPages.isEmpty) _catalogKey = null;
  }

  void _saveState() {
    if (widget.resultsOnly) return;
    PageStorage.maybeOf(context)?.writeState(context, <String, dynamic>{
      'query': _searchController.text,
      'rent': _maxRent,
      'electricity': _electricityRange,
      'city': _selectedCity,
      'ward': _selectedWard,
      'area': _selectedArea,
      'water': _waterType,
      'minArea': _minArea,
      'maxArea': _maxArea,
      'amenities': {..._amenities},
      'sort': _sort,
      'page': _page,
      'catalogKey': _catalogKey,
      'catalogIndex': _catalogIndex,
      'catalogPages': [..._catalogPages],
    }, identifier: 'discovery-${widget.tenantId}');
  }

  final _searchController = TextEditingController();
  Timer? _searchDebounce;

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
    _query = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    _maxRent = widget.initialMaxRent;
    _electricityRange = widget.initialElectricityRange;
    _selectedCity = widget.initialCity;
    _selectedWard = widget.initialWard;
    _selectedArea = widget.initialArea;
    _waterType = widget.initialWaterType;
    _minArea = widget.initialMinArea;
    _maxArea = widget.initialMaxArea;
    _amenities = {...widget.initialAmenities};
    _sort = widget.initialSort;
    RentalPortfolio.instance.addListener(_refreshListings);
    AdminStore.instance.addListener(_refreshListings);
  }

  void _refreshListings() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final remote = _catalogSource != null && !_offlineFallback;
    if (remote) _syncCatalog();
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
          matchesArea &&
          (_minArea == null || room.areaSquareMeters >= _minArea!) &&
          (_maxArea == null || room.areaSquareMeters <= _maxArea!) &&
          _amenities.every(room.tags.contains);
    }).toList();
    if (_sort != 'default') {
      rooms.sort((a, b) {
        final result = switch (_sort) {
          'rentAsc' => a.price.compareTo(b.price),
          'rentDesc' => b.price.compareTo(a.price),
          'areaAsc' => a.areaSquareMeters.compareTo(b.areaSquareMeters),
          _ => b.areaSquareMeters.compareTo(a.areaSquareMeters),
        };
        return result == 0 ? a.id.compareTo(b.id) : result;
      });
    }
    final page = _page.clamp(
      0,
      ListPagination.lastPage(rooms.length, _pageSize),
    );
    _page = page;
    _saveState();
    final visibleRooms = remote
        ? (_catalogLoading || _catalogError || _catalogPages.isEmpty
              ? <TenantRoomListing>[]
              : _catalogPages[_catalogIndex].items)
        : rooms.skip(page * _pageSize).take(_pageSize).toList();

    return TenantDiscoveryHome(
      resultsOnly: widget.resultsOnly,
      localRooms: rooms,
      visibleRooms: visibleRooms,
      remote: remote,
      loading: _catalogLoading,
      hasError: _catalogError,
      offline: _offlineFallback,
      query: _query,
      sort: _sort,
      selectedCity: _selectedCity,
      searchController: _searchController,
      activeFilterCount: _activeFilterCount,
      currentPage: _catalogIndex,
      localPage: page,
      pageSize: _pageSize,
      remoteHasNext:
          _catalogPages.isNotEmpty &&
          _catalogIndex < _catalogPages.length &&
          _catalogPages[_catalogIndex].nextCursor != null,
      activeFilters: _activeFilterCount > 0 ? _activeFiltersBar() : null,
      onSearchChanged: _onSearchChanged,
      onSearchClear: () {
        _searchDebounce?.cancel();
        _searchController.clear();
        setState(() {
          _query = '';
          _page = 0;
        });
      },
      onFilter: () => _showFilterSheet(context),
      onOpenSearch: _openSearch,
      onFavorites: _openFavorites,
      onFavoriteToggle: _toggleFavorite,
      onRoomTap: (room) => _showRoomDetails(context, room),
      onSelectArea: (room) => setState(() {
        _selectedCity = room.city;
        _selectedWard = room.ward.isEmpty ? null : room.ward;
        _page = 0;
      }),
      onSortChanged: (value) => setState(() {
        _sort = value ?? 'default';
        _page = 0;
      }),
      onLocalPageChanged: (value) => setState(() => _page = value),
      onRemotePrevious: () => setState(() => _catalogIndex--),
      onRemoteNext: _nextCatalogPage,
      onRetry: () {
        setState(() => _catalogLoading = true);
        _fetchCatalog(
          _catalogQuery,
          _catalogGeneration,
          index: _catalogPages.isEmpty ? 0 : _catalogIndex + 1,
          after: _catalogPages.isEmpty
              ? null
              : _catalogPages[_catalogIndex].nextCursor,
        );
      },
      onUseOffline: () => setState(() => _offlineFallback = true),
      onReloadOnline: () => setState(() {
        _offlineFallback = false;
        _catalogKey = null;
      }),
      onNearby: () => setState(() {
        _sort = 'areaAsc';
        _page = 0;
      }),
      onDeals: () => setState(() {
        _sort = 'rentAsc';
        _page = 0;
      }),
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_maxRent < 20000000) count++;
    if (_selectedCity != null || _selectedWard != null) count++;
    if (_electricityRange.start > 0 || _electricityRange.end < 5) count++;
    if (_waterType != 'Tất cả') count++;
    if (_selectedArea != null || _minArea != null || _maxArea != null) count++;
    count += _amenities.length;
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

    if (_minArea != null || _maxArea != null) {
      filters.add(
        MapEntry(
          'numericArea',
          'Diện tích ${_minArea ?? 0}–${_maxArea ?? '∞'} m²',
        ),
      );
    }
    for (final amenity in _amenities) {
      filters.add(MapEntry('amenity:$amenity', amenity));
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
        case 'numericArea':
          _minArea = null;
          _maxArea = null;
          break;
        case 'area':
          _selectedArea = null;
          break;
      }
      if (filter.startsWith('amenity:')) _amenities.remove(filter.substring(8));
      _page = 0;
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
      _minArea = null;
      _maxArea = null;
      _amenities.clear();
      _page = 0;
    });
  }

  void _onSearchChanged(String value) {
    _saveState();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _page = 0;
      });
    });
  }

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
        initialMinArea: _minArea,
        initialMaxArea: _maxArea,
        initialAmenities: _amenities,
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
      _minArea = filters.minArea;
      _maxArea = filters.maxArea;
      _amenities = filters.amenities;
      _page = 0;
    });
  }

  void _showRoomDetails(BuildContext context, TenantRoomListing room) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TenantRoomDetailsPage(
          room: room,
          onBook: () => _openViewingRequest(room),
          isFavorite: TenantFavoritesStore.contains(room.id),
          onFavoriteToggle: () => _toggleFavorite(room),
        ),
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
            TenantSession.name,
        initialPhone:
            LandlordDemoStore.instance
                .currentLeaseForTenant(TenantSession.currentTenantId)
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
    TenantFavoritesStore.remember(room);
    setState(() => TenantFavoritesStore.toggle(room.id));
  }

  Future<void> _openFavorites() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TenantFavoritesPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TenantDiscoveryPage(
          viewingStore: widget.viewingStore,
          tenantId: widget.tenantId,
          catalogSource: _catalogSource,
          resultsOnly: true,
          initialQuery: _searchController.text.trim(),
          initialMaxRent: _maxRent,
          initialElectricityRange: _electricityRange,
          initialCity: _selectedCity,
          initialWard: _selectedWard,
          initialArea: _selectedArea,
          initialWaterType: _waterType,
          initialMinArea: _minArea,
          initialMaxArea: _maxArea,
          initialAmenities: _amenities,
          initialSort: _sort,
        ),
      ),
    );
  }
}

bool _areaMatches(TenantRoomListing room, String range) {
  final area = room.areaSquareMeters;
  return switch (range) {
    'Dưới 20 m²' => area < 20,
    '20–30 m²' => area >= 20 && area < 30,
    '30–40 m²' => area >= 30 && area < 40,
    '40–50 m²' => area >= 40 && area <= 50,
    'Trên 50 m²' => area > 50,
    _ => true,
  };
}
