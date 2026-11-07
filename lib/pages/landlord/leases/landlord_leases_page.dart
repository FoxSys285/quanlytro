import 'package:flutter/material.dart';

import '../../../layouts/landlord_navigation.dart';
import '../../../layouts/role_layout.dart';
import '../landlord_theme.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_ui.dart';
import '../services/models/landlord_service.dart';
import '../../shared/widgets/list_pagination.dart';
import 'models/landlord_lease_template.dart';

String _waterUnit(String waterType) => switch (waterType) {
  'Theo tháng' => 'tháng',
  'Theo người' => 'người',
  _ => 'm³',
};

String _waterTypeForService(LandlordService? service) {
  final unit = service?.unit.toLowerCase() ?? '';
  final basis = service?.basis.toLowerCase() ?? '';
  if (unit.contains('người') || basis.contains('người')) return 'Theo người';
  if (unit.contains('tháng') ||
      unit.contains('phòng') ||
      basis.contains('tháng') ||
      basis.contains('phòng')) {
    return 'Theo tháng';
  }
  return 'Theo m³';
}

bool _isElectricityService(LandlordService service) =>
    service.id == 'electricity' || service.name.toLowerCase().contains('điện');

bool _isWaterService(LandlordService service) =>
    service.id == 'water' || service.name.toLowerCase().contains('nước');

String _serviceQuantityDescription(LandlordLeaseService service) {
  final basis = service.basis.toLowerCase();
  if (basis.contains('người')) return ' × ${service.quantity} người';
  if (basis.contains('cái') || basis.contains('xe')) {
    return ' × ${service.quantity} ${service.unit}';
  }
  return '';
}

class LandlordLeasesPage extends StatefulWidget {
  const LandlordLeasesPage({
    super.key,
    this.createForRoom,
    this.store,
    this.openTemplateEditor = false,
  });

  final String? createForRoom;
  final LandlordDemoStore? store;
  final bool openTemplateEditor;

  @override
  State<LandlordLeasesPage> createState() => _LandlordLeasesPageState();
}

class _LandlordLeasesPageState extends State<LandlordLeasesPage> {
  LandlordDemoStore get _store =>
      widget.store ?? LandlordDemoStore.activeInstance;
  String _filter = 'Tất cả';
  int _page = 0;
  static const _pageSize = 10;
  String _search = '';

