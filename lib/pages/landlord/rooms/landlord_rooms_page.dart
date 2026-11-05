import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../layouts/landlord_navigation.dart';
import '../../../layouts/role_layout.dart';
import '../../shared/rental/room_image_gallery.dart';
import '../../shared/widgets/google_maps_actions.dart';
import '../../shared/widgets/list_pagination.dart';
import '../billing/landlord_billing_page.dart';
import '../announcements/landlord_announcements_page.dart';
import '../finance/landlord_finance_models.dart';
import '../incidents/landlord_yeucausuachua_page.dart';
import '../incidents/models/landlord_suco.dart';
import '../landlord_demo_store.dart';
import '../landlord_compact_header.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import '../leases/landlord_leases_page.dart';
import '../meter_readings/landlord_chisodiennuoc_page.dart';
import '../viewings/landlord_viewings_page.dart';
import 'components/landlord_room_button.dart';
import 'components/landlord_room_card.dart';
import 'components/landlord_room_editor.dart';
import 'models/landlord_room.dart';

enum _RoomFilter { all, vacant, occupied, unpaid, expiring, maintenance }

enum _RoomSort { code, priceLow, priceHigh, attention }

class LandlordRoomsPage extends StatefulWidget {
  const LandlordRoomsPage({
    super.key,
    this.store,
    this.showHeader = false,
    this.dark = false,
    this.onToggleTheme,
  });
  final LandlordDemoStore? store;
  final bool showHeader;
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

  Future<void> _delete(LandlordRoom room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa phòng ${room.code}?'),
        content: const Text('Chỉ có thể xóa phòng chưa có lịch sử hợp đồng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa phòng'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      _store.deleteRoom(room.code);
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  void _openPage(String title, Widget page) {
    final destination = switch (page) {
      LandlordLeasesPage() => 'leases',
      LandlordBillingPage() => 'billing',
      LandlordChiSoDienNuocPage() => 'meter_readings',
      LandlordViewingsPage() => 'viewings',
      LandlordYeuCauSuaChuaPage() => 'incidents',
      LandlordAnnouncementsPage() => 'announcements',
      _ => 'rooms',
    };
    LandlordNavigation.push<void>(
      context,
      title: title,
      page: page,
      destinationId: destination,
    );
  }

  Future<void> _openContact(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        showLandlordMessage(context, 'Không thể mở ứng dụng liên hệ.');
      }
    } catch (_) {
      if (mounted) {
        showLandlordMessage(context, 'Không thể mở ứng dụng liên hệ.');
      }
    }
  }

