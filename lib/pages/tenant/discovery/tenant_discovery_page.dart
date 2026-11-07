import '../../shared/profile/account_store.dart';
import '../../../layouts/role_layout.dart';
import '../../../data/admin_store.dart';

import 'dart:async';
import 'dart:convert';

import '../../../data/discovery_catalog.dart';
import '../../../data/property_catalog.dart';
import 'models/tenant_property_listing.dart';
import 'tenant_properties_page.dart';

import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';

import 'components/tenant_discovery_filter_sheet.dart';
import 'components/tenant_area_picker_page.dart';
import 'services/tenant_location_service.dart';
import 'components/tenant_room_details_page.dart';
import 'models/tenant_room_listing.dart';
import 'tenant_discovery_home.dart';
import '../../shared/viewings/viewing_store.dart';
import 'tenant_favorites_page.dart';
import 'tenant_favorites_store.dart';
import '../tenant_ui.dart';
import '../tenant_settings_page.dart';
import '../../shared/widgets/list_pagination.dart';
import '../viewings/components/tenant_viewing_request_sheet.dart';
import '../viewings/models/tenant_viewing_request.dart';

class TenantDiscoveryPage extends StatefulWidget {
  const TenantDiscoveryPage({
    super.key,
    this.viewingStore,
    String? tenantId,
    this.catalogSource,
    this.propertyCatalogSource,
    this.initialPropertyId,
    this.initialPropertyName,
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
    this.locationService = const TenantLocationService(),
  }) : _tenantId = tenantId ?? '';

  final TenantLocationService locationService;
  final ViewingStore? viewingStore;
  final String _tenantId;
  String get tenantId =>
      _tenantId.isEmpty ? TenantSession.currentTenantId : _tenantId;
  final TenantCatalogSource? catalogSource;
  final TenantPropertyCatalogSource? propertyCatalogSource;
  final String? initialPropertyId;
  final String? initialPropertyName;
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
  static TenantPropertyCatalogSource? activePropertyCatalogSource;

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
  String? _selectedPropertyId;
  String? _selectedPropertyName;
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
  bool _findingNearby = false;
  bool _openingSearch = false;
  DiscoveryHomeFeed? _homeFeed;
  Future<void>? _homeRequest;
  static const _homePreviewSize = 10;