  @override
  void initState() {
    super.initState();
    if (widget.createForRoom != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editLease();
      });
    } else if (widget.openTemplateEditor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editLeaseTemplate();
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final leases = _store.leases.where((lease) {
        final matchesSearch =
            lease.tenantName.toLowerCase().contains(_search.toLowerCase()) ||
            lease.room.toLowerCase().contains(_search.toLowerCase()) ||
            lease.id.toLowerCase().contains(_search.toLowerCase());
        final matchesFilter = switch (_filter) {
          'Đang thuê' => lease.isCurrent,
          'Sắp hết hạn' => lease.isExpiringSoon,
          'Sắp bắt đầu' => lease.isUpcoming,
          'Hết hạn' => lease.isExpired,
          'Nháp' => lease.status == LandlordLeaseStatus.draft,
          'Đã kết thúc' => lease.status == LandlordLeaseStatus.terminated,
          _ => true,
        };
        return matchesSearch && matchesFilter;
      }).toList()..sort((a, b) => a.endDate.compareTo(b.endDate));
      final currentCount = _store.activeLeases.length;
      final expiringCount = _store.leases
          .where((lease) => lease.isExpiringSoon)
          .length;
      final draftCount = _store.leases
          .where((lease) => lease.status == LandlordLeaseStatus.draft)
          .length;

      final page = _page.clamp(
        0,
        ListPagination.lastPage(leases.length, _pageSize),
      );
      final visible = leases.skip(page * _pageSize).take(_pageSize);
      return PropertyPortfolioBackdrop(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            key: const PageStorageKey('landlord-leases'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topBar(),
                    const SizedBox(height: 15),
                    _leaseHero(),
                    const SizedBox(height: 16),
                    _overviewPanel(currentCount, expiringCount, draftCount),
                    const SizedBox(height: 16),
                    _templatesPanel(),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _editLease(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tạo hợp đồng'),
                        style: FilledButton.styleFrom(
                          backgroundColor: landlordBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => setState(() {
                        _search = value.trim();
                        _page = 0;
                      }),
                      style: TextStyle(
                        color: LandlordPalette.of(context).ink,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm người thuê, phòng, mã hợp đồng',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: landlordBlue,
                        ),
                        filled: true,
                        fillColor: LandlordPalette.of(context).surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: .9),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: landlordBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final label in const [
                            'Tất cả',
                            'Đang thuê',
                            'Sắp hết hạn',
                            'Sắp bắt đầu',
                            'Hết hạn',
                            'Nháp',
                            'Đã kết thúc',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  '$label · ${_countForFilter(label)}',
                                ),
                                selected: _filter == label,
                                selectedColor: landlordBlue,
                                backgroundColor: LandlordPalette.of(context)
                                    .surface,
                                side: BorderSide(
                                  color: _filter == label
                                      ? Colors.transparent
                                      : Colors.white,
                                ),
                                labelStyle: TextStyle(
                                  color: _filter == label
                                      ? Colors.white
                                      : landlordBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                onSelected: (_) => setState(() {
                                  _filter = label;
                                  _page = 0;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (leases.isEmpty)
                      _emptyContracts()
                    else ...[
                      for (final lease in visible) _leaseCard(lease),
                      ListPagination(
                        total: leases.length,
                        page: page,
                        pageSize: _pageSize,
                        onChanged: (value) => setState(() => _page = value),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Thay đổi được đồng bộ lên Firebase và chia sẻ theo quyền tài khoản.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LandlordPalette.of(context).muted,
                        fontSize: 11,
                      ),
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

  Widget _topBar() => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Quay lại',
        onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            RoleLayoutShell.navigateTo(context, 'properties');
          }
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Hợp đồng thuê',
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Nhà trọ',
        onPressed: _openProperties,
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFFF3267),
          backgroundColor: Colors.white.withValues(alpha: .86),
        ),
        icon: const Icon(Icons.favorite_rounded),
      ),
    ],
  );

  void _openProperties() {
    if (RoleLayoutShell.navigateTo(context, 'properties')) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Widget _leaseHero() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Colors.white.withValues(alpha: .9)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          LandlordPalette.of(context).surface.withValues(alpha: .98),
          LandlordPalette.of(context).surfaceAlt.withValues(alpha: .8),
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x205A99E9),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF438EFF), landlordBlue],
            ),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: Colors.white,
            size: 33,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUẢN LÝ NHÀ TRỌ',
                style: TextStyle(
                  color: landlordBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Hợp đồng thuê',
                style: TextStyle(
                  color: LandlordPalette.of(context).ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Theo dõi hiệu lực và thời hạn hợp đồng.',
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _overviewPanel(
    int currentCount,
    int expiringCount,
    int draftCount,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF438EFF), Color(0xFF154BCC)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30366BDA),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tổng quan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .3)),
              ),
              child: const Text(
                'Tháng này',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            final width = (constraints.maxWidth - spacing * 2) / 3;
            return Wrap(
              spacing: spacing,
              children: [
                _overviewMetric(
                  width: width,
                  label: 'Đang hiệu lực',
                  value: '$currentCount',
                  icon: Icons.check_circle_outline_rounded,
                ),
                _overviewMetric(
                  width: width,
                  label: 'Sắp hết hạn',
                  value: '$expiringCount',
                  icon: Icons.event_busy_outlined,
                ),
                _overviewMetric(
                  width: width,
                  label: 'Bản nháp',
                  value: '$draftCount',
                  icon: Icons.drafts_outlined,
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _templatesPanel() => LandlordGlassCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.library_books_outlined, color: landlordBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hợp đồng mẫu (${_store.leaseTemplates.length})',
                style: TextStyle(
                  color: LandlordPalette.of(context).ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _editLeaseTemplate(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tạo mẫu'),
            ),
          ],
        ),
        if (_store.leaseTemplates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              'Chưa có mẫu. Tạo mẫu chung một lần để điền sẵn thông tin chủ trọ, phí và điều khoản khi lập hợp đồng.',
              style: TextStyle(
                color: LandlordPalette.of(context).muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          )
        else
          for (final template in _store.leaseTemplates)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: LandlordPalette.of(context).surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: LandlordPalette.of(context).line),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: landlordBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: TextStyle(
                              color: LandlordPalette.of(context).ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_store.serviceRecordById(template.electricityServiceId)?.name ?? 'Điện'} ${formatLandlordMoney(template.electricityPrice)}/${_store.serviceRecordById(template.electricityServiceId)?.unit ?? 'kWh'} · ${_store.serviceRecordById(template.waterServiceId)?.name ?? 'Nước'} ${formatLandlordMoney(template.waterPrice)}/${_store.serviceRecordById(template.waterServiceId)?.unit ?? _waterUnit(template.waterType)}',
                            style: TextStyle(
                              color: LandlordPalette.of(context).muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Chỉnh sửa mẫu',
                      onPressed: () => _editLeaseTemplate(template),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Xóa mẫu',
                      onPressed: () => _deleteLeaseTemplate(template),
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Tạo hợp đồng từ mẫu này',
                      onPressed: () => _editLease(initialTemplate: template),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    ),
                  ],
                ),
              ),
            ),
      ],
    ),
  );

  Widget _emptyContracts() => LandlordGlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE4EFFF),
            borderRadius: BorderRadius.circular(19),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: landlordBlue,
            size: 29,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _search.isEmpty && _filter == 'Tất cả'
              ? 'Chưa có hợp đồng thuê.'
              : 'Không có hợp đồng phù hợp.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => _editLease(),
          style: FilledButton.styleFrom(
            backgroundColor: landlordBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            elevation: 4,
            shadowColor: landlordBlue.withValues(alpha: .35),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tạo hợp đồng'),
        ),
      ],
    ),
  );

  int _countForFilter(String label) => switch (label) {
    'Đang thuê' => _store.leases.where((lease) => lease.isCurrent).length,
    'Sắp hết hạn' =>
      _store.leases.where((lease) => lease.isExpiringSoon).length,
    'Sắp bắt đầu' => _store.leases.where((lease) => lease.isUpcoming).length,
    'Hết hạn' => _store.leases.where((lease) => lease.isExpired).length,
    'Nháp' =>
      _store.leases
          .where((lease) => lease.status == LandlordLeaseStatus.draft)
          .length,
    'Đã kết thúc' =>
      _store.leases
          .where((lease) => lease.status == LandlordLeaseStatus.terminated)
          .length,
    _ => _store.leases.length,
  };

  Widget _overviewMetric({
    required double width,
    required String label,
    required String value,
    required IconData icon,
  }) => Container(
    width: width,
    padding: const EdgeInsets.fromLTRB(11, 12, 8, 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: Colors.white),
        const SizedBox(height: 9),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _leaseCard(LandlordLease lease) {
    final (status, color) = _leaseStatus(lease);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: LandlordGlassCard(
        padding: EdgeInsets.zero,
        onTap: () => _showLeaseDetails(lease),
        tint: color,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: landlordBlue.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: landlordBlue,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng ${lease.room}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: LandlordPalette.of(context).ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lease.tenantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: LandlordPalette.of(context).muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LandlordStatusPill(status, color: color),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                lease.id,
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Divider(height: 22, color: LandlordPalette.of(context).line),
              _detailLine(
                'Thời hạn',
                '${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
              ),
              const SizedBox(height: 8),
              _detailLine(
                'Tiền thuê',
                '${formatLandlordMoney(lease.monthlyRent)} / tháng',
              ),
              const SizedBox(height: 8),
              _detailLine('Tiền cọc', formatLandlordMoney(lease.deposit)),
              const SizedBox(height: 8),
              _detailLine('Số người ở', '${lease.occupantCount} người'),
              if (lease.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailLine('Liên hệ', lease.phone),
              ],
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 7,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showLeaseDocument(lease),
                    icon: const Icon(Icons.article_outlined, size: 17),
                    label: const Text('Xem bản hợp đồng'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _editLease(lease: lease),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Chỉnh sửa'),
                  ),
                  if (lease.isCurrent)
                    FilledButton.tonalIcon(
                      onPressed: () => _endLease(lease),
                      style: FilledButton.styleFrom(
                        foregroundColor: const Color(0xFFB64A4A),
                      ),
                      icon: const Icon(Icons.event_busy_outlined, size: 17),
                      label: const Text('Kết thúc'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _leaseStatus(LandlordLease lease) {
    if (lease.status == LandlordLeaseStatus.terminated) {
      return ('Đã kết thúc', LandlordPalette.of(context).muted);
    }
    if (lease.status == LandlordLeaseStatus.draft) {
      return ('Nháp', const Color(0xFFE08A1E));
    }
    if (lease.isExpiringSoon) return ('Sắp hết hạn', const Color(0xFFE08A1E));
    if (lease.isUpcoming) return ('Sắp bắt đầu', landlordBlue);
    if (lease.isExpired) return ('Hết hạn', LandlordPalette.of(context).muted);
    return ('Đang hiệu lực', const Color(0xFF16836F));
  }

  Widget _detailLine(String label, String value) => Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 12,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Future<void> _showLeaseDetails(LandlordLease lease) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hợp đồng ${lease.id}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: LandlordPalette.of(context).ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng ${lease.room}',
                  style: TextStyle(color: LandlordPalette.of(context).muted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailHeading('BÊN A · BÊN CHO THUÊ'),
                        _detailLine('Họ tên', lease.landlordName),
                        _detailLine(
                          'Thường trú',
                          lease.landlordPermanentAddress,
                        ),
                        _detailLine('CCCD', lease.landlordCitizenId),
                        _detailLine('Điện thoại / Zalo', lease.landlordContact),
                        const SizedBox(height: 12),
                        _detailHeading('BÊN B · BÊN THUÊ'),
                        _detailLine('Họ tên', lease.tenantName),
                        _detailLine('Năm sinh', lease.tenantBirthYear),
                        _detailLine('CCCD', lease.tenantCitizenId),
                        _detailLine(
                          'Ngày cấp',
                          lease.tenantCitizenIssueDate == null
                              ? 'Chưa cập nhật'
                              : landlordDate(lease.tenantCitizenIssueDate!),
                        ),
                        _detailLine('Điện thoại / Zalo', lease.phone),
                        _detailLine('Thường trú', lease.tenantPermanentAddress),
                        const SizedBox(height: 12),
                        _detailHeading('PHÒNG VÀ CHI PHÍ'),
                        _detailLine('Số phòng', lease.room),
                        _detailLine(
                          'Giá phòng',
                          '${formatLandlordMoney(lease.monthlyRent)}/tháng',
                        ),
                        _detailLine(
                          'Tiền đặt cọc',
                          formatLandlordMoney(lease.deposit),
                        ),
                        _detailLine(
                          'Tiền điện',
                          '${formatLandlordMoney(lease.electricityPrice)}/kWh',
                        ),
                        _detailLine(
                          'Tiền nước',
                          '${formatLandlordMoney(lease.waterPrice)}/${_waterUnit(lease.waterType)}',
                        ),
                        if (lease.services.isNotEmpty)
                          for (final service in lease.services)
                            _detailLine(
                              service.name,
                              '${formatLandlordMoney(service.price)}/${service.unit}${_serviceQuantityDescription(service)} · áp dụng ${formatLandlordMoney(service.amount)}/tháng',
                            )
                        else ...[
                          _detailLine(
                            'Tiền xe',
                            '${formatLandlordMoney(lease.vehicleFee)}/tháng',
                          ),
                          _detailLine(
                            lease.serviceName.isEmpty
                                ? 'Tiền dịch vụ'
                                : 'Phí ${lease.serviceName}',
                            '${formatLandlordMoney(lease.serviceFee)}/${lease.serviceUnit.isEmpty ? 'tháng' : lease.serviceUnit}',
                          ),
                        ],
                        const SizedBox(height: 12),
                        _detailHeading('THỜI HẠN VÀ THANH TOÁN'),
                        _detailLine(
                          'Thời hạn thuê',
                          '${lease.termMonths} tháng',
                        ),
                        _detailLine('Từ ngày', landlordDate(lease.startDate)),
                        _detailLine('Đến ngày', landlordDate(lease.endDate)),
                        _detailLine(
                          'Ngày đóng tiền',
                          'Ngày ${lease.dueDay} hằng tháng',
                        ),
                        _detailLine(
                          'Số người ở',
                          '${lease.occupantCount} người',
                        ),
                        if (lease.cashPaymentEnabled)
                          _detailLine(
                            'Tiền mặt tại',
                            lease.cashPaymentLocation,
                          ),
                        if (lease.bankTransferEnabled) ...[
                          _detailLine('Ngân hàng', lease.bankName),
                          _detailLine('Số tài khoản', lease.bankAccountNumber),
                        ],
                        const SizedBox(height: 12),
                        _detailHeading('GHI CHÚ'),
                        Text(
                          lease.note.isEmpty ? 'Không có ghi chú.' : lease.note,
                          style: TextStyle(
                            color: LandlordPalette.of(context).ink,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editLease(lease: lease);
                    },
                    icon: Icon(Icons.edit_outlined),
                    label: Text('Chỉnh sửa hợp đồng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLeaseDocument(LandlordLease lease) async {
    final today = DateTime.now();
    final rentalAddress = lease.rentalAddress.isEmpty
        ? _store.property.address
        : lease.rentalAddress;
    String value(String text) =>
        text.trim().isEmpty ? '........................................' : text;
    String date(DateTime? date) =>
        date == null ? '................................' : landlordDate(date);
    Widget paragraph(String text, {bool bold = false, TextAlign? align}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            text,
            textAlign: align,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              height: 1.45,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'serif',
            ),
          ),
        );
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'serif',
        ),
      ),
    );
    List<Widget> obligations(String content) => content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => paragraph(line.startsWith('•') ? line : '• $line'))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(context).height * .92,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Bản xem trước hợp đồng thuê',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD5D5D5)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            paragraph(
                              'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                              bold: true,
                              align: TextAlign.center,
                            ),
                            paragraph(
                              'Độc lập - Tự do - Hạnh phúc',
                              bold: true,
                              align: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            paragraph(
                              'HỢP ĐỒNG THUÊ PHÒNG TRỌ',
                              bold: true,
                              align: TextAlign.center,
                            ),
                            paragraph(
                              'Số: ${lease.id}',
                              align: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            paragraph('Phòng ${lease.room}', bold: true),
                            paragraph(
                              'Hôm nay ngày ${today.day} tháng ${today.month} năm ${today.year}, tại địa chỉ: $rentalAddress.',
                            ),
                            paragraph('Chúng tôi gồm:'),
                            heading('1. BÊN CHO THUÊ PHÒNG TRỌ (BÊN A)'),
                            paragraph('Ông/bà: ${value(lease.landlordName)}'),
                            paragraph(
                              'Sinh ngày: ${date(lease.landlordBirthDate)}',
                            ),
                            paragraph(
                              'Nơi đăng ký HKTT: ${value(lease.landlordPermanentAddress)}',
                            ),
                            paragraph(
                              'CCCD: ${value(lease.landlordCitizenId)}, cấp ngày ${date(lease.landlordCitizenIssueDate)} tại ${value(lease.landlordCitizenIssuePlace)}.',
                            ),
                            paragraph(
                              'Số điện thoại liên hệ: ${value(lease.landlordContact)}',
                            ),
                            heading('2. BÊN THUÊ PHÒNG TRỌ (BÊN B)'),
                            paragraph('Ông/bà: ${value(lease.tenantName)}'),
                            paragraph(
                              'Sinh ngày: ${date(lease.tenantBirthDate)}${lease.tenantBirthDate == null && lease.tenantBirthYear.isNotEmpty ? ' (năm ${lease.tenantBirthYear})' : ''}',
                            ),
                            paragraph(
                              'Nơi đăng ký HKTT: ${value(lease.tenantPermanentAddress)}',
                            ),
                            paragraph(
                              'CCCD: ${value(lease.tenantCitizenId)}, cấp ngày ${date(lease.tenantCitizenIssueDate)} tại ${value(lease.tenantCitizenIssuePlace)}.',
                            ),
                            paragraph(
                              'Số điện thoại liên hệ: ${value(lease.phone)}',
                            ),
                            heading('3. NỘI DUNG THỎA THUẬN'),
                            paragraph(
                              'Sau khi bàn bạc kỹ lưỡng, hai bên cùng thống nhất như sau:',
                            ),
                            paragraph(
                              '• Bên A đồng ý cho bên B thuê phòng ${lease.room} tại địa chỉ $rentalAddress.',
                            ),
                            paragraph(
                              '• Giá thuê: ${formatLandlordMoney(lease.monthlyRent)}/tháng.',
                            ),
                            paragraph(
                              '• Tiền điện: ${formatLandlordMoney(lease.electricityPrice)}/kWh, tính theo chỉ số công tơ.',
                            ),
                            paragraph(
                              '• Tiền nước: ${formatLandlordMoney(lease.waterPrice)}/${_waterUnit(lease.waterType)}${lease.waterType == 'Theo m³' ? ', tính theo chỉ số công tơ' : ''}${lease.waterType == 'Theo người' ? ' (${lease.occupantCount} người theo hợp đồng)' : ''}.',
                            ),
                            if (lease.services.isNotEmpty) ...[
                              for (final service in lease.services)
                                paragraph(
                                  '• ${value(service.name)}: đơn giá ${formatLandlordMoney(service.price)}/${value(service.unit)}${_serviceQuantityDescription(service)}, áp dụng ${formatLandlordMoney(service.amount)}/tháng.',
                                ),
                            ] else ...[
                              if (lease.vehicleFee > 0)
                                paragraph(
                                  '• Tiền xe: ${formatLandlordMoney(lease.vehicleFee)}/tháng.',
                                ),
                              if (lease.serviceFee > 0)
                                paragraph(
                                  '• Phí ${value(lease.serviceName.isEmpty ? 'dịch vụ' : lease.serviceName)}: ${formatLandlordMoney(lease.serviceFee)}/${value(lease.serviceUnit.isEmpty ? 'tháng' : lease.serviceUnit)}.',
                                ),
                            ],
                            paragraph(
                              '• Tiền đặt cọc: ${formatLandlordMoney(lease.deposit)}.',
                            ),
                            paragraph(
                              '• Hợp đồng có giá trị từ ngày ${landlordDate(lease.startDate)} đến ngày ${landlordDate(lease.endDate)}.',
                            ),
                            paragraph('• Hình thức thanh toán:'),
                            if (lease.cashPaymentEnabled)
                              paragraph(
                                '  - Tiền mặt tại: ${value(lease.cashPaymentLocation)}.',
                              ),
                            if (lease.bankTransferEnabled)
                              paragraph(
                                '  - Chuyển khoản: ${value(lease.bankName)}, số tài khoản ${value(lease.bankAccountNumber)}.',
                              ),
                            heading('4. TRÁCH NHIỆM CỦA CÁC BÊN'),
                            paragraph('Trách nhiệm của bên A:'),
                            ...obligations(lease.responsibilityA),
                            paragraph('Trách nhiệm của bên B:'),
                            ...obligations(lease.responsibilityB),
                            heading('5. TRÁCH NHIỆM CHUNG'),
                            ...obligations(lease.commonResponsibilities),
                            if (lease.note.trim().isNotEmpty) ...[
                              heading('GHI CHÚ'),
                              paragraph(lease.note),
                            ],
                            const SizedBox(height: 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      paragraph(
                                        'ĐẠI DIỆN BÊN A',
                                        bold: true,
                                        align: TextAlign.center,
                                      ),
                                      paragraph(
                                        '(Ký và ghi rõ họ tên)',
                                        align: TextAlign.center,
                                      ),
                                      const SizedBox(height: 60),
                                      paragraph(
                                        value(lease.landlordName),
                                        bold: true,
                                        align: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    children: [
                                      paragraph(
                                        'ĐẠI DIỆN BÊN B',
                                        bold: true,
                                        align: TextAlign.center,
                                      ),
                                      paragraph(
                                        '(Ký và ghi rõ họ tên)',
                                        align: TextAlign.center,
                                      ),
                                      const SizedBox(height: 60),
                                      paragraph(
                                        value(lease.tenantName),
                                        bold: true,
                                        align: TextAlign.center,
                                      ),
                                    ],
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailHeading(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: TextStyle(
        color: landlordBlue,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );

  Future<void> _editLease({
    LandlordLease? lease,
    String? initialTemplateId,
    LandlordLeaseTemplate? initialTemplate,
  }) async {
    final result = await LandlordNavigation.push<_LeaseDraft>(
      context,
      destinationId: 'leases',
      page: _LeaseEditor(
        store: _store,
        lease: lease,
        initialRoom: lease == null ? widget.createForRoom : null,
        initialTemplateId: initialTemplate?.id ?? initialTemplateId,
        occupiedRooms: _store.activeLeases.map((item) => item.room).toSet(),
      ),
    );
    if (result == null || !mounted) return;
    try {
      _store.saveLease(
        tenantId: result.tenantKey.isEmpty ? null : result.tenantKey,
        existing: lease,
        room: result.room,
        landlordName: result.landlordName,
        landlordPermanentAddress: result.landlordPermanentAddress,
        landlordCitizenId: result.landlordCitizenId,
        landlordContact: result.landlordContact,
        tenantName: result.tenantName,
        tenantBirthYear: result.tenantBirthYear,
        tenantCitizenId: result.tenantCitizenId,
        tenantCitizenIssueDate: result.tenantCitizenIssueDate,
        tenantPermanentAddress: result.tenantPermanentAddress,
        phone: result.phone,
        startDate: result.startDate,
        endDate: result.endDate,
        monthlyRent: result.monthlyRent,
        deposit: result.deposit,
        termMonths: result.termMonths,
        electricityPrice: result.electricityPrice,
        waterPrice: result.waterPrice,
        waterType: result.waterType,
        electricityServiceId: result.electricityServiceId,
        waterServiceId: result.waterServiceId,
        vehicleFee: result.vehicleFee,
        serviceFee: result.serviceFee,
        serviceId: result.serviceId,
        serviceName: result.serviceName,
        serviceUnit: result.serviceUnit,
        serviceBasis: result.serviceBasis,
        services: result.services,
        dueDay: result.dueDay,
        cashPaymentEnabled: result.cashPaymentEnabled,
        cashPaymentLocation: result.cashPaymentLocation,
        bankTransferEnabled: result.bankTransferEnabled,
        bankName: result.bankName,
        bankAccountNumber: result.bankAccountNumber,
        occupantCount: result.occupantCount,
        note: result.note,
        status: result.status,
        landlordBirthDate: result.landlordBirthDate,
        landlordCitizenIssueDate: result.landlordCitizenIssueDate,
        landlordCitizenIssuePlace: result.landlordCitizenIssuePlace,
        tenantBirthDate: result.tenantBirthDate,
        tenantCitizenIssuePlace: result.tenantCitizenIssuePlace,
        responsibilityA: result.responsibilityA,
        responsibilityB: result.responsibilityB,
        commonResponsibilities: result.commonResponsibilities,
        templateId: result.templateId,
        rentalAddress: result.rentalAddress,
      );
      showLandlordMessage(
        context,
        lease == null ? 'Đã tạo hợp đồng.' : 'Đã cập nhật hợp đồng.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  Future<void> _editLeaseTemplate([LandlordLeaseTemplate? template]) async {
    final result = await LandlordNavigation.push<_LeaseTemplateDraft>(
      context,
      destinationId: 'leases',
      page: _LeaseTemplateEditor(store: _store, template: template),
    );
    if (result == null || !mounted) return;
    try {
      _store.saveLeaseTemplate(
        existing: template,
        name: result.name,
        landlordName: result.landlordName,
        landlordPermanentAddress: result.landlordPermanentAddress,
        landlordCitizenId: result.landlordCitizenId,
        landlordContact: result.landlordContact,
        landlordBirthDate: result.landlordBirthDate,
        landlordCitizenIssueDate: result.landlordCitizenIssueDate,
        landlordCitizenIssuePlace: result.landlordCitizenIssuePlace,
        electricityPrice: result.electricityPrice,
        waterPrice: result.waterPrice,
        waterType: result.waterType,
        electricityServiceId: result.electricityServiceId,
        waterServiceId: result.waterServiceId,
        cashPaymentEnabled: result.cashPaymentEnabled,
        cashPaymentLocation: result.cashPaymentLocation,
        bankTransferEnabled: result.bankTransferEnabled,
        bankName: result.bankName,
        bankAccountNumber: result.bankAccountNumber,
        responsibilityA: result.responsibilityA,
        responsibilityB: result.responsibilityB,
        commonResponsibilities: result.commonResponsibilities,
      );
      showLandlordMessage(
        context,
        template == null ? 'Đã tạo hợp đồng mẫu.' : 'Đã cập nhật hợp đồng mẫu.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  Future<void> _deleteLeaseTemplate(LandlordLeaseTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hợp đồng mẫu?'),
        content: Text('Mẫu “${template.name}” sẽ bị xóa khỏi danh sách.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa mẫu'),
          ),
        ],
      ),
    );
    if (confirmed == true) _store.deleteLeaseTemplate(template);
  }

  Future<void> _endLease(LandlordLease lease) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kết thúc hợp đồng?'),
        content: Text(
          'Hợp đồng phòng ${lease.room} của ${lease.tenantName} sẽ chuyển sang trạng thái đã kết thúc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Kết thúc hợp đồng'),
          ),
        ],
      ),
    );
    if (confirmed == true) _store.endLease(lease);
  }
}

