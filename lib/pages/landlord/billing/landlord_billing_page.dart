import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../../../layouts/landlord_navigation.dart';
import '../landlord_theme.dart';
import '../landlord_glass.dart';
import '../finance/landlord_room_balance.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_ui.dart';
import '../properties/components/landlord_property_image.dart';
import '../properties/components/landlord_property_editor.dart';
import '../properties/models/landlord_property.dart';
import '../properties/components/property_portfolio_visuals.dart';
import '../incidents/models/landlord_suco.dart';
import '../rooms/components/landlord_room_button.dart';
import '../rooms/landlord_room_finance_detail_page.dart';
import '../rooms/models/landlord_room.dart';
import '../../shared/widgets/list_pagination.dart';

enum _BillingRoomSort { code, priceLow, priceHigh, attention }

class LandlordBillingPage extends StatefulWidget {
  const LandlordBillingPage({
    super.key,
    this.initialRoom,
    this.profileName,
    this.store,
  });
  final LandlordDemoStore? store;
  final String? initialRoom;
  final String? profileName;

  @override
  State<LandlordBillingPage> createState() => _LandlordBillingPageState();
}

class _LandlordBillingPageState extends State<LandlordBillingPage> {
  RentalPortfolio get _portfolio => RentalPortfolio.instance;
  LandlordDemoStore get _store =>
      widget.store ??
      (_selectedPropertyId == null
          ? null
          : _portfolio.byId(_selectedPropertyId!)) ??
      _portfolio.active;
  String? _selectedPropertyId;
  String _propertyQuery = '';
  String _propertyFilter = 'Tất cả';
  int? _floor;
  bool _grid = false;
  _BillingRoomSort _roomSort = _BillingRoomSort.code;
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  String _roomFilter = 'Tất cả';
  int _roomPage = 0;
  int _billingTab = 0;
  late final _search = TextEditingController(text: widget.initialRoom ?? '');
  late String _query = widget.initialRoom ?? '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _filter = 'Tất cả';
  int _page = 0;
  static const _pageSize = 10;

  bool _hasActiveIncident(LandlordRoomDetails details) => _store.incidents.any(
    (incident) =>
        _store.canonicalRoom(incident.room) ==
            _store.canonicalRoom(details.room.code) &&
        (incident.status == IncidentStatus.newly ||
            incident.status == IncidentStatus.inProgress),
  );

  LandlordRoomHighlight _roomHighlight(LandlordRoomBalance balance) {
    if (balance.invoices.any(
      (invoice) =>
          invoice.status == LandlordInvoiceStatus.overdue &&
          invoice.remaining > 0,
    )) {
      return LandlordRoomHighlight.overdue;
    }
    final details = balance.details;
    if (_hasActiveIncident(details)) return LandlordRoomHighlight.maintenance;
    final lease = details.lease;
    if (lease?.isCurrent == true) {
      final days = lease!.endDate.difference(DateTime.now()).inDays;
      if (days >= 0 && days <= 30) return LandlordRoomHighlight.expiring;
    }
    if (balance.state == RoomPaymentState.pendingReview) {
      return LandlordRoomHighlight.pendingReview;
    }
    if (balance.remaining > 0) return LandlordRoomHighlight.unpaid;
    if (balance.state == RoomPaymentState.paid) {
      return LandlordRoomHighlight.paid;
    }
    if (balance.state == RoomPaymentState.unbilled) {
      return LandlordRoomHighlight.unbilled;
    }
    return switch (details.status) {
      LandlordRoomStatus.vacant => LandlordRoomHighlight.vacant,
      LandlordRoomStatus.occupied => LandlordRoomHighlight.occupied,
      LandlordRoomStatus.upcoming => LandlordRoomHighlight.upcoming,
    };
  }

  bool _matchesRoomFilter(LandlordRoomBalance balance, String filter) {
    final details = balance.details;
    final lease = details.lease;
    return switch (filter) {
      'Phòng trống' => details.status == LandlordRoomStatus.vacant,
      'Đang thuê' => details.status == LandlordRoomStatus.occupied,
      'Chưa đóng tiền' => balance.remaining > 0,
      'Sắp hết hạn' =>
        lease?.isCurrent == true &&
            lease!.endDate.difference(DateTime.now()).inDays >= 0 &&
            lease.endDate.difference(DateTime.now()).inDays <= 30,
      'Đang sửa chữa' => _hasActiveIncident(details),
      'Đã đóng tiền' => balance.state == RoomPaymentState.paid,
      'Chưa lập phiếu thu' => balance.state == RoomPaymentState.unbilled,
      'Đang chờ duyệt' => balance.state == RoomPaymentState.pendingReview,
      _ => true,
    };
  }

  void _returnToPropertyPicker() => setState(() {
    _selectedPropertyId = null;
    _propertyQuery = '';
    _floor = null;
    _roomFilter = 'Tất cả';
    _roomPage = 0;
    _query = '';
    _search.clear();
  });

