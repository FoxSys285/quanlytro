import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../data/app_persistence.dart';
import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';
import '../../shared/settings/account_settings_page.dart';
import '../landlord_theme.dart';

import '../landlord_demo_store.dart';
import '../landlord_ui.dart';
import '../rooms/models/landlord_room.dart';
import 'landlord_property_detail_page.dart';
import 'components/landlord_property_editor.dart';
import 'components/property_portfolio_visuals.dart';
import 'components/landlord_property_image.dart';
import 'models/landlord_property.dart';

class PropertyPortfolioPage extends StatefulWidget {
  const PropertyPortfolioPage({super.key, this.profileName});
  final String? profileName;
  @override
  State<PropertyPortfolioPage> createState() => _PropertyPortfolioPageState();
}

class _PropertyPortfolioPageState extends State<PropertyPortfolioPage> {
  String _query = '';
  String _filter = 'Tất cả';
  bool _saving = false;
  String? _selectedPropertyId;
  RentalPortfolio get _portfolio => RentalPortfolio.instance;

  void _openProperty(LandlordDemoStore store) {
    _portfolio.select(store.property.id);
    setState(() => _selectedPropertyId = store.property.id);
  }

  Widget _propertyDetail(LandlordDemoStore store) => LandlordPropertyDetailPage(
    store: store,
    onBack: () => setState(() => _selectedPropertyId = null),
    onEdit: () => _edit(store),
  );