class _LeaseDraft {
  const _LeaseDraft({
    required this.tenantKey,
    required this.room,
    required this.landlordName,
    required this.landlordPermanentAddress,
    required this.landlordCitizenId,
    required this.landlordContact,
    required this.tenantName,
    required this.tenantBirthYear,
    required this.tenantCitizenId,
    required this.tenantCitizenIssueDate,
    required this.tenantPermanentAddress,
    required this.phone,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.termMonths,
    required this.electricityPrice,
    required this.waterPrice,
    required this.waterType,
    required this.electricityServiceId,
    required this.waterServiceId,
    required this.vehicleFee,
    required this.serviceFee,
    required this.serviceId,
    required this.serviceName,
    required this.serviceUnit,
    required this.serviceBasis,
    required this.services,
    required this.dueDay,
    required this.cashPaymentEnabled,
    required this.cashPaymentLocation,
    required this.bankTransferEnabled,
    required this.bankName,
    required this.bankAccountNumber,
    required this.occupantCount,
    required this.note,
    required this.status,
    required this.landlordBirthDate,
    required this.landlordCitizenIssueDate,
    required this.landlordCitizenIssuePlace,
    required this.tenantBirthDate,
    required this.tenantCitizenIssuePlace,
    required this.responsibilityA,
    required this.responsibilityB,
    required this.commonResponsibilities,
    required this.templateId,
    required this.rentalAddress,
  });