  Future<void> _editProperty() async {
    final property = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(property: _store.property),
    );
    if (!mounted || property == null) return;
    _store.updateProperty(property);
    try {
      final persistence = AppPersistence.current;
      await persistence?.saveChanges();
      if (!mounted) return;
      showLandlordMessage(
        context,
        persistence?.cloudConfirmed == true
            ? 'Đã cập nhật ${property.name}. Đã lưu lên Firebase.'
            : 'Đã cập nhật ${property.name}. Đã lưu trên máy.',
      );
    } catch (error) {
      if (mounted) showLandlordMessage(context, '$error');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.store != null) {
      _selectedPropertyId = widget.store!.property.id;
    } else if (widget.initialRoom != null && _portfolio.stores.isNotEmpty) {
      _selectedPropertyId = _portfolio.active.property.id;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _portfolio,
    builder: (context, _) {
      if (_selectedPropertyId == null &&
          widget.store == null &&
          widget.initialRoom == null) {
        return _propertyPicker();
      }
      return _billingContent();
    },
  );

  Widget _propertyPicker() {
    final profileName =
        widget.profileName ?? _portfolio.active.property.ownerName;
    final stores = _portfolio.stores.where((store) {
      final query = _propertyQuery.trim().toLowerCase();
      final matchesQuery = '${store.property.name} ${store.property.address}'
          .toLowerCase()
          .contains(query);
      final hasOccupiedRoom = store.roomDetails.any(
        (room) => room.status.name == 'occupied',
      );
      final hasVacantRoom = store.roomDetails.any(
        (room) => room.status.name == 'vacant',
      );
      final matchesFilter = switch (_propertyFilter) {
        'Đang thuê' => hasOccupiedRoom,
        'Còn phòng' => hasVacantRoom,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
    return LandlordGlassPage(
      title: 'Thu chi nhà trọ',
      subtitle: 'Chọn nhà trọ để xem công nợ và phiếu thu.',
      kicker: 'QUẢN LÝ TÀI CHÍNH',
      profileName: profileName,
      store: _portfolio.active,
      children: [
        LandlordGlassSection(
          title: 'Nhà trọ',
          subtitle: 'Danh sách nhà trọ bạn đang quản lý.',
        ),
        LandlordGlassSearch(
          hint: 'Tìm tên hoặc địa chỉ nhà trọ',
          onChanged: (value) => setState(() => _propertyQuery = value),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          children: [
            for (final filter in const ['Tất cả', 'Đang thuê', 'Còn phòng'])
              ChoiceChip(
                label: Text(filter),
                selected: _propertyFilter == filter,
                onSelected: (_) => setState(() => _propertyFilter = filter),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (stores.isEmpty)
          LandlordGlassCard(
            child: Text(
              _portfolio.stores.isEmpty
                  ? 'Bạn chưa có nhà trọ để theo dõi thu chi.'
                  : 'Không tìm thấy nhà trọ phù hợp.',
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final store in stores)
                  SizedBox(width: width, child: _propertyCard(store)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _propertyCard(LandlordDemoStore store) {
    final property = store.property;
    final occupied = store.roomDetails
        .where((room) => room.status.name == 'occupied')
        .length;
    final vacant = store.roomDetails
        .where((room) => room.status.name == 'vacant')
        .length;
    return LandlordGlassCard(
      padding: EdgeInsets.zero,
      onTap: () {
        _portfolio.select(property.id);
        setState(() {
          _selectedPropertyId = property.id;
          _floor = null;
          _roomPage = 0;
          _roomFilter = 'Tất cả';
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LandlordPropertyImage(
            url: property.imageUrl,
            bytes: property.imageBytes,
            height: 160,
            borderRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandlordPalette.of(context).ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  property.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandlordPalette.of(context).muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _propertyMetric(
                      '${store.catalog.length} phòng',
                      Icons.meeting_room_outlined,
                    ),
                    _propertyMetric(
                      '$occupied đang thuê',
                      Icons.people_alt_outlined,
                    ),
                    _propertyMetric(
                      '$vacant còn trống',
                      Icons.door_front_door_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PropertyPortfolioActionButton(
                    label: 'Xem thu chi',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      _portfolio.select(property.id);
                      setState(() {
                        _selectedPropertyId = property.id;
                        _floor = null;
                        _roomPage = 0;
                        _roomFilter = 'Tất cả';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertyMetric(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: LandlordPalette.of(context).surfaceAlt,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: LandlordPalette.of(context).primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _billingContent() => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final balances = landlordRoomBalances(_store, _period);
      final rooms = balances.where((balance) {
        final details = balance.details;
        final lease = details.lease;
        final haystack =
            '${details.room.code} ${details.typeName} '
                    '${lease?.tenantName ?? ''} ${lease?.phone ?? ''}'
                .toLowerCase();
        return _matchesRoomFilter(balance, _roomFilter) &&
            (_floor == null || details.room.floor == _floor) &&
            haystack.contains(_query.trim().toLowerCase());
      }).toList();
      switch (_roomSort) {
        case _BillingRoomSort.code:
          rooms.sort(
            (a, b) => a.details.room.code.compareTo(b.details.room.code),
          );
        case _BillingRoomSort.priceLow:
          rooms.sort(
            (a, b) => (a.details.monthlyRent ?? 0).compareTo(
              b.details.monthlyRent ?? 0,
            ),
          );
        case _BillingRoomSort.priceHigh:
          rooms.sort(
            (a, b) => (b.details.monthlyRent ?? 0).compareTo(
              a.details.monthlyRent ?? 0,
            ),
          );
        case _BillingRoomSort.attention:
          const priority = [
            LandlordRoomHighlight.overdue,
            LandlordRoomHighlight.maintenance,
            LandlordRoomHighlight.expiring,
            LandlordRoomHighlight.pendingReview,
            LandlordRoomHighlight.unpaid,
            LandlordRoomHighlight.unbilled,
            LandlordRoomHighlight.paid,
            LandlordRoomHighlight.vacant,
            LandlordRoomHighlight.occupied,
            LandlordRoomHighlight.upcoming,
          ];
          rooms.sort(
            (a, b) => priority
                .indexOf(_roomHighlight(a))
                .compareTo(priority.indexOf(_roomHighlight(b))),
          );
      }
      final totalRooms = balances.length;
      final occupiedRooms = balances
          .where(
            (balance) => balance.details.status == LandlordRoomStatus.occupied,
          )
          .length;
      final vacantRooms = balances
          .where(
            (balance) => balance.details.status == LandlordRoomStatus.vacant,
          )
          .length;
      final floorOptions =
          balances.map((balance) => balance.details.room.floor).toSet().toList()
            ..sort();
      final roomFilterOptions = [
        ('Tất cả', balances.length),
        (
          'Phòng trống',
          balances
              .where((balance) => _matchesRoomFilter(balance, 'Phòng trống'))
              .length,
        ),
        (
          'Đang thuê',
          balances
              .where((balance) => _matchesRoomFilter(balance, 'Đang thuê'))
              .length,
        ),
        (
          'Chưa đóng tiền',
          balances
              .where((balance) => _matchesRoomFilter(balance, 'Chưa đóng tiền'))
              .length,
        ),
        (
          'Sắp hết hạn',
          balances
              .where((balance) => _matchesRoomFilter(balance, 'Sắp hết hạn'))
              .length,
        ),
        (
          'Đang sửa chữa',
          balances
              .where((balance) => _matchesRoomFilter(balance, 'Đang sửa chữa'))
              .length,
        ),
        (
          'Đã đóng tiền',
          balances
              .where((balance) => _matchesRoomFilter(balance, 'Đã đóng tiền'))
              .length,
        ),
        (
          'Chưa lập phiếu thu',
          balances
              .where(
                (balance) => _matchesRoomFilter(balance, 'Chưa lập phiếu thu'),
              )
              .length,
        ),
        (
          'Đang chờ duyệt',
          balances
              .where((balance) => _matchesRoomFilter(balance, 'Đang chờ duyệt'))
              .length,
        ),
      ];
      final roomPage = _roomPage.clamp(
        0,
        ListPagination.lastPage(rooms.length, 12),
      );
      final invoices = _store.invoices.where((invoice) {
        if (_filter == 'Chưa thanh toán') {
          return invoice.status == LandlordInvoiceStatus.unpaid ||
              invoice.status == LandlordInvoiceStatus.overdue;
        }
        if (_filter == 'Thanh toán một phần') {
          return invoice.status == LandlordInvoiceStatus.partial;
        }
        if (_filter == 'Đã thanh toán') {
          return invoice.status == LandlordInvoiceStatus.paid;
        }
        return true;
      }).toList()..sort((a, b) => b.period.compareTo(a.period));
      final debt = balances.fold<int>(0, (sum, b) => sum + b.remaining);
      final paid = balances.fold<int>(0, (sum, b) => sum + b.monthlyPaid);
      final pendingCount = _store.payments
          .where((p) => p.status == LandlordPaymentStatus.pending)
          .length;
      final overdue = balances
          .expand((b) => b.invoices)
          .where((i) => i.status == LandlordInvoiceStatus.overdue)
          .fold<int>(0, (sum, i) => sum + i.remaining);
      final months = {
        DateTime(DateTime.now().year, DateTime.now().month),
        _period,
        ..._store.invoices.map((i) => DateTime(i.period.year, i.period.month)),
      }.toList()..sort((a, b) => b.compareTo(a));
      final page = _page.clamp(
        0,
        ListPagination.lastPage(invoices.length, _pageSize),
      );
      return _billingShell(context, [
        LandlordBluePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Thu tiền phòng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    landlordMonth(_period),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Còn phải thu',
                style: TextStyle(color: Color(0xFFD8E7FF), fontSize: 12),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatLandlordMoney(debt),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '${balances.where((b) => b.state == RoomPaymentState.unpaid).length} phòng chưa đóng',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${balances.where((b) => b.state == RoomPaymentState.paid).length} phòng đã đóng',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metric(
                  'Đã thu trong tháng',
                  formatLandlordMoney(paid),
                  Icons.check_circle_outline,
                  const Color(0xFF17A374),
                  width: width,
                ),
                _metric(
                  'Chờ duyệt',
                  '$pendingCount khoản',
                  Icons.fact_check_outlined,
                  const Color(0xFFB78427),
                  width: width,
                ),
                _metric(
                  'Quá hạn',
                  formatLandlordMoney(overdue),
                  Icons.event_busy_outlined,
                  const Color(0xFFDA4458),
                  width: width,
                ),
                _metric(
                  'Chưa lập phiếu thu',
                  '${balances.where((b) => b.state == RoomPaymentState.unbilled).length} phòng',
                  Icons.receipt_long_outlined,
                  propertyBlue,
                  width: width,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LandlordGlassSection(
          title: 'Danh sách phòng',
          subtitle:
              'Theo dõi phiếu thu theo tháng và tình trạng của từng phòng.',
          trailing: IconButton.filledTonal(
            tooltip: 'Lập phiếu thu',
            onPressed: _store.activeLeases.isEmpty ? null : _createInvoice,
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        DropdownButtonFormField<DateTime>(
          key: ValueKey(_period),
          initialValue: _period,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tháng theo dõi',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
          items: [
            for (final month in months)
              DropdownMenuItem(value: month, child: Text(landlordMonth(month))),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _period = value;
                _roomPage = 0;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        _BillingRoomKpis(
          total: totalRooms,
          occupied: occupiedRooms,
          vacant: vacantRooms,
        ),
        const SizedBox(height: 14),
        LandlordGlassCard(
          padding: const EdgeInsets.all(5),
          child: DefaultTabController(
            length: 2,
            initialIndex: _billingTab,
            child: TabBar(
              dividerColor: Colors.transparent,
              onTap: (value) => setState(() => _billingTab = value),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF45BCFF), propertyBlue],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: LandlordPalette.of(context).muted,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              tabs: [
                const Tab(text: 'Phòng trọ'),
                const Tab(text: 'Lịch sử hóa đơn'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_billingTab == 0) ...[
          TextField(
            controller: _search,
            onChanged: (value) => setState(() {
              _query = value;
              _roomPage = 0;
            }),
            decoration: InputDecoration(
              hintText: 'Tìm mã phòng, tên khách, số điện thoại',
              hintStyle: TextStyle(
                color: LandlordPalette.of(context).muted,
                fontSize: 12,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: LandlordPalette.of(context).muted,
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () => setState(() {
                        _query = '';
                        _roomPage = 0;
                        _search.clear();
                      }),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
              filled: true,
              fillColor: LandlordPalette.of(context).surface
                  .withValues(alpha: 0.85),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: LandlordPalette.of(context).line),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final floorPicker = DropdownButtonFormField<int>(
                key: ValueKey('${_store.property.id}:$_floor'),
                initialValue: _floor,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Lọc theo tầng',
                  prefixIcon: Icon(Icons.layers_outlined),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int>(child: Text('Tất cả các tầng')),
                  for (final floor in floorOptions)
                    DropdownMenuItem(value: floor, child: Text('Tầng $floor')),
                ],
                onChanged: (value) => setState(() {
                  _floor = value;
                  _roomPage = 0;
                }),
              );
              final toggle = _BillingRoomViewToggle(
                grid: _grid,
                onList: () => setState(() => _grid = false),
                onGrid: () => setState(() => _grid = true),
              );
              return Row(
                children: [
                  Expanded(child: floorPicker),
                  const SizedBox(width: 6),
                  toggle,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (filter, count) in roomFilterOptions)
                  _BillingRoomFilterPill(
                    label: '$filter ($count)',
                    selected: _roomFilter == filter,
                    onTap: () => setState(() {
                      _roomFilter = filter;
                      _roomPage = 0;
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
                  'Hiển thị ${rooms.length} phòng · ${_store.property.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandlordPalette.of(context).muted,
                    fontSize: 11,
                  ),
                ),
              ),
              PopupMenuButton<_BillingRoomSort>(
                tooltip: 'Sắp xếp phòng',
                onSelected: (value) => setState(() {
                  _roomSort = value;
                  _roomPage = 0;
                }),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _BillingRoomSort.code,
                    child: Text('Theo mã phòng'),
                  ),
                  PopupMenuItem(
                    value: _BillingRoomSort.priceLow,
                    child: Text('Giá thấp trước'),
                  ),
                  PopupMenuItem(
                    value: _BillingRoomSort.priceHigh,
                    child: Text('Giá cao trước'),
                  ),
                  PopupMenuItem(
                    value: _BillingRoomSort.attention,
                    child: Text('Cần chú ý trước'),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sắp xếp',
                        style: TextStyle(
                          color: LandlordPalette.of(context).primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.unfold_more_rounded,
                        size: 16,
                        color: LandlordPalette.of(context).primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (rooms.isEmpty)
            const LandlordGlassCard(
              child: Text('Không có phòng phù hợp với bộ lọc.'),
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
                  for (final balance in rooms.skip(roomPage * 12).take(12))
                    SizedBox(
                      width: width,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: LandlordRoomButton(
                          key: ValueKey(balance.details.room.code),
                          details: balance.details,
                          highlight: _roomHighlight(balance),
                          compact: _grid,
                          secondaryText: [
                            if (balance.details.lease?.tenantName.isNotEmpty ==
                                true)
                              balance.details.lease!.tenantName,
                            'Tầng ${balance.details.room.floor}',
                          ].join(' · '),
                          valueText: balance.state == RoomPaymentState.vacant
                              ? null
                              : balance.pendingPayment != null
                              ? 'Chờ duyệt · ${formatLandlordMoney(balance.pendingPayment!.reportedAmount)}'
                              : balance.remaining > 0
                              ? 'Còn thiếu · ${formatLandlordMoney(balance.remaining)}'
                              : balance.state == RoomPaymentState.paid
                              ? 'Đã thu · ${formatLandlordMoney(balance.monthlyPaid)}'
                              : null,
                          onTap: () => _openRoomDetail(balance),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          ListPagination(
            total: rooms.length,
            page: roomPage,
            pageSize: 12,
            showBoundaryPages: true,
            onChanged: (value) => setState(() => _roomPage = value),
          ),
        ],
        if (_billingTab == 1) ...[
          const SizedBox(height: 4),
          LandlordGlassSection(
            title: 'Lịch sử hóa đơn',
            subtitle: '${_store.invoices.length} hóa đơn của nhà trọ',
            trailing: TextButton.icon(
              onPressed: _store.activeLeases.isEmpty ? null : _createInvoice,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Lập phiếu thu'),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in const [
                  'Tất cả',
                  'Chưa thanh toán',
                  'Thanh toán một phần',
                  'Đã thanh toán',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text('$label · ${_invoiceCount(label)}'),
                      selected: _filter == label,
                      onSelected: (_) => setState(() {
                        _filter = label;
                        _page = 0;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (invoices.isEmpty)
            const LandlordGlassCard(
              child: Text('Chưa có hóa đơn trong trạng thái này.'),
            ),
          for (final invoice in invoices.skip(page * _pageSize).take(_pageSize))
            _invoiceCard(invoice),
          ListPagination(
            total: invoices.length,
            page: page,
            pageSize: _pageSize,
            onChanged: (value) => setState(() => _page = value),
          ),
          const SizedBox(height: 8),
          Text(
            'Số tiền đã thu chỉ thay đổi khi chủ trọ xác nhận khoản thanh toán. Khoản nợ gồm cả hóa đơn chưa đóng từ các tháng trước.',
            style: TextStyle(
              color: LandlordPalette.of(context).muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ]);
    },
  );

  Widget _billingShell(BuildContext context, List<Widget> children) =>
      PropertyPortfolioBackdrop(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            key: PageStorageKey('landlord-billing-${_store.property.id}'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _billingHeader(context),
                    const SizedBox(height: 16),
                    _billingPropertyCard(context),
                    const SizedBox(height: 16),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _billingHeader(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: widget.store == null && widget.initialRoom == null
              ? 'Quay lại danh sách nhà trọ'
              : 'Quay lại',
          onPressed: widget.store == null && widget.initialRoom == null
              ? _returnToPropertyPicker
              : () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _store.property.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Chi tiết nhà trọ',
                style: TextStyle(color: palette.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Chỉnh sửa thông tin nhà trọ',
          onPressed: _editProperty,
          icon: const Icon(Icons.edit_outlined, color: propertyBlue),
        ),
      ],
    );
  }

  Widget _billingPropertyCard(BuildContext context) => LandlordGlassCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LandlordPropertyImage(
          url: _store.property.imageUrl,
          bytes: _store.property.imageBytes,
          height: MediaQuery.sizeOf(context).width >= 700 ? 220 : 150,
          borderRadius: 21,
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: propertyBlue,
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _store.property.address.isEmpty
                          ? 'Chưa cập nhật địa chỉ'
                          : _store.property.address,
                      style: TextStyle(
                        color: LandlordPalette.of(context).ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_store.catalog.length} phòng · ${_store.roomTypes.length} loại phòng',
                      style: TextStyle(
                        color: LandlordPalette.of(context).muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _openRoomDetail(LandlordRoomBalance balance) {
    final roomCode = balance.details.room.code;
    LandlordNavigation.push<void>(
      context,
      destinationId: 'billing',
      page: LandlordRoomFinanceDetailPage(
        store: _store,
        roomCode: roomCode,
        period: _period,
        onCreateReceipt: balance.details.lease?.isCurrent != true
            ? null
            : () => _createInvoice(initialLeaseId: balance.details.lease!.id),
      ),
    );
  }

  int _invoiceCount(String label) => _store.invoices.where((invoice) {
    if (label == 'Chưa thanh toán') {
      return invoice.status == LandlordInvoiceStatus.unpaid ||
          invoice.status == LandlordInvoiceStatus.overdue;
    }
    if (label == 'Thanh toán một phần') {
      return invoice.status == LandlordInvoiceStatus.partial;
    }
    if (label == 'Đã thanh toán') {
      return invoice.status == LandlordInvoiceStatus.paid;
    }
    return true;
  }).length;

  Widget _metric(
    String label,
    String value,
    IconData icon,
    Color color, {
    required double width,
  }) => Container(
    width: width,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          LandlordPalette.of(context).surface.withValues(alpha: 0.95),
          LandlordPalette.of(context).surface.withValues(alpha: 0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? LandlordPalette.of(context).line
            : Colors.white,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x125A7CBE),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: LandlordPalette.of(context).ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _invoiceCard(LandlordInvoice invoice) {
    final (label, color) = _invoiceStatus(invoice.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LandlordGlassCard(
        tint: color,
        onTap: () => _showDetails(invoice),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: landlordBlue.withValues(alpha: 0.1),
                  child: Icon(Icons.receipt_long_outlined, color: landlordBlue),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng ${invoice.room} · ${landlordMonth(invoice.period)}',
                        style: TextStyle(
                          color: LandlordPalette.of(context).ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${invoice.id} · ${invoice.tenantName}',
                        style: TextStyle(
                          color: LandlordPalette.of(context).muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                LandlordStatusPill(label, color: color),
              ],
            ),
            Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng cộng',
                    style: TextStyle(
                      color: LandlordPalette.of(context).muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  formatLandlordMoney(invoice.total),
                  style: TextStyle(
                    color: LandlordPalette.of(context).ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Còn lại · hạn ${landlordDate(invoice.dueDate)}',
                    style: TextStyle(
                      color: LandlordPalette.of(context).muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  formatLandlordMoney(invoice.remaining),
                  style: TextStyle(
                    color: invoice.remaining > 0
                        ? const Color(0xFFB17419)
                        : const Color(0xFF16836F),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _invoiceStatus(LandlordInvoiceStatus status) =>
      switch (status) {
        LandlordInvoiceStatus.unpaid => (
          'Chưa thanh toán',
          const Color(0xFFDA4458),
        ),
        LandlordInvoiceStatus.partial => (
          'Thanh toán một phần',
          const Color(0xFFDA4458),
        ),
        LandlordInvoiceStatus.paid => (
          'Đã thanh toán',
          const Color(0xFF16836F),
        ),
        LandlordInvoiceStatus.overdue => ('Quá hạn', const Color(0xFFD64545)),
        LandlordInvoiceStatus.cancelled => (
          'Đã hủy',
          LandlordPalette.of(context).muted,
        ),
      };

  Future<void> _showDetails(LandlordInvoice invoice) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      showDragHandle: true,
      builder: (context) {
        final (status, color) = _invoiceStatus(invoice.status);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.id,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: LandlordPalette.of(context).ink,
                        ),
                      ),
                    ),
                    LandlordStatusPill(status, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng ${invoice.room} · ${invoice.tenantName} · ${landlordMonth(invoice.period)}',
                  style: TextStyle(
                    color: LandlordPalette.of(context).muted,
                    fontSize: 12,
                  ),
                ),
                Divider(height: 24),
                for (final charge in invoice.charges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            charge.name,
                            style: TextStyle(
                              color: LandlordPalette.of(context).ink,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          formatLandlordMoney(charge.amount),
                          style: TextStyle(
                            color: LandlordPalette.of(context).ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Divider(height: 20),
                _summaryRow('Tổng cộng', invoice.total, bold: true),
                const SizedBox(height: 8),
                _summaryRow('Đã xác nhận', invoice.paidAmount),
                const SizedBox(height: 8),
                _summaryRow('Còn phải thu', invoice.remaining, bold: true),
                const SizedBox(height: 15),
                if (invoice.paidAmount == 0 &&
                    invoice.status != LandlordInvoiceStatus.cancelled)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Hủy hóa đơn?'),
                            content: Text(
                              'Hóa đơn sẽ được giữ trong lịch sử với trạng thái đã hủy.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Quay lại'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Hủy hóa đơn'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            _store.cancelInvoice(invoice);
                            if (context.mounted) Navigator.pop(context);
                          } on ArgumentError catch (error) {
                            if (context.mounted) {
                              showLandlordMessage(
                                context,
                                error.message.toString(),
                              );
                            }
                          }
                        }
                      },
                      icon: Icon(Icons.cancel_outlined),
                      label: Text('Hủy hóa đơn'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, int amount, {bool bold = false}) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: bold
                ? LandlordPalette.of(context).ink
                : LandlordPalette.of(context).muted,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
      ),
      Text(
        formatLandlordMoney(amount),
        style: TextStyle(
          color: LandlordPalette.of(context).ink,
          fontSize: bold ? 14 : 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );

  Future<void> _createInvoice({String? initialLeaseId}) async {
    final draft = await showDialog<_InvoiceDraft>(
      context: context,
      builder: (_) => _InvoiceEditor(
        leases: _store.activeLeases,
        store: _store,
        initialLeaseId: initialLeaseId,
        period: _period,
        lockPeriod: initialLeaseId != null,
      ),
    );
    if (draft == null || !mounted) return;
    final lease = _store.leaseById(draft.leaseId);
    if (lease == null) return;
    final charges = <LandlordInvoiceCharge>[
      LandlordInvoiceCharge(name: 'Tiền thuê phòng', amount: lease.monthlyRent),
      if (draft.electricKwh > 0)
        LandlordInvoiceCharge(
          name: 'Điện · ${draft.electricKwh} kWh',
          amount: draft.electricKwh * lease.electricityPrice,
        ),
      if ((lease.waterType == 'Theo tháng' ||
              lease.waterType == 'Theo người') &&
          lease.waterPrice > 0)
        LandlordInvoiceCharge(
          name: lease.waterType == 'Theo người'
              ? 'Nước · ${lease.occupantCount} người'
              : 'Nước · theo tháng',
          amount: lease.waterPrice *
              (lease.waterType == 'Theo người' ? lease.occupantCount : 1),
        )
      else if (draft.waterM3 > 0)
        LandlordInvoiceCharge(
          name: 'Nước · ${draft.waterM3} m³',
          amount: draft.waterM3 * lease.waterPrice,
        ),
      if (lease.vehicleFee > 0)
        LandlordInvoiceCharge(name: 'Tiền xe', amount: lease.vehicleFee),
      if (lease.serviceFee > 0)
        LandlordInvoiceCharge(name: 'Tiền dịch vụ', amount: lease.serviceFee),
      if (draft.extraFee > 0)
        LandlordInvoiceCharge(
          name: draft.extraName.isEmpty ? 'Khoản thu khác' : draft.extraName,
          amount: draft.extraFee,
        ),
    ];
    try {
      final invoice = _store.createInvoice(
        lease: lease,
        period: draft.period,
        dueDate: draft.dueDate,
        charges: charges,
      );
      setState(() {
        _period = draft.period;
        _roomPage = 0;
      });
      showLandlordMessage(
        context,
        'Đã lập phiếu thu ${invoice.id} · ${formatLandlordMoney(invoice.total)}.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }
}

class _BillingRoomKpis extends StatelessWidget {
  const _BillingRoomKpis({
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
          _BillingRoomKpi(
            label: 'Tổng phòng',
            value: '$total',
            unit: 'phòng',
            color: palette.primary,
          ),
          const SizedBox(width: 6),
          _BillingRoomKpi(
            label: 'Đang thuê',
            value: '$occupied',
            unit: 'căn',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          _BillingRoomKpi(
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

class _BillingRoomKpi extends StatelessWidget {
  const _BillingRoomKpi({
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

class _BillingRoomViewToggle extends StatelessWidget {
  const _BillingRoomViewToggle({
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

class _BillingRoomFilterPill extends StatelessWidget {
  const _BillingRoomFilterPill({
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

class _InvoiceDraft {
  const _InvoiceDraft({
    required this.leaseId,
    required this.period,
    required this.dueDate,
    required this.electricKwh,
    required this.waterM3,
    required this.extraName,
    required this.extraFee,
  });
  final String leaseId;
  final DateTime period;
  final DateTime dueDate;
  final int electricKwh;
  final int waterM3;
  final String extraName;
  final int extraFee;
}

class _InvoiceEditor extends StatefulWidget {
  const _InvoiceEditor({
    required this.leases,
    required this.store,
    this.initialLeaseId,
    this.period,
    this.lockPeriod = false,
  });
  final List<LandlordLease> leases;
  final LandlordDemoStore store;
  final String? initialLeaseId;
  final DateTime? period;
  final bool lockPeriod;

  @override
  State<_InvoiceEditor> createState() => _InvoiceEditorState();
}

class _InvoiceEditorState extends State<_InvoiceEditor> {
  late String _leaseId = widget.initialLeaseId ?? widget.leases.first.id;
  late DateTime _period =
      widget.period ?? DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _dueDate = _dueDateFor(_period, _lease.dueDay);
  final _electric = TextEditingController();
  final _water = TextEditingController();
  final _extraName = TextEditingController();
  final _extra = TextEditingController();

  LandlordLease get _lease =>
      widget.leases.firstWhere((item) => item.id == _leaseId);

  DateTime _dueDateFor(DateTime period, int day) {
    final lastDay = DateTime(period.year, period.month + 1, 0).day;
    return DateTime(period.year, period.month, day > lastDay ? lastDay : day);
  }

  @override
  void dispose() {
    _electric.dispose();
    _water.dispose();
    _extraName.dispose();
    _extra.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadReading();
  }

  void _loadReading() {
    final reading = widget.store.readingForRoom(_lease.room, _period);
    _electric.text = reading?.newElectric == null
        ? ''
        : reading!.electricUsage.toString();
    _water.text = reading?.newWater == null
        ? ''
        : reading!.waterUsage.toString();
  }

  List<DateTime> get _periods {
    final now = DateTime.now();
    return {
      _period,
      for (var offset = -2; offset <= 1; offset++)
        DateTime(now.year, now.month + offset),
    }.toList()..sort((a, b) => a.compareTo(b));
  }

  @override
  Widget build(BuildContext context) {
    final periodByKey = {for (final period in _periods) _key(period): period};
    final electricKwh = int.tryParse(_electric.text.trim()) ?? 0;
    final waterM3 = int.tryParse(_water.text.trim()) ?? 0;
    final extraFee = int.tryParse(_extra.text.trim()) ?? 0;
    final estimatedTotal =
        _lease.monthlyRent +
        electricKwh * _lease.electricityPrice +
        (_lease.waterType == 'Theo tháng'
            ? _lease.waterPrice
            : _lease.waterType == 'Theo người'
            ? _lease.waterPrice * _lease.occupantCount
            : waterM3 * _lease.waterPrice) +
        _lease.vehicleFee +
        _lease.serviceFee +
        extraFee;
    return AlertDialog(
      title: Text('Lập phiếu thu'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chọn hợp đồng, nhập chỉ số tiêu thụ và kiểm tra tổng tiền trước khi phát hành.',
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              _sectionLabel('HỢP ĐỒNG VÀ KỲ THU'),
              DropdownButtonFormField<String>(
                initialValue: _leaseId,
                decoration: InputDecoration(labelText: 'Hợp đồng / phòng'),
                items: [
                  for (final lease in widget.leases)
                    DropdownMenuItem(
                      value: lease.id,
                      child: Text('${lease.room} · ${lease.tenantName}'),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _leaseId = value ?? _leaseId;
                  _loadReading();
                  _dueDate = _dueDateFor(_period, _lease.dueDay);
                }),
              ),
              DropdownButtonFormField<String>(
                initialValue: _key(_period),
                decoration: InputDecoration(labelText: 'Kỳ hóa đơn'),
                items: [
                  for (final period in widget.lockPeriod ? [_period] : _periods)
                    DropdownMenuItem(
                      value: _key(period),
                      child: Text(landlordMonth(period)),
                    ),
                ],
                onChanged: widget.lockPeriod
                    ? null
                    : (value) => setState(() {
                        _period = periodByKey[value] ?? _period;
                        _loadReading();
                        _dueDate = _dueDateFor(_period, _lease.dueDay);
                      }),
              ),
              const SizedBox(height: 12),
              LandlordCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    _contractChargeLine(
                      'Tiền thuê phòng',
                      formatLandlordMoney(_lease.monthlyRent),
                    ),
                    _contractChargeLine(
                      'Đơn giá điện',
                      '${formatLandlordMoney(_lease.electricityPrice)}/kWh',
                    ),
                    _contractChargeLine(
                      'Tiền xe',
                      '${formatLandlordMoney(_lease.vehicleFee)}/tháng',
                    ),
                    _contractChargeLine(
                      'Tiền dịch vụ',
                      '${formatLandlordMoney(_lease.serviceFee)}/tháng',
                    ),
                  ],
                ),
              ),
              _sectionLabel('CHỈ SỐ TIÊU THỤ'),
              TextField(
                controller: _electric,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Điện tiêu thụ (kWh)',
                  helperText:
                      '${formatLandlordMoney(_lease.electricityPrice)}/kWh',
                ),
              ),
              if (_lease.waterType == 'Theo m³')
                TextField(
                  controller: _water,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nước tiêu thụ (m³)',
                    helperText: '${formatLandlordMoney(_lease.waterPrice)}/m³',
                  ),
                ),
              if (_lease.waterType == 'Theo tháng' ||
                  _lease.waterType == 'Theo người')
                _contractChargeLine(
                  'Tiền nước',
                  _lease.waterType == 'Theo người'
                      ? '${formatLandlordMoney(_lease.waterPrice)}/người × ${_lease.occupantCount}'
                      : '${formatLandlordMoney(_lease.waterPrice)}/tháng',
                ),
              _sectionLabel('KHOẢN THU THÊM'),
              TextField(
                controller: _extraName,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Tên khoản thu',
                  hintText: 'Ví dụ: Vệ sinh thêm',
                ),
              ),
              TextField(
                controller: _extra,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: 'Số tiền (đ)'),
              ),
              _sectionLabel('THỜI HẠN'),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày đến hạn',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(landlordDate(_dueDate)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2B5FB9), landlordBlue],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TỔNG TẠM TÍNH',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kiểm tra trước khi phát hành',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        formatLandlordMoney(estimatedTotal),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Đơn giá, tiền xe và dịch vụ lấy từ hợp đồng đang chọn.',
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
        FilledButton(onPressed: _save, child: Text('Phát hành hóa đơn')),
      ],
    );
  }

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 2),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: landlordBlue,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    ),
  );

  Widget _contractChargeLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: LandlordPalette.of(context).muted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  int? _amount(TextEditingController controller) {
    if (controller.text.trim().isEmpty) return 0;
    final value = int.tryParse(controller.text.trim());
    return value != null && value >= 0 ? value : null;
  }

  void _save() {
    final electric = _amount(_electric);
    final water = _amount(_water);
    final extra = _amount(_extra);
    if ([electric, water, extra].contains(null)) {
      showLandlordMessage(
        context,
        'Vui lòng nhập số lượng và khoản thu hợp lệ.',
      );
      return;
    }
    Navigator.pop(
      context,
      _InvoiceDraft(
        leaseId: _leaseId,
        period: _period,
        dueDate: _dueDate,
        electricKwh: electric!,
        waterM3: water!,
        extraName: _extraName.text.trim(),
        extraFee: extra!,
      ),
    );
  }
}
