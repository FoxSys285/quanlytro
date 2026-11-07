import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../data/property_catalog.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/properties/components/landlord_property_image.dart';
import '../../shared/widgets/list_pagination.dart';
import '../tenant_detail_ui.dart';
import '../tenant_ui.dart';
import 'models/tenant_property_listing.dart';

class TenantPropertiesPage extends StatefulWidget {
  const TenantPropertiesPage({
    super.key,
    required this.onPropertySelected,
    this.catalogSource,
    this.verifiedOnly = false,
  });

  final ValueChanged<TenantPropertyListing> onPropertySelected;
  final TenantPropertyCatalogSource? catalogSource;
  final bool verifiedOnly;

  @override
  State<TenantPropertiesPage> createState() => _TenantPropertiesPageState();
}

class _TenantPropertiesPageState extends State<TenantPropertiesPage> {
  static const _pageSize = 8;
  final _search = TextEditingController();
  final _pages = <PropertyCatalogPage>[];
  late bool _verifiedOnly = widget.verifiedOnly;
  Timer? _debounce;
  int _generation = 0;
  int _page = 0;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    RentalPortfolio.instance.addListener(_refresh);
    AdminStore.instance.addListener(_refresh);
    if (widget.catalogSource != null) {
      _loading = true;
      _fetch(0, 0);
    }
  }

  @override
  void dispose() {
    RentalPortfolio.instance.removeListener(_refresh);
    AdminStore.instance.removeListener(_refresh);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _searchChanged() {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() {
      _page = 0;
      _pages.clear();
      _error = false;
      _loading = widget.catalogSource != null;
    });
    if (widget.catalogSource != null) {
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => _fetch(generation, 0),
      );
    }
  }

  Future<void> _fetch(int generation, int index) async {
    try {
      final result = await widget.catalogSource!.fetch(
        TenantPropertyQuery(query: _search.text, verifiedOnly: _verifiedOnly),
        after: index == 0 ? null : _pages[index - 1].nextCursor,
        limit: _pageSize,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (index == _pages.length) _pages.add(result);
        _page = index;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _next() {
    if (_page + 1 < _pages.length) {
      setState(() => _page++);
    } else {
      setState(() => _loading = true);
      _fetch(_generation, _page + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = TenantPropertyQuery(
      query: _search.text,
      verifiedOnly: _verifiedOnly,
    );
    final local = [
      for (final store in RentalPortfolio.instance.stores)
        if (!AdminStore.instance.isHidden(store.property.id))
          TenantPropertyListing.fromStore(
            store,
            verified: AdminStore.instance.isVerified(store.property.id),
          ),
    ].where(query.matches).toList();
    final remote = widget.catalogSource != null;
    if (!remote) {
      _page = _page.clamp(0, ListPagination.lastPage(local.length, _pageSize));
    }
    final listings = remote
        ? (_loading || _error || _pages.isEmpty
              ? <TenantPropertyListing>[]
              : _pages[_page].items)
        : local.skip(_page * _pageSize).take(_pageSize).toList();

    return TenantDetailTheme(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF8),
        appBar: AppBar(
          title: Text(
            _verifiedOnly ? 'Nhà trọ đáng tin cậy' : 'Danh sách nhà trọ',
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF073B25), Color(0xFF168452)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _verifiedOnly
                                ? Icons.verified_user_rounded
                                : Icons.apartment_rounded,
                            color: const Color(0xFFBAEACD),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _verifiedOnly
                                ? 'An tâm chọn chỗ ở'
                                : 'Tìm nhà trọ bạn yêu thích',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _verifiedOnly
                                ? 'Khám phá các nhà trọ đã được xác minh thông tin.'
                                : 'Khám phá từng nhà trọ, xem giá thuê và chọn phòng phù hợp.',
                            style: const TextStyle(
                              color: Color(0xFFD6EFDF),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _search,
                            onChanged: (_) => _searchChanged(),
                            decoration: InputDecoration(
                              hintText:
                                  'Tìm tên nhà trọ, tỉnh/thành, xã/phường...',
                              hintStyle: const TextStyle(fontSize: 12),
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Xóa tìm kiếm',
                                      onPressed: () {
                                        _search.clear();
                                        _searchChanged();
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả nhà trọ'),
                          selected: !_verifiedOnly,
                          onSelected: (_) {
                            _verifiedOnly = false;
                            _searchChanged();
                          },
                        ),
                        ChoiceChip(
                          avatar: const Icon(
                            Icons.verified_rounded,
                            size: 17,
                            color: tenantGreenDark,
                          ),
                          label: const Text('Đã xác minh'),
                          selected: _verifiedOnly,
                          onSelected: (_) {
                            _verifiedOnly = true;
                            _searchChanged();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      remote
                          ? 'Khám phá nhà trọ · Trang ${_page + 1}'
                          : '${local.length} nhà trọ${_verifiedOnly ? ' đã xác minh' : ''}',
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error) ...[
                      const TenantEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Chưa tải được danh sách nhà trọ',
                        subtitle: 'Kiểm tra kết nối và thử lại.',
                      ),
                      Center(
                        child: OutlinedButton(
                          onPressed: _searchChanged,
                          child: const Text('Thử lại'),
                        ),
                      ),
                    ] else if (listings.isEmpty)
                      TenantEmptyState(
                        icon: _verifiedOnly
                            ? Icons.verified_user_outlined
                            : Icons.search_off_rounded,
                        title: _verifiedOnly
                            ? 'Chưa có nhà trọ đã xác minh'
                            : 'Không tìm thấy nhà trọ',
                        subtitle:
                            'Thử tìm ở khu vực khác hoặc thay đổi bộ lọc.',
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final listing in listings)
                              SizedBox(
                                width: constraints.maxWidth >= 720
                                    ? (constraints.maxWidth - 16) / 2
                                    : constraints.maxWidth,
                                child: _PropertyCard(
                                  listing: listing,
                                  onTap: () =>
                                      widget.onPropertySelected(listing),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (!remote)
                      ListPagination(
                        total: local.length,
                        page: _page,
                        pageSize: _pageSize,
                        showBoundaryPages: true,
                        onChanged: (value) => setState(() => _page = value),
                      )
                    else if (!_loading && !_error && _pages.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.outlined(
                            tooltip: 'Trang trước',
                            onPressed: _page == 0
                                ? null
                                : () => setState(() => _page--),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Trang ${_page + 1}'),
                          ),
                          IconButton.outlined(
                            tooltip: 'Trang tiếp theo',
                            onPressed: _pages[_page].nextCursor == null
                                ? null
                                : _next,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.listing, required this.onTap});
  final TenantPropertyListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final property = listing.property;
    return Material(
      key: ValueKey('property-card-${property.id}'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: tenantLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                LandlordPropertyImage(
                  url: property.imageUrl,
                  bytes: property.imageBytes,
                  height: 180,
                  semanticLabel: 'Ảnh ${property.name}',
                ),
                if (listing.verified)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _VerificationBadge(label: listing.verificationLabel),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: tenantInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (listing.verified && listing.isDemoVerification) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Dữ liệu mẫu, chưa kiểm chứng ngoài thực tế.',
                      style: TextStyle(
                        color: tenantMuted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 17,
                        color: tenantGreen,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          property.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: tenantMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _tag(
                        Icons.door_front_door_outlined,
                        '${listing.roomCount} phòng',
                      ),
                      for (final amenity in property.amenities.take(2))
                        _tag(Icons.check_rounded, amenity),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    listing.minRent == null
                        ? 'Liên hệ để biết giá thuê'
                        : 'Từ ${formatTenantMoney(listing.minRent!)}/tháng',
                    style: const TextStyle(
                      color: tenantGreenDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Xem phòng trọ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEDF7F0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tenantGreenDark),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: tenantGreenDark, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: tenantGreen, size: 16),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: tenantGreenDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