  final String tenantKey;
  final String room;
  final String landlordName;
  final String landlordPermanentAddress;
  final String landlordCitizenId;
  final String landlordContact;
  final String tenantName;
  final String tenantBirthYear;
  final String tenantCitizenId;
  final DateTime? tenantCitizenIssueDate;
  final String tenantPermanentAddress;
  final String phone;
  final DateTime startDate;
  final DateTime endDate;
  final int monthlyRent;
  final int deposit;
  final int termMonths;
  final int electricityPrice;
  final int waterPrice;
  final String waterType;
  final String electricityServiceId;
  final String waterServiceId;
  final int vehicleFee;
  final int serviceFee;
  final String serviceId;
  final String serviceName;
  final String serviceUnit;
  final String serviceBasis;
  final List<LandlordLeaseService> services;
  final int dueDay;
  final bool cashPaymentEnabled;
  final String cashPaymentLocation;
  final bool bankTransferEnabled;
  final String bankName;
  final String bankAccountNumber;
  final int occupantCount;
  final String note;
  final LandlordLeaseStatus status;
  final DateTime? landlordBirthDate;
  final DateTime? landlordCitizenIssueDate;
  final String landlordCitizenIssuePlace;
  final DateTime? tenantBirthDate;
  final String tenantCitizenIssuePlace;
  final String responsibilityA;
  final String responsibilityB;
  final String commonResponsibilities;
  final String templateId;
  final String rentalAddress;
}

class _LeaseEditor extends StatefulWidget {
  const _LeaseEditor({
    required this.store,
    required this.lease,
    required this.occupiedRooms,
    this.initialRoom,
    this.initialTemplateId,
  });
  final LandlordDemoStore store;
  final LandlordLease? lease;
  final Set<String> occupiedRooms;
  final String? initialRoom;
  final String? initialTemplateId;

  @override
  State<_LeaseEditor> createState() => _LeaseEditorState();
}

class _LeaseEditorState extends State<_LeaseEditor> {
  LandlordDemoStore get _store => widget.store;
  LandlordLeaseTemplate? get _initialTemplate {
    final id = widget.lease == null
        ? (widget.initialTemplateId ?? _store.leaseTemplates.firstOrNull?.id)
        : widget.lease!.templateId;
    return id == null ? null : _store.leaseTemplateById(id);
  }

  List<String> get _allRooms =>
      _store.catalog.map((room) => room.leaseRoomCode ?? room.code).toList();

  LandlordService? _serviceRecord(String? id) =>
      id == null || id.isEmpty ? null : _store.serviceRecordById(id);

  LandlordService? _typeRate(String? room, {required bool water}) {
    final type = room == null ? null : _store.roomTypeForRoom(room);
    if (type == null) return null;
    for (final id in type.serviceIds) {
      final service = _serviceRecord(id);
      if (service != null &&
          service.active &&
          (water ? _isWaterService(service) : _isElectricityService(service))) {
        return service;
      }
    }
    return null;
  }

  LandlordService? _preferredRateService(String? room, {required bool water}) {
    final typeRate = _typeRate(room, water: water);
    if (typeRate != null) return typeRate;
    final template = _templateId == null
        ? _initialTemplate
        : _store.leaseTemplateById(_templateId!);
    final savedId = water
        ? widget.lease?.waterServiceId ?? template?.waterServiceId
        : widget.lease?.electricityServiceId ?? template?.electricityServiceId;
    final saved = _serviceRecord(savedId);
    if (widget.lease != null && saved != null) return saved;
    if (saved?.active == true) return saved;
    return _store.serviceById(water ? 'water' : 'electricity');
  }

  int _servicePriceForRoom(String? room, LandlordService? service) {
    if (service == null) return 0;
    final type = room == null ? null : _store.roomTypeForRoom(room);
    return type?.serviceIds.contains(service.id) == true
        ? type!.servicePrices[service.id] ?? service.price
        : service.price;
  }

  List<LandlordService> _rateOptions({required bool water}) {
    final options = _store.services.where((service) {
      if (!service.active) return false;
      return water ? _isWaterService(service) : _isElectricityService(service);
    }).toList();
    final savedId = water ? _waterServiceId : _electricityServiceId;
    final saved = _serviceRecord(savedId);
    if (saved != null && !options.any((service) => service.id == saved.id)) {
      options.add(saved);
    }
    return options;
  }

  List<LandlordLeaseService> _servicesForRoom(String room) {
    final type = _store.roomTypeForRoom(room);
    if (type == null) return const [];
    final occupants = int.tryParse(_occupants.text) ?? 1;
    final attached = <LandlordLeaseService>[];
    for (final id in type.serviceIds) {
      final service = _serviceRecord(id);
      if (service == null ||
          !service.active ||
          _isElectricityService(service) ||
          _isWaterService(service)) {
        continue;
      }
      attached.add(
        LandlordLeaseService(
          serviceId: service.id,
          name: service.name,
          unit: service.unit,
          basis: service.basis,
          price: type.servicePrices[id] ?? service.price,
          quantity: _isPerPersonBasis(service.basis) ? occupants : 1,
          amount:
              (type.servicePrices[id] ?? service.price) *
              (_isPerPersonBasis(service.basis) ? occupants : 1),
        ),
      );
    }
    return attached;
  }

  bool _isPerPersonBasis(String basis) => basis.toLowerCase().contains('người');

  bool _isItemBasis(String basis) =>
      basis.toLowerCase().contains('cái') || basis.toLowerCase().contains('xe');

  LandlordLeaseService _withServiceQuantity(
    LandlordLeaseService service,
    int quantity,
  ) => LandlordLeaseService(
    serviceId: service.serviceId,
    name: service.name,
    unit: service.unit,
    basis: service.basis,
    price: service.price,
    quantity: quantity,
    amount: service.price * quantity,
  );

  void _updateOccupantServiceAmounts() {
    final occupants = int.tryParse(_occupants.text) ?? 1;
    _selectedContractServices = _selectedContractServices
        .map(
          (service) => _isPerPersonBasis(service.basis)
              ? _withServiceQuantity(service, occupants)
              : service,
        )
        .toList(growable: false);
  }

  void _setItemServiceQuantity(String serviceId, int quantity) {
    _selectedContractServices = _selectedContractServices
        .map(
          (service) => service.serviceId == serviceId
              ? _withServiceQuantity(service, quantity)
              : service,
        )
        .toList(growable: false);
  }

  List<LandlordLeaseService> _legacyLeaseServices(LandlordLease lease) => [
    if (lease.vehicleFee > 0)
      LandlordLeaseService(
        serviceId: 'vehicle',
        name: 'Gửi xe',
        unit: 'cái',
        basis: 'Theo cái / xe',
        price: lease.vehicleFee,
        amount: lease.vehicleFee,
      ),
    if (lease.serviceFee > 0)
      LandlordLeaseService(
        serviceId: lease.serviceId,
        name: lease.serviceName.isEmpty ? 'Dịch vụ' : lease.serviceName,
        unit: lease.serviceUnit.isEmpty ? 'tháng' : lease.serviceUnit,
        basis: lease.serviceBasis,
        price: lease.serviceFee,
        amount: lease.serviceFee,
      ),
  ];

  List<LandlordLeaseService> get _contractServices => _selectedContractServices;

  void _applyRoomDefaults(String room) {
    final electricity = _preferredRateService(room, water: false);
    final water = _preferredRateService(room, water: true);
    _electricityServiceId = electricity?.id ?? '';
    _waterServiceId = water?.id ?? '';
    _electricity.text = _servicePriceForRoom(room, electricity).toString();
    _water.text = _servicePriceForRoom(room, water).toString();
    _waterType = _waterTypeForService(water);
    _selectedContractServices = _servicesForRoom(room);
  }

  int? _roomRent(String? code) {
    if (code == null) return null;
    for (final details in _store.roomDetails) {
      if (details.room.code == code || details.room.leaseRoomCode == code) {
        return details.monthlyRent;
      }
    }
    return null;
  }

