import 'package:flutter/material.dart';

import '../landlord_theme.dart';
import '../landlord_glass.dart';
import '../finance/landlord_room_balance.dart';
import '../finance/landlord_room_balance_card.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_ui.dart';
import '../../shared/widgets/list_pagination.dart';

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
  LandlordDemoStore get _store =>
      widget.store ?? LandlordDemoStore.activeInstance;
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  String _roomFilter = 'Tất cả';
  int _roomPage = 0;
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([RentalPortfolio.instance, _store]),
    builder: (context, _) {
      final balances = landlordRoomBalances(_store, _period);
      bool matches(LandlordRoomBalance b, String filter) => switch (filter) {
        'Chưa đóng' => b.state == RoomPaymentState.unpaid,
        'Đã đóng' => b.state == RoomPaymentState.paid,
        'Chưa lập hóa đơn' => b.state == RoomPaymentState.unbilled,
        'Phòng trống' => b.state == RoomPaymentState.vacant,
        _ => true,
      };
      final rooms =
          balances
              .where(
                (b) =>
                    matches(b, _roomFilter) &&
                    '${b.details.room.code} ${b.details.lease?.tenantName ?? ''}'
                        .toLowerCase()
                        .contains(_query.trim().toLowerCase()),
              )
              .toList()
            ..sort((a, b) {
              final state = a.state.index.compareTo(b.state.index);
              return state != 0
                  ? state
                  : a.details.room.code.compareTo(b.details.room.code);
            });
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
      return LandlordGlassPage(
        store: _store,
        profileName: widget.profileName,
        title: 'Theo dõi thu chi',
        kicker: 'QUẢN LÝ TÀI CHÍNH',
        subtitle: 'Trạng thái đóng tiền theo từng phòng.',
        children: [
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
                    'Chưa lập hóa đơn',
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
            subtitle: 'Đỏ: chưa đóng · Xanh: đã đóng tiền',
            trailing: IconButton.filledTonal(
              tooltip: 'Lập hóa đơn',
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
                DropdownMenuItem(
                  value: month,
                  child: Text(landlordMonth(month)),
                ),
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
          LandlordGlassSearch(
            controller: _search,
            hint: 'Tìm phòng hoặc tên người thuê',
            onChanged: (value) => setState(() {
              _query = value;
              _roomPage = 0;
            }),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in const [
                  'Tất cả',
                  'Chưa đóng',
                  'Đã đóng',
                  'Chưa lập hóa đơn',
                  'Phòng trống',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(
                        '$filter · ${balances.where((b) => matches(b, filter)).length}',
                      ),
                      selected: _roomFilter == filter,
                      onSelected: (_) => setState(() {
                        _roomFilter = filter;
                        _roomPage = 0;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (rooms.isEmpty)
            const LandlordGlassCard(
              child: Text('Không có phòng phù hợp với bộ lọc.'),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final balance in rooms.skip(roomPage * 12).take(12))
                    SizedBox(
                      width: width,
                      child: LandlordRoomBalanceCard(
                        balance: balance,
                        onTap: () => _showRoomInvoices(balance),
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
            onChanged: (value) => setState(() => _roomPage = value),
          ),
          const SizedBox(height: 24),
          LandlordGlassSection(
            title: 'Lịch sử hóa đơn',
            subtitle: '${_store.invoices.length} hóa đơn của nhà trọ',
            trailing: TextButton.icon(
              onPressed: _store.activeLeases.isEmpty ? null : _createInvoice,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Lập hóa đơn'),
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
      );
    },
  );

  Future<void> _showRoomInvoices(LandlordRoomBalance balance) async {
    final selected = await showModalBottomSheet<Object>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phòng ${balance.details.room.code}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(balance.details.lease?.tenantName ?? 'Chưa có người thuê'),
            const SizedBox(height: 14),
            LandlordStatusPill(
              balance.label,
              color: roomPaymentColor(balance.state),
            ),
            const SizedBox(height: 14),
            Text(
              'Còn phải thu: ${formatLandlordMoney(balance.remaining)}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (balance.invoices.isEmpty)
              const Text(
                'Chưa có hóa đơn cho phòng này trong tháng đã chọn hoặc các tháng trước.',
              ),
            for (final invoice in balance.invoices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.receipt_long_outlined,
                  color: invoice.remaining > 0
                      ? const Color(0xFFDA4458)
                      : const Color(0xFF17A374),
                ),
                title: Text('${invoice.id} · ${landlordMonth(invoice.period)}'),
                subtitle: Text(
                  '${invoice.status.label} · ${formatLandlordMoney(invoice.remaining)} còn lại',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, invoice),
              ),
            if (balance.details.lease?.isCurrent == true &&
                balance.monthlyInvoices.isEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Lập hóa đơn cho phòng này'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (selected is LandlordInvoice) await _showDetails(selected);
    if (selected == true) {
      await _createInvoice(initialLeaseId: balance.details.lease!.id);
    }
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
      if (lease.waterType == 'Theo tháng' && lease.waterPrice > 0)
        LandlordInvoiceCharge(
          name: 'Nước · theo tháng',
          amount: lease.waterPrice,
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
        'Đã lập hóa đơn ${invoice.id} · ${formatLandlordMoney(invoice.total)}.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
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
  });
  final List<LandlordLease> leases;
  final LandlordDemoStore store;
  final String? initialLeaseId;
  final DateTime? period;

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
            : waterM3 * _lease.waterPrice) +
        _lease.vehicleFee +
        _lease.serviceFee +
        extraFee;
    return AlertDialog(
      title: Text('Lập hóa đơn'),
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
                  for (final period in _periods)
                    DropdownMenuItem(
                      value: _key(period),
                      child: Text(landlordMonth(period)),
                    ),
                ],
                onChanged: (value) => setState(() {
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
              if (_lease.waterType == 'Theo tháng')
                _contractChargeLine(
                  'Tiền nước',
                  '${formatLandlordMoney(_lease.waterPrice)}/tháng',
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