  void _showRoom(String code) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final details = _store.roomDetails.firstWhere(
            (item) => item.room.code == code,
          );
          final lease = details.lease;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chi tiết phòng',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng chi tiết',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  RoomImageGallery(images: details.type?.images ?? const []),
                  const SizedBox(height: 12),
                  LandlordRoomCard(
                    details: details,
                    onEdit: () {
                      Navigator.pop(context);
                      _edit(details.room);
                    },
                    onDelete: _canDelete(details.room)
                        ? () {
                            Navigator.pop(context);
                            _delete(details.room);
                          }
                        : null,
                  ),
                  Text(
                    _store.property.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(_store.property.address),
                  GoogleMapsActions(address: _store.property.address),
                  const SizedBox(height: 12),
                  Text(_store.property.description),
                  if (lease != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Hợp đồng & người thuê',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('Mã hợp đồng: ${lease.id}'),
                    Text('Liên hệ: ${lease.phone}'),
                    Text(
                      'Thời hạn: ${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
                    ),
                    Text('Đặt cọc: ${formatLandlordMoney(lease.deposit)}'),
                    Text('Thanh toán: ngày ${lease.dueDay} hằng tháng'),
                    for (final member in _store.membersForLease(lease.id))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(member.name),
                        subtitle: Text(member.phone),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _canDelete(LandlordRoom room) => !_store.leases.any(
    (lease) =>
        _store.canonicalRoom(lease.room) == _store.canonicalRoom(room.code),
  );

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
    final lease = details.lease;
    if (highlight == LandlordRoomHighlight.overdue && lease != null) {
      final phone = lease.phone.replaceAll(RegExp(r'\D'), '');
      return [
        LandlordRoomAction(
          label: 'Gọi',
          icon: Icons.call_outlined,
          onTap: () => _openContact(Uri(scheme: 'tel', path: phone)),
        ),
        LandlordRoomAction(
          label: 'Nhắc qua Zalo',
          icon: Icons.message_outlined,
          primary: true,
          onTap: () => _openContact(Uri.parse('https://zalo.me/$phone')),
        ),
      ];
    }
    if (highlight == LandlordRoomHighlight.vacant) {
      return [
        LandlordRoomAction(
          label: 'Lịch xem',
          icon: Icons.calendar_month_outlined,
          onTap: () =>
              _openPage('Lịch xem phòng', const LandlordViewingsPage()),
        ),
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
      ];
    }
    if (highlight == LandlordRoomHighlight.maintenance) {
      return [
        LandlordRoomAction(
          label: 'Xem sự cố',
          icon: Icons.handyman_outlined,
          primary: true,
          onTap: () =>
              _openPage('Yêu cầu sửa chữa', const LandlordYeuCauSuaChuaPage()),
        ),
        LandlordRoomAction(
          label: 'Chi tiết',
          icon: Icons.open_in_new_rounded,
          onTap: () => _showRoom(details.room.code),
        ),
      ];
    }
    if (highlight == LandlordRoomHighlight.expiring ||
        highlight == LandlordRoomHighlight.upcoming) {
      return [
        LandlordRoomAction(
          label: 'Hợp đồng',
          icon: Icons.description_outlined,
          onTap: () => _openPage('Hợp đồng thuê', const LandlordLeasesPage()),
        ),
        LandlordRoomAction(
          label: 'Chi tiết',
          icon: Icons.open_in_new_rounded,
          primary: true,
          onTap: () => _showRoom(details.room.code),
        ),
      ];
    }
    return [
      LandlordRoomAction(
        label: 'Chỉ số',
        icon: Icons.bolt_outlined,
        onTap: () =>
            _openPage('Chỉ số điện nước', const LandlordChiSoDienNuocPage()),
      ),
      LandlordRoomAction(
        label: 'Hóa đơn',
        icon: Icons.receipt_long_outlined,
        primary: true,
        onTap: () => _openPage('Hóa đơn', const LandlordBillingPage()),
      ),
    ];
  }

  Future<void> _copyList(List<LandlordRoomDetails> rooms) async {
    final rows = <String>[
      'Mã phòng,Tầng,Loại phòng,Trạng thái,Giá thuê,Người thuê',
    ];
    String csv(String value) => '"${value.replaceAll('"', '""')}"';
    for (final details in rooms) {
      rows.add(
        [
          csv(details.room.code),
          '${details.room.floor}',
          csv(details.typeName),
          csv(details.status.label),
          '${details.monthlyRent ?? 0}',
          csv(details.lease?.tenantName ?? ''),
        ].join(','),
      );
    }
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (mounted) {
      showLandlordMessage(
        context,
        'Đã sao chép danh sách ${rooms.length} phòng.',
      );
    }
  }

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

      return Stack(
        children: [
          LandlordPageFrame(
            children: [
              if (widget.showHeader) ...[
                LandlordCompactHeader(
                  store: _store,
                  dark: widget.dark,
                  onToggleTheme: widget.onToggleTheme,
                  onNotifications: () {
                    if (!RoleLayoutShell.tryNavigateTo(
                      context,
                      'announcements',
                    )) {
                      _openPage('Thông báo', const LandlordAnnouncementsPage());
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              _RoomsHero(
                propertyName: _store.property.name,
                address: _store.property.address,
                onAdd: () => _edit(),
                onSearch: () => _searchFocus.requestFocus(),
              ),
              const SizedBox(height: 13),
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
                  fillColor: palette.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
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
                        const DropdownMenuItem<int>(
                          child: Text('Tất cả các tầng'),
                        ),
                        for (final floor in floors)
                          DropdownMenuItem(
                            value: floor,
                            child: Text('Tầng $floor'),
                          ),
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
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
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
                                  invoice: invoice,
                                  incident: incident,
                                  compact: _grid,
                                  actions: _actionsFor(details, highlight),
                                  onTap: () => _showRoom(details.room.code),
                                  onEdit: () => _edit(details.room),
                                  onDelete: _canDelete(details.room)
                                      ? () => _delete(details.room)
                                      : null,
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
              const SizedBox(height: 102),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _RoomActionDock(
                  onAdd: () => _edit(),
                  onMeters: () => _openPage(
                    'Chỉ số điện nước',
                    const LandlordChiSoDienNuocPage(),
                  ),
                  onCopy: () => _copyList(matches),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _RoomsHero extends StatelessWidget {
  const _RoomsHero({
    required this.propertyName,
    required this.address,
    required this.onAdd,
    required this.onSearch,
  });
  final String propertyName;
  final String address;
  final VoidCallback onAdd;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D4ED8), Color(0xFF2A60D6), Color(0xFF183B96)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x281D4ED8),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -20,
          top: -42,
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x22FFFFFF), width: 34),
            ),
          ),
        ),
        Positioned(
          right: 22,
          bottom: 10,
          child: Wrap(
            spacing: 14,
            runSpacing: 11,
            children: [
              for (var i = 0; i < 12; i++)
                const CircleAvatar(
                  radius: 2,
                  backgroundColor: Color(0x33FFFFFF),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x28FFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '▣  QUẢN LÝ KHÔNG GIAN',
                  style: TextStyle(
                    color: Color(0xFFDBEAFE),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Danh sách phòng trọ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFD7E5FF),
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '$propertyName · $address',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE1EBFF),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Thêm phòng mới',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Tìm phòng',
                    onPressed: onSearch,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x33FFFFFF),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.search_rounded, size: 19),
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
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(12),
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
        color: selected ? palette.primary : palette.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? palette.primary : palette.line),
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

class _RoomActionDock extends StatelessWidget {
  const _RoomActionDock({
    required this.onAdd,
    required this.onMeters,
    required this.onCopy,
  });
  final VoidCallback onAdd;
  final VoidCallback onMeters;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFF27364D),
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3B16243B),
          blurRadius: 19,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        _DockAction(
          label: 'Thêm phòng',
          icon: Icons.add_home_rounded,
          selected: true,
          onTap: onAdd,
        ),
        _DockAction(
          label: 'Ghi điện nước',
          icon: Icons.edit_note_rounded,
          selected: false,
          onTap: onMeters,
        ),
        _DockAction(
          label: 'Sao chép DS',
          icon: Icons.copy_rounded,
          selected: false,
          onTap: onCopy,
        ),
      ],
    ),
  );
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? const Color(0xFF2563EB) : Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFFC9D4E5),
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFC9D4E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