  final _formKey = GlobalKey<FormState>();
  late final _landlordName = TextEditingController(
    text:
        widget.lease?.landlordName ??
        _initialTemplate?.landlordName ??
        _store.property.ownerName,
  );
  late final _landlordAddress = TextEditingController(
    text:
        widget.lease?.landlordPermanentAddress ??
        _initialTemplate?.landlordPermanentAddress ??
        _store.property.address,
  );
  late final _landlordId = TextEditingController(
    text:
        widget.lease?.landlordCitizenId ??
        _initialTemplate?.landlordCitizenId ??
        '',
  );
  late final _landlordContact = TextEditingController(
    text:
        widget.lease?.landlordContact ??
        _initialTemplate?.landlordContact ??
        _store.property.phone,
  );
  late final _landlordIssuePlace = TextEditingController(
    text:
        widget.lease?.landlordCitizenIssuePlace ??
        _initialTemplate?.landlordCitizenIssuePlace ??
        '',
  );
  late final _rentalAddress = TextEditingController(
    text: widget.lease?.rentalAddress.isNotEmpty == true
        ? widget.lease!.rentalAddress
        : _store.property.address,
  );
  late final _name = TextEditingController(
    text: widget.lease?.tenantName ?? '',
  );
  late final _birthYear = TextEditingController(
    text: widget.lease?.tenantBirthYear ?? '',
  );
  late final _tenantId = TextEditingController(
    text: widget.lease?.tenantCitizenId ?? '',
  );
  late final _tenantIssuePlace = TextEditingController(
    text: widget.lease?.tenantCitizenIssuePlace ?? '',
  );
  late final _tenantKey = TextEditingController(
    text: widget.lease?.tenantId ?? '',
  );
  late final _tenantAddress = TextEditingController(
    text: widget.lease?.tenantPermanentAddress ?? '',
  );
  late final _phone = TextEditingController(text: widget.lease?.phone ?? '');
  late final _rent = TextEditingController(
    text:
        widget.lease?.monthlyRent.toString() ??
        (_roomRent(
                  widget.lease?.room ??
                      widget.initialRoom ??
                      _firstAvailableRoom,
                ) ??
                3000000)
            .toString(),
  );
  late final _deposit = TextEditingController(
    text:
        widget.lease?.deposit.toString() ??
        (_roomRent(
                  widget.lease?.room ??
                      widget.initialRoom ??
                      _firstAvailableRoom,
                ) ??
                3000000)
            .toString(),
  );
  late final _termMonths = TextEditingController(
    text: widget.lease?.termMonths.toString() ?? '12',
  );
  late final _electricity = TextEditingController(
    text:
        widget.lease?.electricityPrice.toString() ??
        _servicePriceForRoom(
          _room,
          _preferredRateService(_room, water: false),
        ).toString(),
  );
  late final _water = TextEditingController(
    text:
        widget.lease?.waterPrice.toString() ??
        _servicePriceForRoom(
          _room,
          _preferredRateService(_room, water: true),
        ).toString(),
  );
  late final _dueDay = TextEditingController(
    text: widget.lease?.dueDay.toString() ?? '10',
  );
  late final _cashLocation = TextEditingController(
    text:
        widget.lease?.cashPaymentLocation ??
        _initialTemplate?.cashPaymentLocation ??
        _store.property.address,
  );
  late final _bankName = TextEditingController(
    text:
        widget.lease?.bankName ??
        _initialTemplate?.bankName ??
        _store.defaultPaymentAccount?.bankName ??
        '',
  );
  late final _bankAccount = TextEditingController(
    text:
        widget.lease?.bankAccountNumber ??
        _initialTemplate?.bankAccountNumber ??
        _store.defaultPaymentAccount?.accountNumber ??
        '',
  );
  late final _occupants = TextEditingController(
    text: widget.lease?.occupantCount.toString() ?? '1',
  );
  late final _note = TextEditingController(text: widget.lease?.note ?? '');
  late final _responsibilityA = TextEditingController(
    text:
        widget.lease?.responsibilityA ??
        _initialTemplate?.responsibilityA ??
        '',
  );
  late final _responsibilityB = TextEditingController(
    text:
        widget.lease?.responsibilityB ??
        _initialTemplate?.responsibilityB ??
        '',
  );
  late final _commonResponsibilities = TextEditingController(
    text:
        widget.lease?.commonResponsibilities ??
        _initialTemplate?.commonResponsibilities ??
        '',
  );
  late String _room =
      widget.lease?.room ?? widget.initialRoom ?? _firstAvailableRoom;
  late DateTime _start = widget.lease?.startDate ?? DateTime.now();
  late DateTime _end =
      widget.lease?.endDate ??
      DateTime(
        DateTime.now().year + 1,
        DateTime.now().month,
        DateTime.now().day,
      );
  late LandlordLeaseStatus _status =
      widget.lease?.status ?? LandlordLeaseStatus.active;
  late String _waterType =
      widget.lease?.waterType ??
      _waterTypeForService(_preferredRateService(_room, water: true));
  late String _electricityServiceId =
      widget.lease?.electricityServiceId ??
      _preferredRateService(_room, water: false)?.id ??
      '';
  late String _waterServiceId =
      widget.lease?.waterServiceId ??
      _preferredRateService(_room, water: true)?.id ??
      '';
  late List<LandlordLeaseService> _selectedContractServices =
      widget.lease == null
      ? _servicesForRoom(_room)
      : widget.lease!.services.isNotEmpty
      ? List<LandlordLeaseService>.from(widget.lease!.services)
      : _legacyLeaseServices(widget.lease!);
  late String? _templateId = widget.lease == null
      ? (widget.initialTemplateId ?? _store.leaseTemplates.firstOrNull?.id)
      : (widget.lease!.templateId.isEmpty ||
                _store.leaseTemplateById(widget.lease!.templateId) == null
            ? null
            : widget.lease!.templateId);
  late DateTime? _tenantIssueDate = widget.lease?.tenantCitizenIssueDate;
  late DateTime? _landlordBirthDate =
      widget.lease?.landlordBirthDate ?? _initialTemplate?.landlordBirthDate;
  late DateTime? _landlordIssueDate =
      widget.lease?.landlordCitizenIssueDate ??
      _initialTemplate?.landlordCitizenIssueDate;
  late DateTime? _tenantBirthDate = widget.lease?.tenantBirthDate;
  late bool _cashEnabled =
      widget.lease?.cashPaymentEnabled ??
      _initialTemplate?.cashPaymentEnabled ??
      true;
  late bool _bankEnabled =
      widget.lease?.bankTransferEnabled ??
      _initialTemplate?.bankTransferEnabled ??
      true;

  String get _firstAvailableRoom => _allRooms.firstWhere(
    (room) => !widget.occupiedRooms.contains(room),
    orElse: () => _allRooms.first,
  );

  @override
  void dispose() {
    _landlordName.dispose();
    _landlordAddress.dispose();
    _landlordId.dispose();
    _landlordContact.dispose();
    _landlordIssuePlace.dispose();
    _rentalAddress.dispose();
    _name.dispose();
    _birthYear.dispose();
    _tenantId.dispose();
    _tenantIssuePlace.dispose();
    _tenantKey.dispose();
    _tenantAddress.dispose();
    _phone.dispose();
    _rent.dispose();
    _deposit.dispose();
    _termMonths.dispose();
    _electricity.dispose();
    _water.dispose();
    _dueDay.dispose();
    _cashLocation.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _occupants.dispose();
    _note.dispose();
    _responsibilityA.dispose();
    _responsibilityB.dispose();
    _commonResponsibilities.dispose();
    super.dispose();
  }