  Future<void> _save(String message) async {
    setState(() => _saving = true);
    try {
      final persistence = AppPersistence.current;
      await persistence?.saveChanges();
      if (!mounted) return;
      showLandlordMessage(
        context,
        persistence?.cloudConfirmed == true
            ? '$message Đã lưu lên Firebase.'
            : '$message Đã lưu trên máy.',
      );
    } catch (error) {
      if (mounted) showLandlordMessage(context, '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(LandlordDemoStore store) async {
    final property = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(property: store.property),
    );
    if (!mounted || property == null) return;
    store.updateProperty(property);
    await _save('Đã cập nhật ${property.name}.');
  }

  Future<void> _add() async {
    final session = LocalAuth.instance.session;
    if (LocalAuth.instance.isCloudMode && session == null) {
      showLandlordMessage(
        context,
        'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.',
      );
      return;
    }
    final property = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(
        creating: true,
        property: LandlordProperty(
          id: _portfolio.stores.isEmpty && session != null
              ? session.uid
              : 'property-${DateTime.now().microsecondsSinceEpoch}',
          name: '',
          address: '',
          ownerName:
              session?.displayName ??
              (_portfolio.stores.isEmpty
                  ? widget.profileName ?? ''
                  : _portfolio.active.property.ownerName),
          phone: _portfolio.stores.isEmpty
              ? ''
              : _portfolio.active.property.phone,
          phoneIsSynthetic:
              _portfolio.stores.isNotEmpty &&
              _portfolio.active.property.phoneIsSynthetic,
          description: '',
          city: _portfolio.stores.isEmpty
              ? ''
              : _portfolio.active.property.city,
          ward: _portfolio.stores.isEmpty
              ? ''
              : _portfolio.active.property.ward,
        ),
      ),
    );
    if (!mounted || property == null) return;
    if (_portfolio.stores.isEmpty) {
      try {
        _portfolio.createSingleProperty(property);
        await _save(
          'Đã tạo nhà trọ. Hãy thêm loại phòng và phòng trọ của bạn.',
        );
      } on ArgumentError catch (error) {
        if (mounted) showLandlordMessage(context, error.message.toString());
      }
      return;
    }
    var floors = 3;
    var rooms = 6;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Thiết lập tầng và phòng'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${property.name} · ${floors * rooms} phòng sẽ được tạo tự động',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: floors,
                  decoration: const InputDecoration(labelText: 'Số tầng'),
                  items: [
                    for (var i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text('$i tầng')),
                  ],
                  onChanged: (v) => setDialogState(() => floors = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: rooms,
                  decoration: const InputDecoration(
                    labelText: 'Phòng mỗi tầng',
                  ),
                  items: [
                    for (var i = 1; i <= 20; i++)
                      DropdownMenuItem(value: i, child: Text('$i phòng')),
                  ],
                  onChanged: (v) => setDialogState(() => rooms = v!),
                ),
                const SizedBox(height: 12),
                Text(
                  'Có thể sửa từng phòng và bảng giá sau khi tạo.',
                  style: TextStyle(color: LandlordPalette.of(context).muted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Tạo nhà trọ'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    _portfolio.add(property, floors: floors, roomsPerFloor: rooms);
    await _save('Đã thêm ${property.name}.');
  }

  Future<void> _delete(LandlordDemoStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa nhà trọ'),
        content: Text(
          'Xóa ${store.property.name} và danh sách phòng chưa có hợp đồng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      _portfolio.remove(store.property.id);
      await _save('Đã xóa ${store.property.name}.');
    } on ArgumentError catch (e) {
      if (mounted) showLandlordMessage(context, e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_portfolio, AdminStore.instance]),
    builder: (context, _) {
      final selectedStore = _selectedPropertyId == null
          ? null
          : _portfolio.byId(_selectedPropertyId!);
      if (selectedStore != null) return _propertyDetail(selectedStore);
      final stores = _portfolio.stores.where((store) {
        final matchesSearch = '${store.property.name} ${store.property.address}'
            .toLowerCase()
            .contains(_query.toLowerCase());
        final hasOccupiedRoom = store.roomDetails.any(
          (room) => room.status == LandlordRoomStatus.occupied,
        );
        final hasVacantRoom = store.roomDetails.any(
          (room) => room.status == LandlordRoomStatus.vacant,
        );
        final matchesFilter = switch (_filter) {
          'Đang thuê' => hasOccupiedRoom,
          'Còn phòng' => hasVacantRoom,
          _ => true,
        };
        return matchesSearch && matchesFilter;
      }).toList();
      final profileName =
          widget.profileName ??
          LocalAuth.instance.session?.displayName ??
          (_portfolio.active.property.ownerName.trim().isEmpty
              ? 'Chủ trọ'
              : _portfolio.active.property.ownerName);
      final palette = LandlordPalette.of(context);
      final dark = Theme.of(context).brightness == Brightness.dark;
      return PropertyPortfolioBackdrop(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            key: const PageStorageKey('landlord-property-portfolio'),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PropertyProfileHeader(
                      name: profileName,
                      onMenu: () => Scaffold.of(context).openDrawer(),
                      onActiveProperty: () {
                        if (_portfolio.stores.isNotEmpty) {
                          _openProperty(_portfolio.active);
                        } else {
                          _add();
                        }
                      },
                      onSettings: () {
                        if (!RoleLayoutShell.navigateTo(context, 'settings')) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const Scaffold(
                                body: AccountSettingsPage(
                                  role: AppRole.landlord,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    PropertyPortfolioIntro(
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x155D6FE8),
                                  blurRadius: 22,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 12,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tìm tên hoặc địa chỉ nhà trọ',
                                hintStyle: const TextStyle(
                                  color: propertyMuted,
                                  fontSize: 12,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF7180A4),
                                  size: 25,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 48,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: palette.surface.withValues(
                                  alpha: dark ? 0.9 : 0.76,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: Color(0x70FFFFFF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                    color: propertyBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        PopupMenuButton<String>(
                          tooltip: 'Lọc nhà trọ',
                          initialValue: _filter,
                          onSelected: (value) =>
                              setState(() => _filter = value),
                          itemBuilder: (_) => [
                            for (final filter in const [
                              'Tất cả',
                              'Đang thuê',
                              'Còn phòng',
                            ])
                              CheckedPopupMenuItem(
                                value: filter,
                                checked: _filter == filter,
                                child: Text(filter),
                              ),
                          ],
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: dark
                                    ? [palette.surface, palette.surfaceAlt]
                                    : [
                                        const Color(0xFFF1F7FF),
                                        const Color(0xFFCDE1FF),
                                      ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x125D6FE8),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _filter == 'Tất cả'
                                  ? const Color(0xFF4278B9)
                                  : propertyBlue,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_filter != 'Tất cả')
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          label: Text(_filter),
                          onDeleted: () => setState(() => _filter = 'Tất cả'),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Center(
                      child: PropertyPortfolioActionButton(
                        label: 'Thêm nhà trọ',
                        disabledLabel: 'Đang lưu...',
                        icon: Icons.add_rounded,
                        onTap: _saving ? null : _add,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (stores.isEmpty)
                      LandlordEmptyState(
                        message: _portfolio.stores.isEmpty
                            ? 'Chưa có nhà trọ. Thêm nhà trọ để bắt đầu quản lý.'
                            : 'Không tìm thấy nhà trọ phù hợp.',
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 960
                            ? 3
                            : constraints.maxWidth >= 640
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 16) /
                            columns;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 18,
                          children: [
                            for (final store in stores)
                              SizedBox(width: width, child: _card(store)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _card(LandlordDemoStore store) {
    final property = store.property;
    final palette = LandlordPalette.of(context);
    final rooms = store.roomDetails;
    final occupiedCount = rooms
        .where((room) => room.status == LandlordRoomStatus.occupied)
        .length;
    final vacantCount = rooms
        .where((room) => room.status == LandlordRoomStatus.vacant)
        .length;
    final illustrative =
        property.imageBytes == null && property.imageUrl.isEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x255D7BBA),
            blurRadius: 23,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProperty(store),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  LandlordPropertyImage(
                    url: property.imageUrl,
                    bytes: property.imageBytes,
                    height: 138,
                    borderRadius: 19,
                    showIllustrationLabel: false,
                  ),
                  Positioned(
                    top: 14,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xAA473626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            illustrative ? 'Ảnh minh họa' : 'Ảnh nhà trọ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 9, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            property.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: propertyMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 34,
                      child: PopupMenuButton<String>(
                        tooltip: 'Tùy chọn nhà trọ',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 130),
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: palette.muted,
                          size: 20,
                        ),
                        onSelected: (value) =>
                            value == 'edit' ? _edit(store) : _delete(store),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Chỉnh sửa'),
                          ),
                          if (store.leases.isEmpty)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa nhà trọ'),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.primarySoft,
                      ),
                      child: IconButton(
                        tooltip: 'Xem phòng',
                        padding: EdgeInsets.zero,
                        onPressed: () => _openProperty(store),
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          color: propertyBlue,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 13),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _propertyStat(
                      '${store.catalog.length} phòng',
                      Icons.meeting_room_outlined,
                    ),
                    _propertyStat(
                      '$occupiedCount đang thuê',
                      Icons.people_alt_outlined,
                    ),
                    _propertyStat(
                      '$vacantCount còn trống',
                      Icons.door_front_door_outlined,
                    ),
                  ],
                ),
              ),
              if (AdminStore.instance.reviewNote(property.id).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Text(
                    'Yêu cầu từ quản trị viên: ${AdminStore.instance.reviewNote(property.id)}',
                    style: const TextStyle(
                      color: Color(0xFF9B651A),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _propertyStat(String label, IconData icon) {
    final palette = LandlordPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: palette.ink,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