  TenantCatalogQuery get _catalogQuery {
    if (!widget.resultsOnly) return const TenantCatalogQuery();
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
      propertyId: _selectedPropertyId,
    );
  }

  void _syncCatalog() {
    final key = !widget.resultsOnly
        ? 'discovery-home'
        : jsonEncode([
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
            _selectedPropertyId,
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
        if (widget.resultsOnly) {
          _fetchCatalog(query, generation, index: 0);
        } else {
          _loadHome(generation);
        }
      }
    });
  }

  Future<void> _loadHome(int generation) {
    return _homeRequest ??= _fetchHome(generation)
        .whenComplete(() => _homeRequest = null);
  }

  Future<void> _fetchHome(int generation) async {
    final source = _catalogSource;
    if (source == null) return;
    try {
      final feed = source is TenantDiscoveryHomeSource
          ? await (source as TenantDiscoveryHomeSource).fetchHome(
              limit: _homePreviewSize,
            )
          : DiscoveryHomeFeed.fromRooms(
              (await source.fetch(
                const TenantCatalogQuery(),
                limit: _homePreviewSize,
              )).items,
            );
      if (!mounted || generation != _catalogGeneration) return;
      setState(() {
        _homeFeed = feed;
        _catalogPages
          ..clear()
          ..add(CatalogPage(items: feed.featured));
        _catalogIndex = 0;
        _catalogLoading = false;
        _catalogError = false;
      });
    } catch (_) {
      if (!mounted || generation != _catalogGeneration) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = _homeFeed == null;
      });
      if (_homeFeed != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa làm mới được. Danh sách hiện tại vẫn được giữ lại.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshHome() async {
    if (_homeRequest != null) return _homeRequest;
    if (_catalogSource == null) {
      setState(() {});
      return;
    }
    setState(() {
      _offlineFallback = false;
      _catalogLoading = true;
      _catalogError = false;
    });
    await _loadHome(++_catalogGeneration);
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
    if (!widget.resultsOnly) return;
    final saved = PageStorage.maybeOf(context)
        ?.readState(context, identifier: _storageIdentifier);
    if (saved is! Map<String, dynamic>) return;
    _query = saved['query'] as String;
    _searchController.text = _query;
    _maxRent = saved['rent'] as int;
    _electricityRange = saved['electricity'] as RangeValues;
    _selectedCity = saved['city'] as String?;
    _selectedWard = saved['ward'] as String?;
    _selectedArea = saved['area'] as String?;
    _selectedPropertyId = saved['propertyId'] as String?;
    _selectedPropertyName = saved['propertyName'] as String?;
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
    TenantSelectedLocation.instance.restore(
      city: _selectedCity,
      ward: _selectedWard,
    );
  }

  void _saveState() {
    if (!widget.resultsOnly) return;
    PageStorage.maybeOf(context)?.writeState(context, <String, dynamic>{
      'query': _searchController.text,
      'rent': _maxRent,
      'electricity': _electricityRange,
      'city': _selectedCity,
      'ward': _selectedWard,
      'area': _selectedArea,
      'propertyId': _selectedPropertyId,
      'propertyName': _selectedPropertyName,
      'water': _waterType,
      'minArea': _minArea,
      'maxArea': _maxArea,
      'amenities': {..._amenities},
      'sort': _sort,
      'page': _page,
      'catalogKey': _catalogKey,
      'catalogIndex': _catalogIndex,
      'catalogPages': [..._catalogPages],
    }, identifier: _storageIdentifier);
  }

  String get _storageIdentifier {
    final initialFilters = [
      widget.initialQuery,
      widget.initialPropertyId,
      widget.initialCity,
      widget.initialWard,
      widget.initialMaxRent,
      widget.initialSort,
      widget.initialArea,
      widget.initialMinArea,
      widget.initialMaxArea,
      widget.initialElectricityRange.start,
      widget.initialElectricityRange.end,
      widget.initialWaterType,
      widget.initialAmenities.toList()..sort(),
    ];
    return 'discovery-results-${widget.tenantId}-${jsonEncode(initialFilters)}';
  }

  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    RentalPortfolio.instance.removeListener(_refreshListings);
    AdminStore.instance.removeListener(_refreshListings);
    TenantSelectedLocation.instance.removeListener(_refreshListings);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    RentalPortfolio.instance.addListener(_refreshListings);
    AdminStore.instance.addListener(_refreshListings);
    TenantSelectedLocation.instance.addListener(_refreshListings);
    if (!widget.resultsOnly) return;
    _query = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    _maxRent = widget.initialMaxRent;
    _electricityRange = widget.initialElectricityRange;
    _selectedCity = widget.initialCity;
    _selectedWard = widget.initialWard;
    _selectedArea = widget.initialArea;
    _selectedPropertyId = widget.initialPropertyId;
    _selectedPropertyName = widget.initialPropertyName;
    _waterType = widget.initialWaterType;
    _minArea = widget.initialMinArea;
    _maxArea = widget.initialMaxArea;
    _amenities = {...widget.initialAmenities};
    _sort = widget.initialSort;
  }

  void _refreshListings() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final remote = _catalogSource != null && !_offlineFallback;
    if (remote) _syncCatalog();
    final normalizedQuery = _query.trim().toLowerCase();
    final minimumElectricity = (_electricityRange.start * 1000).round();
    final maximumElectricity = (_electricityRange.end * 1000).round();
    // The cloud catalogue has its own bounded queries. Do not construct every
    // room from the business portfolio just to render a ten-room preview.
    final rooms =
        (remote ? <TenantRoomListing>[] : TenantRoomDemoData.allListings).where((
          room,
        ) {
          if (!widget.resultsOnly) return true;
          final searchableText =
              '${room.name} ${room.address} ${room.roomType} ${room.tags.join(' ')} ${room.city} ${room.ward}'
                  .toLowerCase();
          final matchesQuery =
              normalizedQuery.isEmpty ||
              searchableText.contains(normalizedQuery);
          final matchesLocation =
              (_selectedCity == null ||
                  sameLocationName(room.city, _selectedCity!)) &&
              (_selectedWard == null ||
                  sameLocationName(room.ward, _selectedWard!));
          final matchesElectricity =
              room.electricityPrice >= minimumElectricity &&
              room.electricityPrice <= maximumElectricity;
          final matchesWater =
              _waterType == 'Tất cả' || room.waterType == _waterType;
          final matchesArea =
              _selectedArea == null || _areaMatches(room, _selectedArea!);
          return matchesQuery &&
              (_selectedPropertyId == null ||
                  room.propertyId == _selectedPropertyId) &&
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
        ? ((!widget.resultsOnly && _homeFeed != null)
              ? _homeFeed!.featured
              : _catalogLoading || _catalogError || _catalogPages.isEmpty
              ? <TenantRoomListing>[]
              : _catalogPages[_catalogIndex].items)
        : rooms
              .skip(page * _pageSize)
              .take(widget.resultsOnly ? _pageSize : _homePreviewSize)
              .toList();

    final home = TenantDiscoveryHome(
      locationService: widget.locationService,
      resultsOnly: widget.resultsOnly,
      localRooms: rooms,
      visibleRooms: visibleRooms,
      remote: remote,
      loading: _catalogLoading && (widget.resultsOnly || _homeFeed == null),
      hasError: _catalogError,
      offline: _offlineFallback,
      profileName: AccountStore.instance.profile(AppRole.tenant).name,
      tenantId: widget.tenantId,
      query: _query,
      sort: _sort,
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
      onSearchSubmitted: _submitSearch,
      onSearchClear: () {
        _searchDebounce?.cancel();
        _searchController.clear();
        setState(() {
          _query = '';
          _page = 0;
        });
      },
      onFilter: () => _showFilterSheet(context),
      onPickArea: _openAreaPicker,
      onAreaSelected: (selection) => unawaited(_applyAreaSelection(selection)),
      onOpenSearch: _openSearch,
      onFavorites: _openFavorites,
      onSettings: _openSettings,
      onFavoriteToggle: _toggleFavorite,
      onRoomTap: (room) => _showRoomDetails(context, room),
      onSortChanged: (value) => setState(() {
        _sort = value ?? 'default';
        _page = 0;
      }),
      onLocalPageChanged: (value) => setState(() => _page = value),
      onRemotePrevious: () => setState(() => _catalogIndex--),
      onRemoteNext: _nextCatalogPage,
      onRetry: () {
        if (!widget.resultsOnly) {
          _refreshHome();
          return;
        }
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
      onNearby: _findNearby,
      onProperties: () => _openProperties(),
      onVerifiedProperties: () => _openProperties(verifiedOnly: true),
      onMyLease: () => _openTenantDestination('my_lease'),
      onInvoices: () => _openTenantDestination('invoices'),
      onViewings: () => _openTenantDestination('viewings'),
      onConversations: () => _openTenantDestination('conversations'),
      homeFeed: remote ? _homeFeed : null,
      onRefresh: _refreshHome,
      onGoodPrice: () => _openSearch(initialSort: 'rentAsc'),
    );
    return Material(type: MaterialType.transparency, child: home);
  }

  void _openTenantDestination(String destinationId) {
    RoleLayoutShell.tryNavigateTo(context, destinationId);
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedPropertyId != null) count++;
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
    if (_selectedPropertyId != null) {
      filters.add(
        MapEntry('property', _selectedPropertyName ?? 'Nhà trọ đã chọn'),
      );
    }
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
        case 'property':
          _selectedPropertyId = null;
          _selectedPropertyName = null;
          break;
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
      _selectedPropertyId = null;
      _selectedPropertyName = null;
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

  void _submitSearch() {
    FocusScope.of(context).unfocus();
    _searchDebounce?.cancel();
    if (!widget.resultsOnly) {
      unawaited(_openSearch());
      return;
    }
    setState(() {
      _query = _searchController.text.trim();
      _page = 0;
    });
  }

  void _onSearchChanged(String value) {
    if (!widget.resultsOnly) {
      setState(() => _query = value);
      return;
    }
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
    FocusScope.of(context).unfocus();
    final filters = await showModalBottomSheet<TenantDiscoveryFilterSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TenantDiscoveryFilterSheet(
        locationService: widget.locationService,
        availableRooms: [for (final page in _catalogPages) ...page.items],
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
    if (!widget.resultsOnly) {
      await _openSearch(filters: filters);
      return;
    }
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
    if (filters.city != null) {
      TenantSelectedLocation.instance.select(
        city: filters.city!,
        ward: filters.ward,
      );
    } else {
      TenantSelectedLocation.instance.reset();
    }
  }

  void _showRoomDetails(BuildContext context, TenantRoomListing room) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TenantRoomDetailsPage(
          room: room,
          onBook: () => _openViewingRequest(room),
          isFavorite: TenantFavoritesStore.contains(room.id),
          onFavoriteToggle: () => _toggleFavorite(room),
          propertyLoader: (propertyId) async {
            final source =
                widget.propertyCatalogSource ??
                TenantDiscoveryPage.activePropertyCatalogSource;
            if (source is TenantPropertyDetailsSource) {
              return (await (source as TenantPropertyDetailsSource)
                      .fetchProperty(propertyId))
                  ?.property;
            }
            return null;
          },
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

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TenantSettingsPage()),
    );
  }

  Future<void> _findNearby() async {
    if (_findingNearby) return;
    _findingNearby = true;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Đang lấy vị trí để tìm phòng…')),
      );
    try {
      final selection = await widget.locationService.currentArea();
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      await _applyAreaSelection(selection);
    } on TenantLocationFailure catch (error) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Không lấy được vị trí. Hãy thử lại hoặc chọn khu vực tìm phòng.',
            ),
          ),
        );
    } finally {
      _findingNearby = false;
    }
  }

  Future<void> _openAreaPicker() async {
    final selection = await Navigator.of(context).push<TenantAreaSelection>(
      MaterialPageRoute<TenantAreaSelection>(
        builder: (_) =>
            TenantAreaPickerPage(locationService: widget.locationService),
      ),
    );
    if (!mounted || selection == null) return;
    await _applyAreaSelection(selection);
  }

  Future<void> _applyAreaSelection(TenantAreaSelection selection) async {
    if (!mounted) return;
    TenantSelectedLocation.instance.select(
      city: selection.city,
      ward: selection.ward,
    );
    if (widget.resultsOnly) {
      setState(() {
        _selectedCity = selection.city;
        _selectedWard = selection.ward;
        _page = 0;
      });
    } else {
      await _openSearch(city: selection.city, ward: selection.ward);
    }
  }

  Future<void> _openProperties({bool verifiedOnly = false}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TenantPropertiesPage(
            verifiedOnly: verifiedOnly,
            catalogSource:
                widget.propertyCatalogSource ??
                TenantDiscoveryPage.activePropertyCatalogSource,
            onPropertySelected: (property) => _openSearch(property: property),
          ),
        ),
      );

  Future<void> _openSearch({
    TenantPropertyListing? property,
    TenantDiscoveryFilterSelection? filters,
    String? city,
    String? ward,
    String? initialSort,
  }) async {
    if (_openingSearch) return;
    _openingSearch = true;
    FocusScope.of(context).unfocus();
    try {
      if (city != null) {
        TenantSelectedLocation.instance.select(city: city, ward: ward);
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TenantDiscoveryPage(
            viewingStore: widget.viewingStore,
            locationService: widget.locationService,
            tenantId: widget.tenantId,
            catalogSource: _catalogSource,
            propertyCatalogSource: widget.propertyCatalogSource,
            resultsOnly: true,
            initialQuery: property == null ? _searchController.text.trim() : '',
            initialPropertyId: property?.property.id ?? _selectedPropertyId,
            initialPropertyName:
                property?.property.name ?? _selectedPropertyName,
            initialMaxRent: filters?.maxRent ?? _maxRent,
            initialElectricityRange:
                filters?.electricityRange ?? _electricityRange,
            initialCity: property != null
                ? null
                : filters != null
                ? filters.city
                : city ?? _selectedCity,
            initialWard: property != null
                ? null
                : filters != null
                ? filters.ward
                : city != null
                ? ward
                : _selectedWard,
            initialArea: filters != null ? filters.area : _selectedArea,
            initialWaterType: filters?.waterType ?? _waterType,
            initialMinArea: filters != null ? filters.minArea : _minArea,
            initialMaxArea: filters != null ? filters.maxArea : _maxArea,
            initialAmenities: filters?.amenities ?? _amenities,
            initialSort: initialSort ?? _sort,
          ),
        ),
      );
    } finally {
      _openingSearch = false;
      if (mounted) setState(() {});
    }
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