  void _applyTemplate(LandlordLeaseTemplate template) {
    _templateId = template.id;
    _landlordName.text = template.landlordName;
    _landlordAddress.text = template.landlordPermanentAddress;
    _landlordId.text = template.landlordCitizenId;
    _landlordContact.text = template.landlordContact;
    _landlordIssuePlace.text = template.landlordCitizenIssuePlace;
    _landlordBirthDate = template.landlordBirthDate;
    _landlordIssueDate = template.landlordCitizenIssueDate;
    if (_typeRate(_room, water: false) == null) {
      _electricityServiceId = template.electricityServiceId;
      _electricity.text =
          (_serviceRecord(_electricityServiceId)?.price ??
                  template.electricityPrice)
              .toString();
    }
    if (_typeRate(_room, water: true) == null) {
      _waterServiceId = template.waterServiceId;
      final waterService = _serviceRecord(_waterServiceId);
      _water.text = (waterService?.price ?? template.waterPrice).toString();
      _waterType = waterService == null
          ? template.waterType
          : _waterTypeForService(waterService);
    }
    _cashEnabled = template.cashPaymentEnabled;
    _cashLocation.text = template.cashPaymentLocation;
    _bankEnabled = template.bankTransferEnabled;
    _bankName.text = template.bankName;
    _bankAccount.text = template.bankAccountNumber;
    _responsibilityA.text = template.responsibilityA;
    _responsibilityB.text = template.responsibilityB;
    _commonResponsibilities.text = template.commonResponsibilities;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final availableRooms = _allRooms
        .where(
          (room) =>
              !widget.occupiedRooms.contains(room) ||
              room == widget.lease?.room,
        )
        .toList();
    if (!availableRooms.contains(_room) && availableRooms.isNotEmpty) {
      _room = availableRooms.first;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 650,
                maxHeight: constraints.maxHeight,
              ),
              child: SizedBox.expand(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FF),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40547AB4),
                        blurRadius: 34,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 18, 14, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.lease == null
                                          ? 'Tạo hợp đồng thuê phòng'
                                          : 'Chỉnh sửa hợp đồng',
                                      style: const TextStyle(
                                        color: Color(0xFF102F67),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Điền thông tin hai bên và thỏa thuận thuê phòng.',
                                      style: TextStyle(
                                        color: LandlordPalette.of(context)
                                            .muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Đóng',
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_store.leaseTemplates.isNotEmpty)
                                  DropdownButtonFormField<String>(
                                    initialValue: _templateId ?? '',
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      'Hợp đồng mẫu chung',
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text('Không dùng mẫu'),
                                      ),
                                      for (final template
                                          in _store.leaseTemplates)
                                        DropdownMenuItem(
                                          value: template.id,
                                          child: Text(template.name),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null || value.isEmpty) {
                                        setState(() => _templateId = null);
                                      } else {
                                        final template = _store
                                            .leaseTemplateById(value);
                                        if (template != null)
                                          _applyTemplate(template);
                                      }
                                    },
                                  ),
                                DropdownButtonFormField<String>(
                                  initialValue: _room,
                                  isExpanded: true,
                                  style: const TextStyle(
                                    color: Color(0xFF102F67),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: _inputDecoration('Phòng')
                                      .copyWith(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            19,
                                          ),
                                          borderSide: const BorderSide(
                                            color: landlordBlue,
                                            width: 1.8,
                                          ),
                                        ),
                                      ),
                                  items: [
                                    for (final room in availableRooms)
                                      DropdownMenuItem(
                                        value: room,
                                        child: Text('Phòng $room'),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _room = value;
                                      final price = _roomRent(value);
                                      if (price != null) {
                                        _rent.text = price.toString();
                                        _deposit.text = price.toString();
                                      }
                                      _applyRoomDefaults(value);
                                    });
                                  },
                                ),
                                _textField(
                                  _rentalAddress,
                                  'Địa chỉ phòng trọ',
                                  validator: _requiredValidator(
                                    'Nhập địa chỉ phòng trọ.',
                                  ),
                                ),
                                _sectionTitle(
                                  'BÊN A · BÊN CHO THUÊ PHÒNG',
                                  icon: Icons.home_outlined,
                                ),
                                _textField(
                                  _landlordName,
                                  'Họ tên bên A',
                                  validator: _requiredValidator(
                                    'Nhập họ tên bên A.',
                                  ),
                                  capitalization: TextCapitalization.words,
                                ),
                                _dateField(
                                  'Sinh ngày bên A',
                                  _landlordBirthDate,
                                  (date) =>
                                      setState(() => _landlordBirthDate = date),
                                  required: false,
                                  lastDate: DateTime.now(),
                                ),
                                _textField(
                                  _landlordAddress,
                                  'Địa chỉ thường trú',
                                  validator: _requiredValidator(
                                    'Nhập địa chỉ thường trú bên A.',
                                  ),
                                ),
                                _textField(
                                  _landlordId,
                                  'CCCD bên A',
                                  keyboardType: TextInputType.number,
                                  validator: _citizenIdValidator,
                                ),
                                _pairFields(
                                  _dateField(
                                    'Ngày cấp CCCD bên A',
                                    _landlordIssueDate,
                                    (date) => setState(
                                      () => _landlordIssueDate = date,
                                    ),
                                    required: false,
                                    lastDate: DateTime.now(),
                                  ),
                                  _textField(
                                    _landlordIssuePlace,
                                    'Nơi cấp CCCD bên A',
                                  ),
                                ),
                                _textField(
                                  _landlordContact,
                                  'Điện thoại / Zalo bên A',
                                  keyboardType: TextInputType.phone,
                                  validator: _phoneValidator,
                                ),
                                _sectionTitle(
                                  'BÊN B · BÊN THUÊ PHÒNG',
                                  icon: Icons.person_outline_rounded,
                                ),
                                _textField(
                                  _tenantKey,
                                  'Mã người thuê (tenantId trong hồ sơ tài khoản)',
                                  readOnly: widget.lease != null,
                                  validator: (value) =>
                                      value == null ||
                                          value.trim().isEmpty ||
                                          RegExp(r'^[^\s/:]+$')
                                              .hasMatch(value.trim())
                                      ? null
                                      : 'Mã người thuê không chứa khoảng trắng, / hoặc :.',
                                ),
                                _textField(
                                  _name,
                                  'Họ tên bên B',
                                  validator: _requiredValidator(
                                    'Nhập họ tên bên B.',
                                  ),
                                  capitalization: TextCapitalization.words,
                                ),
                                _dateField(
                                  'Sinh ngày bên B',
                                  _tenantBirthDate,
                                  (date) =>
                                      setState(() => _tenantBirthDate = date),
                                  required: false,
                                  lastDate: DateTime.now(),
                                ),
                                if (_tenantBirthDate == null &&
                                    widget.lease?.tenantBirthDate == null &&
                                    _birthYear.text.isNotEmpty)
                                  _textField(
                                    _birthYear,
                                    'Năm sinh (hồ sơ cũ)',
                                    keyboardType: TextInputType.number,
                                    validator: _birthYearValidator,
                                  ),
                                _textField(
                                  _tenantId,
                                  'CCCD bên B',
                                  keyboardType: TextInputType.number,
                                  validator: _citizenIdValidator,
                                ),
                                _pairFields(
                                  _dateField(
                                    'Ngày cấp CCCD',
                                    _tenantIssueDate,
                                    (date) =>
                                        setState(() => _tenantIssueDate = date),
                                    lastDate: DateTime.now(),
                                  ),
                                  _textField(
                                    _tenantIssuePlace,
                                    'Nơi cấp CCCD bên B',
                                    validator: _requiredValidator(
                                      'Nhập nơi cấp CCCD bên B.',
                                    ),
                                  ),
                                ),
                                _textField(
                                  _phone,
                                  'Điện thoại / Zalo bên B',
                                  keyboardType: TextInputType.phone,
                                  validator: _phoneValidator,
                                ),
                                _textField(
                                  _tenantAddress,
                                  'Địa chỉ thường trú',
                                  validator: _requiredValidator(
                                    'Nhập địa chỉ thường trú bên B.',
                                  ),
                                ),
                                _sectionTitle(
                                  'PHÒNG VÀ CÁC KHOẢN TIỀN',
                                  icon: Icons.meeting_room_outlined,
                                ),
                                _pairFields(
                                  _textField(
                                    _rent,
                                    'Giá phòng / tháng',
                                    keyboardType: TextInputType.number,
                                    validator: _positiveAmountValidator,
                                  ),
                                  _textField(
                                    _deposit,
                                    'Tiền đặt cọc',
                                    keyboardType: TextInputType.number,
                                    validator: _nonNegativeAmountValidator,
                                  ),
                                ),
                                _rateDropdown(water: false),
                                _textField(
                                  _electricity,
                                  'Đơn giá điện / kWh',
                                  readOnly: true,
                                ),
                                _rateDropdown(water: true),
                                _textField(
                                  _water,
                                  'Đơn giá nước',
                                  readOnly: true,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    'Đơn vị nước: ${_waterUnit(_waterType)} · lấy từ Bảng giá & dịch vụ.',
                                    style: TextStyle(
                                      color: LandlordPalette.of(context).muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                _serviceFields(),
                                _pairFields(
                                  _textField(
                                    _dueDay,
                                    'Ngày đóng tiền (1–31)',
                                    keyboardType: TextInputType.number,
                                    validator: _dueDayValidator,
                                  ),
                                  _textField(
                                    _occupants,
                                    'Số người ở theo hợp đồng',
                                    keyboardType: TextInputType.number,
                                    validator: _occupantsValidator,
                                    onChanged: (_) =>
                                        setState(_updateOccupantServiceAmounts),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    'Dịch vụ tính theo người sẽ tự nhân với số người ở; dịch vụ tính theo cái/xe có thể nhập số lượng riêng.',
                                    style: TextStyle(
                                      color: LandlordPalette.of(context).muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                _sectionTitle(
                                  'THỜI HẠN THUÊ',
                                  icon: Icons.calendar_month_outlined,
                                ),
                                _textField(
                                  _termMonths,
                                  'Thời hạn bên B thuê (tháng)',
                                  keyboardType: TextInputType.number,
                                  validator: _termMonthsValidator,
                                ),
                                _pairFields(
                                  _dateField(
                                    'Từ ngày',
                                    _start,
                                    (date) => setState(() => _start = date!),
                                  ),
                                  _dateField(
                                    'Đến ngày',
                                    _end,
                                    (date) => setState(() => _end = date!),
                                  ),
                                ),
                                _sectionTitle(
                                  'PHƯƠNG THỨC THANH TOÁN',
                                  icon: Icons.payments_outlined,
                                ),
                                CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  dense: true,
                                  activeColor: landlordBlue,
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                    side: const BorderSide(
                                      color: Color(0xFFD4E3FF),
                                    ),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: _cashEnabled,
                                  onChanged: (value) => setState(
                                    () => _cashEnabled = value ?? false,
                                  ),
                                  title: Text(
                                    'Tiền mặt',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_cashEnabled)
                                  _textField(
                                    _cashLocation,
                                    'Địa điểm nhận tiền mặt',
                                    validator: _requiredValidator(
                                      'Nhập nơi nhận tiền mặt.',
                                    ),
                                  ),
                                CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  dense: true,
                                  activeColor: landlordBlue,
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                    side: const BorderSide(
                                      color: Color(0xFFD4E3FF),
                                    ),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: _bankEnabled,
                                  onChanged: (value) => setState(
                                    () => _bankEnabled = value ?? false,
                                  ),
                                  title: Text(
                                    'Chuyển khoản ngân hàng',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_bankEnabled) ...[
                                  _textField(
                                    _bankName,
                                    'Tên ngân hàng',
                                    validator: _requiredValidator(
                                      'Nhập tên ngân hàng.',
                                    ),
                                  ),
                                  _textField(
                                    _bankAccount,
                                    'Số tài khoản',
                                    keyboardType: TextInputType.number,
                                    validator: _bankAccountValidator,
                                  ),
                                ],
                                _sectionTitle(
                                  'GHI CHÚ',
                                  icon: Icons.notes_rounded,
                                ),
                                TextFormField(
                                  controller: _note,
                                  minLines: 2,
                                  maxLines: 4,
                                  style: const TextStyle(
                                    color: Color(0xFF102F67),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _inputDecoration(
                                    'Ghi chú thêm trong hợp đồng',
                                  ).copyWith(alignLabelWithHint: true),
                                ),
                                _sectionTitle(
                                  'TRÁCH NHIỆM CÁC BÊN',
                                  icon: Icons.fact_check_outlined,
                                ),
                                _textArea(
                                  _responsibilityA,
                                  'Trách nhiệm của bên A',
                                ),
                                _textArea(
                                  _responsibilityB,
                                  'Trách nhiệm của bên B',
                                ),
                                _textArea(
                                  _commonResponsibilities,
                                  'Trách nhiệm chung',
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<LandlordLeaseStatus>(
                                  initialValue: _status,
                                  isExpanded: true,
                                  style: const TextStyle(
                                    color: Color(0xFF102F67),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _inputDecoration(
                                    'Trạng thái lưu',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: LandlordLeaseStatus.active,
                                      child: Text('Đang hiệu lực'),
                                    ),
                                    DropdownMenuItem(
                                      value: LandlordLeaseStatus.draft,
                                      child: Text('Nháp'),
                                    ),
                                    DropdownMenuItem(
                                      value: LandlordLeaseStatus.terminated,
                                      child: Text('Đã kết thúc'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _status = value ?? _status,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: landlordBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  elevation: 3,
                                  shadowColor: landlordBlue.withValues(
                                    alpha: .3,
                                  ),
                                ),
                                icon: const Icon(Icons.save_outlined, size: 18),
                                label: const Text('Lưu hợp đồng'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {required IconData icon}) => Padding(
    padding: const EdgeInsets.only(top: 17, bottom: 5),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: const LinearGradient(
              colors: [Color(0xFF438EFF), landlordBlue],
            ),
          ),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: landlordBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pairFields(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 460) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, second],
        );
      }
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _rateDropdown({required bool water}) {
    final id = water ? _waterServiceId : _electricityServiceId;
    final options = _rateOptions(water: water);
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: DropdownButtonFormField<String>(
        initialValue: options.any((service) => service.id == id) ? id : '',
        isExpanded: true,
        style: const TextStyle(
          color: Color(0xFF102F67),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: _inputDecoration(
          water ? 'Dịch vụ nước trong bảng giá' : 'Dịch vụ điện trong bảng giá',
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Chọn dịch vụ')),
          for (final service in options)
            DropdownMenuItem(
              value: service.id,
              child: Text(
                '${service.name} · ${formatLandlordMoney(_servicePriceForRoom(_room, service))}/${service.unit} · ${service.basis}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        validator: (value) => value == null || value.isEmpty
            ? 'Chọn dịch vụ trong Bảng giá & dịch vụ.'
            : null,
        onChanged: (value) {
          final service = _serviceRecord(value);
          setState(() {
            if (water) {
              _waterServiceId = value ?? '';
              _water.text = _servicePriceForRoom(_room, service).toString();
              _waterType = _waterTypeForService(service);
            } else {
              _electricityServiceId = value ?? '';
              _electricity.text = _servicePriceForRoom(
                _room,
                service,
              ).toString();
            }
          });
        },
      ),
    );
  }

  Widget _serviceFields() => Padding(
    padding: const EdgeInsets.only(top: 15),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4E3FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DỊCH VỤ ÁP DỤNG THEO LOẠI PHÒNG',
            style: TextStyle(
              color: landlordBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          if (_contractServices.isEmpty)
            Text(
              'Loại phòng này chưa gắn thêm dịch vụ nào.',
              style: TextStyle(
                color: LandlordPalette.of(context).muted,
                fontSize: 12,
              ),
            )
          else
            for (final service in _contractServices)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: landlordBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              color: Color(0xFF102F67),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${formatLandlordMoney(service.price)}/${service.unit} · ${service.basis}${_serviceQuantityDescription(service)}',
                            style: TextStyle(
                              color: LandlordPalette.of(context).muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isItemBasis(service.basis))
                      SizedBox(
                        width: 94,
                        child: TextFormField(
                          key: ValueKey(
                            'quantity-${_room}-${service.serviceId}',
                          ),
                          initialValue: service.quantity.toString(),
                          keyboardType: TextInputType.number,
                          validator: _nonNegativeAmountValidator,
                          onChanged: (value) => setState(
                            () => _setItemServiceQuantity(
                              service.serviceId,
                              _parseInt(value) ?? 0,
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF102F67),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: _inputDecoration('Số ${service.unit}')
                              .copyWith(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                        ),
                      ),
                    if (_isItemBasis(service.basis)) const SizedBox(width: 8),
                    Text(
                      formatLandlordMoney(service.amount),
                      style: const TextStyle(
                        color: Color(0xFF102F67),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    ),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF526991)),
    floatingLabelStyle: const TextStyle(
      color: landlordBlue,
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD4E3FF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD4E3FF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: landlordBlue, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD64545)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD64545), width: 1.4),
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    TextCapitalization capitalization = TextCapitalization.none,
  }) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF102F67),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(label),
    ),
  );

  Widget _textArea(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        color: Color(0xFF102F67),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(label).copyWith(alignLabelWithHint: true),
    ),
  );

  String? Function(String?) _requiredValidator(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  String? _citizenIdValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 9 || digits.length == 12
        ? null
        : 'CCCD cần có 9 hoặc 12 chữ số.';
  }

  String? _phoneValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 9 && digits.length <= 12
        ? null
        : 'Nhập số điện thoại hợp lệ.';
  }

  String? _birthYearValidator(String? value) {
    final year = int.tryParse((value ?? '').trim());
    return year != null && year >= 1900 && year <= DateTime.now().year
        ? null
        : 'Nhập năm sinh hợp lệ.';
  }

  String? _positiveAmountValidator(String? value) {
    final amount = _parseInt(value);
    return amount != null && amount > 0 ? null : 'Số tiền phải lớn hơn 0.';
  }

  String? _nonNegativeAmountValidator(String? value) {
    final amount = _parseInt(value);
    return amount != null && amount >= 0 ? null : 'Nhập số tiền hợp lệ.';
  }

  String? _dueDayValidator(String? value) {
    final day = _parseInt(value);
    return day != null && day >= 1 && day <= 31
        ? null
        : 'Ngày đóng tiền từ 1 đến 31.';
  }

  String? _termMonthsValidator(String? value) {
    final months = _parseInt(value);
    return months != null && months >= 1 && months <= 120
        ? null
        : 'Thời hạn từ 1 đến 120 tháng.';
  }

  String? _occupantsValidator(String? value) {
    final count = _parseInt(value);
    return count != null && count >= 1 && count <= 30
        ? null
        : 'Số người ở từ 1 đến 30.';
  }

  String? _bankAccountValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 6 && digits.length <= 20
        ? null
        : 'Số tài khoản cần có 6–20 chữ số.';
  }

  int? _parseInt(String? value) =>
      int.tryParse((value ?? '').replaceAll(RegExp(r'[^0-9]'), ''));

  Widget _dateField(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onChanged, {
    DateTime? lastDate,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(1900),
          lastDate: lastDate ?? DateTime(2035),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: Icon(Icons.calendar_month_outlined),
          errorText: required && date == null ? 'Vui lòng chọn ngày' : null,
        ),
        child: Text(
          date == null ? 'Chọn ngày' : landlordDate(date),
          style: TextStyle(
            color: date == null
                ? LandlordPalette.of(context).muted
                : LandlordPalette.of(context).ink,
          ),
        ),
      ),
    ),
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_tenantIssueDate == null) {
      showLandlordMessage(context, 'Chọn ngày cấp CCCD bên B.');
      return;
    }
    if (_tenantBirthDate == null && _birthYear.text.trim().isEmpty) {
      showLandlordMessage(context, 'Chọn ngày sinh bên B.');
      return;
    }
    if (_end.isBefore(_start)) {
      showLandlordMessage(
        context,
        'Ngày kết thúc phải từ ngày bắt đầu trở đi.',
      );
      return;
    }
    if (!_cashEnabled && !_bankEnabled) {
      showLandlordMessage(context, 'Chọn ít nhất một phương thức thanh toán.');
      return;
    }
    Navigator.pop(
      context,
      _LeaseDraft(
        tenantKey: _tenantKey.text.trim(),
        room: _room,
        rentalAddress: _rentalAddress.text,
        landlordName: _landlordName.text,
        landlordPermanentAddress: _landlordAddress.text,
        landlordCitizenId: _landlordId.text.replaceAll(RegExp(r'[^0-9]'), ''),
        landlordContact: _landlordContact.text,
        landlordBirthDate: _landlordBirthDate,
        landlordCitizenIssueDate: _landlordIssueDate,
        landlordCitizenIssuePlace: _landlordIssuePlace.text,
        tenantName: _name.text,
        tenantBirthYear: _tenantBirthDate?.year.toString() ?? _birthYear.text,
        tenantBirthDate: _tenantBirthDate,
        tenantCitizenId: _tenantId.text.replaceAll(RegExp(r'[^0-9]'), ''),
        tenantCitizenIssueDate: _tenantIssueDate,
        tenantCitizenIssuePlace: _tenantIssuePlace.text,
        tenantPermanentAddress: _tenantAddress.text,
        phone: _phone.text,
        startDate: _start,
        endDate: _end,
        monthlyRent: _parseInt(_rent.text)!,
        deposit: _parseInt(_deposit.text)!,
        termMonths: _parseInt(_termMonths.text)!,
        electricityPrice: _parseInt(_electricity.text)!,
        waterPrice: _parseInt(_water.text)!,
        waterType: _waterType,
        vehicleFee: 0,
        serviceFee: _contractServices.fold<int>(
          0,
          (sum, service) => sum + service.amount,
        ),
        serviceId: _contractServices.firstOrNull?.serviceId ?? '',
        serviceName: _contractServices.firstOrNull?.name ?? '',
        serviceUnit: _contractServices.firstOrNull?.unit ?? '',
        serviceBasis: _contractServices.firstOrNull?.basis ?? '',
        services: List.unmodifiable(_contractServices),
        electricityServiceId: _electricityServiceId,
        waterServiceId: _waterServiceId,
        dueDay: _parseInt(_dueDay.text)!,
        cashPaymentEnabled: _cashEnabled,
        cashPaymentLocation: _cashLocation.text,
        bankTransferEnabled: _bankEnabled,
        bankName: _bankName.text,
        bankAccountNumber: _bankAccount.text.replaceAll(RegExp(r'[^0-9]'), ''),
        occupantCount: _parseInt(_occupants.text)!,
        note: _note.text,
        status: _status,
        responsibilityA: _responsibilityA.text,
        responsibilityB: _responsibilityB.text,
        commonResponsibilities: _commonResponsibilities.text,
        templateId: _templateId ?? '',
      ),
    );
  }
}

