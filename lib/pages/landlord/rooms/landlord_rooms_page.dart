import 'package:flutter/material.dart';

import '../../../layouts/landlord_navigation.dart';
import '../../shared/widgets/list_pagination.dart';
import '../billing/landlord_billing_page.dart';
import '../announcements/landlord_announcements_page.dart';
import '../finance/landlord_finance_models.dart';
import '../incidents/landlord_yeucausuachua_page.dart';
import '../incidents/models/landlord_suco.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import '../leases/landlord_leases_page.dart';
import '../meter_readings/landlord_chisodiennuoc_page.dart';
import '../room_types/landlord_room_types_page.dart';
import '../viewings/landlord_viewings_page.dart';
import 'components/landlord_room_button.dart';
import 'components/landlord_room_editor.dart';
import 'landlord_floor_plan_page.dart';
import 'landlord_room_detail_page.dart';
import 'models/landlord_room.dart';

enum _RoomFilter { all, vacant, occupied, unpaid, expiring, maintenance }

enum _RoomSort { code, priceLow, priceHigh, attention }

class LandlordRoomsPage extends StatefulWidget {
  const LandlordRoomsPage({
    super.key,
    this.store,
    this.showHeader = false,
    this.embedded = false,
    this.dark = false,
    this.onToggleTheme,
  });
  final LandlordDemoStore? store;
  final bool showHeader;
  final bool embedded;
  final bool dark;
  final VoidCallback? onToggleTheme;

  @override
  State<LandlordRoomsPage> createState() => _LandlordRoomsPageState();
}

class _LandlordRoomsPageState extends State<LandlordRoomsPage> {
  LandlordDemoStore get _store =>
      widget.store ?? LandlordDemoStore.activeInstance;
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  static const _pageSize = 12;
  String? _propertyId;
  String _query = '';
  int? _floor;
  int _page = 0;
  bool _grid = false;
  _RoomFilter _filter = _RoomFilter.all;
  _RoomSort _sort = _RoomSort.code;

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _edit([LandlordRoom? room]) => showDialog<void>(
    context: context,
    builder: (_) => LandlordRoomEditor(store: _store, room: room),
  );

  void _openPage(String title, Widget page) {
    final destination = switch (page) {
      LandlordLeasesPage() => 'leases',
      LandlordBillingPage() => 'billing',
      LandlordChiSoDienNuocPage() => 'meter_readings',
      LandlordViewingsPage() => 'viewings',
      LandlordYeuCauSuaChuaPage() => 'incidents',
      LandlordAnnouncementsPage() => 'announcements',
      LandlordRoomTypesPage() => 'room_types',
      LandlordFloorPlanSetupPage() || LandlordFloorPlanPage() => 'rooms',
      _ => 'rooms',
    };
    final routeTitle = switch (page) {
      LandlordLeasesPage() ||
      LandlordChiSoDienNuocPage() ||
      LandlordViewingsPage() ||
      LandlordYeuCauSuaChuaPage() ||
      LandlordAnnouncementsPage() ||
      LandlordRoomTypesPage() ||
      LandlordFloorPlanSetupPage() ||
      LandlordFloorPlanPage() => null,
      _ => title,
    };
    LandlordNavigation.push<void>(
      context,
      title: routeTitle,
      page: page,
      destinationId: destination,
    );
  }

  void _showRoom(String code) {
    LandlordNavigation.push<void>(
      context,
      page: LandlordRoomDetailPage(store: _store, roomCode: code),
      destinationId: 'rooms',
    );
  }

  LandlordInvoice? _invoiceFor(LandlordRoomDetails details) {
    final lease = details.lease;
    if (lease == null) return null;
    final invoices =
        _store.invoices
            .where(
              (invoice) => !invoice.cancelled && invoice.leaseId == lease.id,
            )
            .toList()
          ..sort((a, b) => b.period.compareTo(a.period));
    for (final invoice in invoices) {
      if (invoice.status == LandlordInvoiceStatus.overdue &&
          invoice.remaining > 0) {
        return invoice;
      }
    }
    return invoices.firstOrNull;
  }

  LandlordIncident? _incidentFor(LandlordRoomDetails details) {
    for (final incident in _store.incidents) {
      if (_store.canonicalRoom(incident.room) ==
              _store.canonicalRoom(details.room.code) &&
          (incident.status == IncidentStatus.newly ||
              incident.status == IncidentStatus.inProgress)) {
        return incident;
      }
    }
    return null;
  }