class _LeaseTemplateDraft {
  const _LeaseTemplateDraft({
    required this.name,
    required this.landlordName,
    required this.landlordPermanentAddress,
    required this.landlordCitizenId,
    required this.landlordContact,
    required this.landlordBirthDate,
    required this.landlordCitizenIssueDate,
    required this.landlordCitizenIssuePlace,
    required this.electricityPrice,
    required this.waterPrice,
    required this.waterType,
    required this.electricityServiceId,
    required this.waterServiceId,
    required this.cashPaymentEnabled,
    required this.cashPaymentLocation,
    required this.bankTransferEnabled,
    required this.bankName,
    required this.bankAccountNumber,
    required this.responsibilityA,
    required this.responsibilityB,
    required this.commonResponsibilities,
  });

  final String name;
  final String landlordName;
  final String landlordPermanentAddress;
  final String landlordCitizenId;
  final String landlordContact;
  final DateTime? landlordBirthDate;
  final DateTime? landlordCitizenIssueDate;
  final String landlordCitizenIssuePlace;
  final int electricityPrice;
  final int waterPrice;
  final String waterType;
  final String electricityServiceId;
  final String waterServiceId;
  final bool cashPaymentEnabled;
  final String cashPaymentLocation;
  final bool bankTransferEnabled;
  final String bankName;
  final String bankAccountNumber;
  final String responsibilityA;
  final String responsibilityB;
  final String commonResponsibilities;
}

class _LeaseTemplateEditor extends StatefulWidget {
  const _LeaseTemplateEditor({required this.store, this.template});

  final LandlordDemoStore store;
  final LandlordLeaseTemplate? template;

  @override
  State<_LeaseTemplateEditor> createState() => _LeaseTemplateEditorState();
}