  LandlordRoomHighlight _highlight(
    LandlordRoomDetails details,
    LandlordInvoice? invoice,
    LandlordIncident? incident,
  ) {
    if (invoice?.status == LandlordInvoiceStatus.overdue &&
        invoice!.remaining > 0) {
      return LandlordRoomHighlight.overdue;
    }
    if (incident != null) return LandlordRoomHighlight.maintenance;
    if (details.lease?.isCurrent == true) {
      final days = details.lease!.endDate.difference(DateTime.now()).inDays;
      if (days >= 0 && days <= 30) return LandlordRoomHighlight.expiring;
    }
    if (invoice != null && invoice.remaining > 0) {
      return LandlordRoomHighlight.unpaid;
    }
    return switch (details.status) {
      LandlordRoomStatus.vacant => LandlordRoomHighlight.vacant,
      LandlordRoomStatus.occupied => LandlordRoomHighlight.occupied,
      LandlordRoomStatus.upcoming => LandlordRoomHighlight.upcoming,
    };
  }

  bool _matchesFilter(
    LandlordRoomDetails details,
    LandlordInvoice? invoice,
    LandlordIncident? incident,
  ) => switch (_filter) {
    _RoomFilter.all => true,
    _RoomFilter.vacant => details.status == LandlordRoomStatus.vacant,
    _RoomFilter.occupied => details.status == LandlordRoomStatus.occupied,
    _RoomFilter.unpaid => invoice != null && invoice.remaining > 0,
    _RoomFilter.expiring =>
      details.lease?.isCurrent == true &&
          details.lease!.endDate.difference(DateTime.now()).inDays >= 0 &&
          details.lease!.endDate.difference(DateTime.now()).inDays <= 30,
    _RoomFilter.maintenance => incident != null,
  };

  List<LandlordRoomAction> _actionsFor(
    LandlordRoomDetails details,
    LandlordRoomHighlight highlight,
  ) {
    if (highlight == LandlordRoomHighlight.vacant) {
      return [
        LandlordRoomAction(
          label: 'Tạo hợp đồng',
          icon: Icons.description_outlined,
          primary: true,
          onTap: () => _openPage(
            'Hợp đồng thuê',
            LandlordLeasesPage(
              createForRoom: details.room.leaseRoomCode ?? details.room.code,
            ),
          ),
        ),
        LandlordRoomAction(
          label: 'Lịch xem',
          icon: Icons.calendar_month_outlined,
          onTap: () =>
              _openPage('Lịch xem phòng', const LandlordViewingsPage()),
        ),
      ];
    }
    if (highlight == LandlordRoomHighlight.expiring) {
      return [
        LandlordRoomAction(
          label: 'Lịch xem',
          icon: Icons.calendar_month_outlined,
          onTap: () =>
              _openPage('Lịch xem phòng', const LandlordViewingsPage()),
        ),
      ];
    }
    return const [];
  }