class _LeaseTemplateEditorState extends State<_LeaseTemplateEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.template?.name ?? 'Mẫu hợp đồng chung',
  );
  late final _landlordName = TextEditingController(
    text: widget.template?.landlordName ?? widget.store.property.ownerName,
  );
  late final _landlordAddress = TextEditingController(
    text:
        widget.template?.landlordPermanentAddress ??
        widget.store.property.address,
  );
  late final _landlordId = TextEditingController(
    text: widget.template?.landlordCitizenId ?? '',
  );
  late final _landlordContact = TextEditingController(
    text: widget.template?.landlordContact ?? widget.store.property.phone,
  );
  late final _issuePlace = TextEditingController(
    text: widget.template?.landlordCitizenIssuePlace ?? '',
  );
  late final _cashLocation = TextEditingController(
    text: widget.template?.cashPaymentLocation ?? widget.store.property.address,
  );
  late final _bankName = TextEditingController(
    text:
        widget.template?.bankName ??
        widget.store.defaultPaymentAccount?.bankName ??
        '',
  );
  late final _bankAccount = TextEditingController(
    text:
        widget.template?.bankAccountNumber ??
        widget.store.defaultPaymentAccount?.accountNumber ??
        '',
  );
  late final _electricity = TextEditingController(
    text:
        (_serviceRecord(_electricityServiceId)?.price ??
                widget.template?.electricityPrice ??
                3500)
            .toString(),
  );
  late final _water = TextEditingController(
    text:
        (_serviceRecord(_waterServiceId)?.price ??
                widget.template?.waterPrice ??
                15000)
            .toString(),
  );
  late final _responsibilityA = TextEditingController(
    text: widget.template?.responsibilityA ?? '',
  );
  late final _responsibilityB = TextEditingController(
    text: widget.template?.responsibilityB ?? '',
  );
  late final _commonResponsibilities = TextEditingController(
    text: widget.template?.commonResponsibilities ?? 'Hai bên cùng thực hiện đúng các thỏa thuận trong hợp đồng. Nếu có phát sinh, hai bên ưu tiên trao đổi và thống nhất; trường hợp không thống nhất được thì thực hiện theo quy định pháp luật.',
  );
  late DateTime? _birthDate = widget.template?.landlordBirthDate;
  late DateTime? _issueDate = widget.template?.landlordCitizenIssueDate;
  late String _electricityServiceId =
      widget.template?.electricityServiceId ??
      widget.store.serviceById('electricity')?.id ??
      '';
  late String _waterServiceId =
      widget.template?.waterServiceId ??
      widget.store.serviceById('water')?.id ??
      '';
  late String _waterType =
      widget.template?.waterType ??
      _waterTypeForService(_serviceRecord(_waterServiceId));
  late bool _cashEnabled = widget.template?.cashPaymentEnabled ?? true;
  late bool _bankEnabled =
      widget.template?.bankTransferEnabled ??
      (widget.store.defaultPaymentAccount != null);

  LandlordService? _serviceRecord(String? id) =>
      id == null || id.isEmpty ? null : widget.store.serviceRecordById(id);

  List<LandlordService> _rateOptions({required bool water}) {
    final matches = widget.store.services.where((service) {
      if (!service.active) return false;
      final name = service.name.toLowerCase();
      final unit = service.unit.toLowerCase();
      return water
          ? service.id == 'water' ||
                name.contains('nước') ||
                unit.contains('m³')
          : service.id == 'electricity' ||
                name.contains('điện') ||
                unit == 'kwh';
    }).toList();
    final selected = _serviceRecord(
      water ? _waterServiceId : _electricityServiceId,
    );
    if (selected != null &&
        !matches.any((service) => service.id == selected.id)) {
      matches.add(selected);
    }
    return matches;
  }

  @override
  void dispose() {
    _name.dispose();
    _landlordName.dispose();
    _landlordAddress.dispose();
    _landlordId.dispose();
    _landlordContact.dispose();
    _issuePlace.dispose();
    _cashLocation.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _electricity.dispose();
    _water.dispose();
    _responsibilityA.dispose();
    _responsibilityB.dispose();
    _commonResponsibilities.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F8FF),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 690,
              maxHeight: constraints.maxHeight,
            ),
            child: SizedBox.expand(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40547AB4),
                      blurRadius: 34,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 14, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.template == null
                                        ? 'Tạo hợp đồng mẫu chung'
                                        : 'Chỉnh sửa hợp đồng mẫu',
                                    style: const TextStyle(
                                      color: Color(0xFF102F67),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Thông tin bên A và điều khoản sẽ được điền sẵn khi tạo hợp đồng.',
                                    style: TextStyle(
                                      color: LandlordPalette.of(context).muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _field(
                                _name,
                                'Tên mẫu',
                                validator: _required('Nhập tên mẫu.'),
                              ),
                              _heading('BÊN A · CHỦ TRỌ'),
                              _field(
                                _landlordName,
                                'Họ tên bên A',
                                validator: _required('Nhập họ tên bên A.'),
                              ),
                              _picker('Sinh ngày bên A', _birthDate, (date) {
                                setState(() => _birthDate = date);
                              }),
                              _field(
                                _landlordAddress,
                                'Nơi đăng ký HKTT',
                                validator: _required('Nhập nơi đăng ký HKTT.'),
                              ),
                              _field(
                                _landlordId,
                                'CCCD bên A',
                                keyboardType: TextInputType.number,
                                validator: _citizenId,
                              ),
                              _row(
                                _picker('Ngày cấp CCCD', _issueDate, (date) {
                                  setState(() => _issueDate = date);
                                }),
                                _field(_issuePlace, 'Nơi cấp CCCD'),
                              ),
                              _field(
                                _landlordContact,
                                'Số điện thoại liên hệ',
                                keyboardType: TextInputType.phone,
                                validator: _phone,
                              ),
                              _heading('GIÁ VÀ THANH TOÁN MẶC ĐỊNH'),
                              _rateDropdown(water: false),
                              _field(
                                _electricity,
                                'Đơn giá điện / kWh',
                                readOnly: true,
                              ),
                              _rateDropdown(water: true),
                              _field(_water, 'Đơn giá nước', readOnly: true),
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Đơn vị nước: ${_waterUnit(_waterType)} · lấy theo dịch vụ đã chọn.',
                                  style: TextStyle(
                                    color: LandlordPalette.of(context).muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: _cashEnabled,
                                onChanged: (value) => setState(
                                  () => _cashEnabled = value ?? false,
                                ),
                                title: const Text('Nhận tiền mặt'),
                              ),
                              if (_cashEnabled)
                                _field(
                                  _cashLocation,
                                  'Điểm nhận tiền mặt',
                                  validator: _required(
                                    'Nhập điểm nhận tiền mặt.',
                                  ),
                                ),
                              CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: _bankEnabled,
                                onChanged: (value) => setState(
                                  () => _bankEnabled = value ?? false,
                                ),
                                title: const Text('Chuyển khoản ngân hàng'),
                              ),
                              if (_bankEnabled) ...[
                                _field(
                                  _bankName,
                                  'Tên ngân hàng',
                                  validator: _required('Nhập tên ngân hàng.'),
                                ),
                                _field(
                                  _bankAccount,
                                  'Số tài khoản',
                                  keyboardType: TextInputType.number,
                                  validator: _account,
                                ),
                              ],
                              _heading('TRÁCH NHIỆM CÁC BÊN'),
                              _area(_responsibilityA, 'Trách nhiệm của bên A'),
                              _area(_responsibilityB, 'Trách nhiệm của bên B'),
                              _area(
                                _commonResponsibilities,
                                'Trách nhiệm chung',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _save,
                              style: FilledButton.styleFrom(
                                backgroundColor: landlordBlue,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Lưu mẫu'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD4E3FF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD4E3FF)),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        color: Color(0xFF102F67),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: _decoration(label),
    ),
  );

  Widget _rateDropdown({required bool water}) {
    final id = water ? _waterServiceId : _electricityServiceId;
    final options = _rateOptions(water: water);
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: DropdownButtonFormField<String>(
        initialValue: options.any((service) => service.id == id) ? id : '',
        isExpanded: true,
        decoration: _decoration(
          water ? 'Dịch vụ nước trong bảng giá' : 'Dịch vụ điện trong bảng giá',
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Chọn dịch vụ')),
          for (final service in options)
            DropdownMenuItem(
              value: service.id,
              child: Text(
                '${service.name} · ${formatLandlordMoney(service.price)}/${service.unit} · ${service.basis}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        validator: (value) => value == null || value.isEmpty
            ? 'Chọn dịch vụ trong Bảng giá & dịch vụ.'
            : null,
        onChanged: (value) {
          final selected = _serviceRecord(value);
          setState(() {
            if (water) {
              _waterServiceId = value ?? '';
              _water.text = (selected?.price ?? 0).toString();
              _waterType = _waterTypeForService(selected);
            } else {
              _electricityServiceId = value ?? '';
              _electricity.text = (selected?.price ?? 0).toString();
            }
          });
        },
      ),
    );
  }

  Widget _area(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 5,
      style: const TextStyle(color: Color(0xFF102F67), fontSize: 13),
      decoration: _decoration(label).copyWith(alignLabelWithHint: true),
    ),
  );

  Widget _row(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 460
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, second],
          )
        : Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 10),
              Expanded(child: second),
            ],
          ),
  );

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 3),
    child: Text(
      title,
      style: const TextStyle(
        color: landlordBlue,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: .35,
      ),
    ),
  );

  Widget _picker(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: _decoration(label)
            .copyWith(suffixIcon: const Icon(Icons.calendar_month_outlined)),
        child: Text(
          date == null ? 'Chọn ngày' : landlordDate(date),
          style: TextStyle(
            color: date == null
                ? LandlordPalette.of(context).muted
                : LandlordPalette.of(context).ink,
            fontSize: 14,
          ),
        ),
      ),
    ),
  );

  String? Function(String?) _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  String? _citizenId(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 9 || digits.length == 12
        ? null
        : 'CCCD cần có 9 hoặc 12 chữ số.';
  }

  String? _phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 9 && digits.length <= 12
        ? null
        : 'Nhập số điện thoại hợp lệ.';
  }

  int? _amount(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));

  String? _positiveAmount(String? value) {
    final amount = _amount(value ?? '');
    return amount != null && amount > 0 ? null : 'Nhập số tiền lớn hơn 0.';
  }

  String? _nonNegativeAmount(String? value) {
    final amount = _amount(value ?? '');
    return amount != null && amount >= 0 ? null : 'Nhập số tiền hợp lệ.';
  }

  String? _account(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 6 && digits.length <= 20
        ? null
        : 'Số tài khoản cần có 6–20 chữ số.';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_cashEnabled && !_bankEnabled) {
      showLandlordMessage(context, 'Chọn ít nhất một phương thức thanh toán.');
      return;
    }
    Navigator.pop(
      context,
      _LeaseTemplateDraft(
        name: _name.text,
        landlordName: _landlordName.text,
        landlordPermanentAddress: _landlordAddress.text,
        landlordCitizenId: _landlordId.text.replaceAll(RegExp(r'[^0-9]'), ''),
        landlordContact: _landlordContact.text,
        landlordBirthDate: _birthDate,
        landlordCitizenIssueDate: _issueDate,
        landlordCitizenIssuePlace: _issuePlace.text,
        electricityPrice: _amount(_electricity.text)!,
        waterPrice: _amount(_water.text)!,
        waterType: _waterType,
        electricityServiceId: _electricityServiceId,
        waterServiceId: _waterServiceId,
        cashPaymentEnabled: _cashEnabled,
        cashPaymentLocation: _cashLocation.text,
        bankTransferEnabled: _bankEnabled,
        bankName: _bankName.text,
        bankAccountNumber: _bankAccount.text,
        responsibilityA: _responsibilityA.text,
        responsibilityB: _responsibilityB.text,
        commonResponsibilities: _commonResponsibilities.text,
      ),
    );
  }
}