  Widget _frame(List<Widget> children) => widget.embedded
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        )
      : LandlordGlassPage(
          title: 'Danh sách phòng trọ',
          subtitle: _store.property.name,
          kicker: 'QUẢN LÝ KHÔNG GIAN',
          store: _store,
          children: children,
        );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final palette = LandlordPalette.of(context);
      if (_propertyId != _store.property.id) {
        _propertyId = _store.property.id;
        _floor = null;
        _filter = _RoomFilter.all;
        _page = 0;
        _query = '';
        _searchController.clear();
      }
      final all = _store.roomDetails;
      final floors = all.map((item) => item.room.floor).toSet().toList()
        ..sort();
      final occupiedCount = all
          .where((item) => item.status == LandlordRoomStatus.occupied)
          .length;
      final vacantCount = all
          .where((item) => item.status == LandlordRoomStatus.vacant)
          .length;
      if (all.isEmpty) {
        final needsTypes = _store.roomTypes.isEmpty;
        return _frame([
          const LandlordGlassSection(
            title: 'Phòng trọ',
            subtitle: 'Thiết lập không gian cho thuê của bạn',
          ),
          LandlordGlassCard(
            child: Column(
              children: [
                Icon(
                  needsTypes ? Icons.category_outlined : Icons.stairs_rounded,
                  color: propertyBlue,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  needsTypes ? 'Thêm loại phòng trước' : 'Chưa có sơ đồ phòng',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  needsTypes
                      ? 'Tạo loại phòng và giá thuê trước khi thiết lập từng tầng.'
                      : 'Khai báo số phòng cho mỗi tầng hoặc thêm từng phòng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: needsTypes
                      ? () => _openPage(
                          'Loại phòng',
                          LandlordRoomTypesPage(store: _store),
                        )
                      : () => _openPage(
                          'Thiết lập tầng và phòng',
                          LandlordFloorPlanSetupPage(store: _store),
                        ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    needsTypes ? 'Thêm loại phòng' : 'Thiết lập tầng và phòng',
                  ),
                ),
                if (!needsTypes)
                  TextButton(
                    onPressed: () => _edit(),
                    child: const Text('Thêm phòng mới'),
                  ),
                TextButton.icon(
                  onPressed: () => _openPage(
                    'Hợp đồng thuê',
                    LandlordLeasesPage(store: _store, openTemplateEditor: true),
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Tạo hợp đồng mẫu chung'),
                ),
              ],
            ),
          ),
        ]);
      }
      final normalized = _query.trim().toLowerCase();
      final matches = all.where((details) {
        final haystack =
            '${details.room.code} ${details.typeName} '
                    '${details.lease?.tenantName ?? ''} ${details.lease?.phone ?? ''}'
                .toLowerCase();
        if (!haystack.contains(normalized)) return false;
        if (_floor != null && details.room.floor != _floor) return false;
        return _matchesFilter(
          details,
          _invoiceFor(details),
          _incidentFor(details),
        );
      }).toList();
      switch (_sort) {
        case _RoomSort.code:
          matches.sort((a, b) => a.room.code.compareTo(b.room.code));
        case _RoomSort.priceLow:
          matches.sort(
            (a, b) => (a.monthlyRent ?? 0).compareTo(b.monthlyRent ?? 0),
          );
        case _RoomSort.priceHigh:
          matches.sort(
            (a, b) => (b.monthlyRent ?? 0).compareTo(a.monthlyRent ?? 0),
          );
        case _RoomSort.attention:
          const priority = [
            LandlordRoomHighlight.overdue,
            LandlordRoomHighlight.maintenance,
            LandlordRoomHighlight.expiring,
            LandlordRoomHighlight.unpaid,
            LandlordRoomHighlight.vacant,
            LandlordRoomHighlight.occupied,
            LandlordRoomHighlight.upcoming,
          ];
          matches.sort(
            (a, b) => priority
                .indexOf(_highlight(a, _invoiceFor(a), _incidentFor(a)))
                .compareTo(
                  priority.indexOf(
                    _highlight(b, _invoiceFor(b), _incidentFor(b)),
                  ),
                ),
          );
      }
      final page = _page.clamp(
        0,
        ListPagination.lastPage(matches.length, _pageSize),
      );
      final visible = matches.skip(page * _pageSize).take(_pageSize).toList();

      return _frame([
        LandlordGlassSection(
          title: 'Phòng trọ',
          subtitle: 'Tìm kiếm và quản lý phòng của nhà trọ',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _edit(),
              style: FilledButton.styleFrom(
                backgroundColor: propertyBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm phòng mới'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  _openPage('Sơ đồ tầng', LandlordFloorPlanPage(store: _store)),
              style: FilledButton.styleFrom(
                backgroundColor: propertyBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.grid_view_rounded, size: 17),
              label: const Text('Sơ đồ tầng'),
            ),
            FilledButton.icon(
              onPressed: () => _openPage(
                'Chỉ số điện nước',
                LandlordChiSoDienNuocPage(store: _store),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: propertyBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Ghi điện nước'),
            ),
            FilledButton.icon(
              onPressed: () => _openPage(
                'Hợp đồng thuê',
                LandlordLeasesPage(store: _store, openTemplateEditor: true),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: propertyBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Tạo hợp đồng mẫu chung'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _RoomsKpis(
          total: all.length,
          occupied: occupiedCount,
          vacant: vacantCount,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: (value) => setState(() {
            _query = value;
            _page = 0;
          }),
          decoration: InputDecoration(
            hintText: 'Tìm mã phòng, tên khách, số điện thoại',
            hintStyle: TextStyle(color: palette.muted, fontSize: 12),
            prefixIcon: Icon(Icons.search_rounded, color: palette.muted),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () => setState(() {
                      _query = '';
                      _page = 0;
                      _searchController.clear();
                    }),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            filled: true,
            fillColor: palette.surface.withValues(alpha: 0.85),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: palette.line),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('${_store.property.id}:$_floor'),
                initialValue: _floor,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.layers_outlined,
                    size: 18,
                    color: palette.primary,
                  ),
                  filled: true,
                  fillColor: palette.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.line),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int>(child: Text('Tất cả các tầng')),
                  for (final floor in floors)
                    DropdownMenuItem(value: floor, child: Text('Tầng $floor')),
                ],
                onChanged: (value) => setState(() {
                  _floor = value;
                  _page = 0;
                }),
              ),
            ),
            const SizedBox(width: 9),
            _ViewToggle(
              grid: _grid,
              onList: () => setState(() => _grid = false),
              onGrid: () => setState(() => _grid = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 37,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterPill(
                label: 'Tất cả (${all.length})',
                selected: _filter == _RoomFilter.all,
                onTap: () => setState(() {
                  _filter = _RoomFilter.all;
                  _page = 0;
                }),
              ),
              _FilterPill(
                label: 'Phòng trống ($vacantCount)',
                selected: _filter == _RoomFilter.vacant,
                onTap: () => setState(() {
                  _filter = _RoomFilter.vacant;
                  _page = 0;
                }),
              ),
              _FilterPill(
                label: 'Đang thuê ($occupiedCount)',
                selected: _filter == _RoomFilter.occupied,
                onTap: () => setState(() {
                  _filter = _RoomFilter.occupied;
                  _page = 0;
                }),
              ),
              _FilterPill(
                label: 'Chưa đóng tiền',
                selected: _filter == _RoomFilter.unpaid,
                onTap: () => setState(() {
                  _filter = _RoomFilter.unpaid;
                  _page = 0;
                }),
              ),
              _FilterPill(
                label: 'Sắp hết hạn',
                selected: _filter == _RoomFilter.expiring,
                onTap: () => setState(() {
                  _filter = _RoomFilter.expiring;
                  _page = 0;
                }),
              ),
              _FilterPill(
                label: 'Đang sửa chữa',
                selected: _filter == _RoomFilter.maintenance,
                onTap: () => setState(() {
                  _filter = _RoomFilter.maintenance;
                  _page = 0;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Hiển thị ${matches.length} phòng · ${_store.property.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.muted, fontSize: 11),
              ),
            ),
            PopupMenuButton<_RoomSort>(
              tooltip: 'Sắp xếp phòng',
              onSelected: (value) => setState(() {
                _sort = value;
                _page = 0;
              }),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _RoomSort.code,
                  child: Text('Theo mã phòng'),
                ),
                PopupMenuItem(
                  value: _RoomSort.priceLow,
                  child: Text('Giá thấp trước'),
                ),
                PopupMenuItem(
                  value: _RoomSort.priceHigh,
                  child: Text('Giá cao trước'),
                ),
                PopupMenuItem(
                  value: _RoomSort.attention,
                  child: Text('Cần chú ý trước'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sắp xếp',
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 16,
                      color: palette.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (matches.isEmpty)
          const LandlordEmptyState(
            message: 'Không có phòng phù hợp với bộ lọc.',
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = _grid
                ? (constraints.maxWidth < 650 ? 2 : 3)
                : (constraints.maxWidth < 700 ? 1 : 2);
            const spacing = 11.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final details in visible)
                  SizedBox(
                    width: width,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Builder(
                        builder: (context) {
                          final invoice = _invoiceFor(details);
                          final incident = _incidentFor(details);
                          final highlight = _highlight(
                            details,
                            invoice,
                            incident,
                          );
                          return LandlordRoomButton(
                            key: ValueKey(details.room.code),
                            details: details,
                            highlight: highlight,
                            compact: _grid,
                            actions: _actionsFor(details, highlight),
                            onTap: () => _showRoom(details.room.code),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        ListPagination(
          total: matches.length,
          page: page,
          pageSize: _pageSize,
          showBoundaryPages: true,
          onChanged: (value) => setState(() => _page = value),
        ),
      ]);
    },
  );
}

class _RoomsKpis extends StatelessWidget {
  const _RoomsKpis({
    required this.total,
    required this.occupied,
    required this.vacant,
  });
  final int total;
  final int occupied;
  final int vacant;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.85),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? palette.line
              : Colors.white,
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          _RoomKpi(
            label: 'Tổng phòng',
            value: '$total',
            unit: 'phòng',
            color: palette.primary,
          ),
          const SizedBox(width: 6),
          _RoomKpi(
            label: 'Đang thuê',
            value: '$occupied',
            unit: 'căn',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          _RoomKpi(
            label: 'Phòng trống',
            value: '$vacant',
            unit: 'căn',
            color: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}

class _RoomKpi extends StatelessWidget {
  const _RoomKpi({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.muted, fontSize: 10),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(color: palette.muted, fontSize: 9),
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
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.grid,
    required this.onList,
    required this.onGrid,
  });
  final bool grid;
  final VoidCallback onList;
  final VoidCallback onGrid;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Xem dạng danh sách',
            onPressed: onList,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: grid ? null : palette.primarySoft,
            ),
            icon: Icon(
              Icons.view_agenda_rounded,
              color: grid ? palette.muted : palette.primary,
              size: 19,
            ),
          ),
          IconButton(
            tooltip: 'Xem dạng lưới',
            onPressed: onGrid,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: grid ? palette.primarySoft : null,
            ),
            icon: Icon(
              Icons.grid_view_rounded,
              color: grid ? palette.primary : palette.muted,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Material(
        color: selected
            ? propertyBlue
            : palette.surface.withValues(alpha: 0.85),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? propertyBlue : palette.line),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : palette.ink,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
