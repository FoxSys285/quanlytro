import 'package:flutter/material.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_ui.dart';

class LandlordBillingPage extends StatefulWidget {
  const LandlordBillingPage({super.key});

  @override
  State<LandlordBillingPage> createState() => _LandlordBillingPageState();
}

class _LandlordBillingPageState extends State<LandlordBillingPage> {
  final _store = LandlordDemoStore.instance;
  String _filter = 'Tất cả';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final invoices = _store.invoices.where((invoice) {
        if (_filter == 'Chưa thanh toán') {
          return invoice.status == LandlordInvoiceStatus.unpaid ||
              invoice.status == LandlordInvoiceStatus.overdue;
        }
        if (_filter == 'Thanh toán một phần')
          return invoice.status == LandlordInvoiceStatus.partial;
        if (_filter == 'Đã thanh toán')
          return invoice.status == LandlordInvoiceStatus.paid;
        return true;
      }).toList()..sort((a, b) => b.period.compareTo(a.period));
      final debt = _store.payableInvoices.fold<int>(
        0,
        (sum, invoice) => sum + invoice.remaining,
      );
      final pendingCount = _store.payments
          .where((payment) => payment.status == LandlordPaymentStatus.pending)
          .length;

      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Hóa đơn',
            subtitle:
                '${_store.invoices.length} hóa đơn · ${formatLandlordMoney(debt)} chưa thu',
            trailing: FilledButton.icon(
              onPressed: _store.activeLeases.isEmpty ? null : _createInvoice,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Lập hóa đơn'),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Còn phải thu',
                  formatLandlordMoney(debt),
                  Icons.account_balance_wallet_outlined,
                  landlordBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metric(
                  'Chờ duyệt',
                  '$pendingCount khoản',
                  Icons.fact_check_outlined,
                  const Color(0xFFE08A1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      label: Text(label),
                      selected: _filter == label,
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            const LandlordEmptyState(
              message: 'Chưa có hóa đơn trong trạng thái này.',
            ),
          for (final invoice in invoices) _invoiceCard(invoice),
          const SizedBox(height: 4),
          const Text(
            'Số tiền đã thu chỉ thay đổi khi chủ trọ xác nhận khoản thanh toán.',
            style: TextStyle(color: landlordMuted, fontSize: 11),
          ),
        ],
      );
    },
  );

  Widget _metric(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: landlordLine),
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
                    style: const TextStyle(color: landlordMuted, fontSize: 10),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: landlordInk,
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
    return LandlordCard(
      onTap: () => _showDetails(invoice),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: landlordBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: landlordBlue,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${invoice.room} · ${landlordMonth(invoice.period)}',
                      style: const TextStyle(
                        color: landlordInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${invoice.id} · ${invoice.tenantName}',
                      style: const TextStyle(
                        color: landlordMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              LandlordStatusPill(label, color: color),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng cộng',
                  style: const TextStyle(color: landlordMuted, fontSize: 12),
                ),
              ),
              Text(
                formatLandlordMoney(invoice.total),
                style: const TextStyle(
                  color: landlordInk,
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
                  style: const TextStyle(color: landlordMuted, fontSize: 11),
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
    );
  }

  (String, Color) _invoiceStatus(LandlordInvoiceStatus status) =>
      switch (status) {
        LandlordInvoiceStatus.unpaid => (
          'Chưa thanh toán',
          const Color(0xFFE08A1E),
        ),
        LandlordInvoiceStatus.partial => ('Thanh toán một phần', landlordBlue),
        LandlordInvoiceStatus.paid => (
          'Đã thanh toán',
          const Color(0xFF16836F),
        ),
        LandlordInvoiceStatus.overdue => ('Quá hạn', const Color(0xFFD64545)),
        LandlordInvoiceStatus.cancelled => ('Đã hủy', landlordMuted),
      };

  Future<void> _showDetails(LandlordInvoice invoice) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final (status, color) = _invoiceStatus(invoice.status);
        return SafeArea(
          child: Padding(
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: landlordInk,
                        ),
                      ),
                    ),
                    LandlordStatusPill(status, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng ${invoice.room} · ${invoice.tenantName} · ${landlordMonth(invoice.period)}',
                  style: const TextStyle(color: landlordMuted, fontSize: 12),
                ),
                const Divider(height: 24),
                for (final charge in invoice.charges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            charge.name,
                            style: const TextStyle(
                              color: landlordInk,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          formatLandlordMoney(charge.amount),
                          style: const TextStyle(
                            color: landlordInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 20),
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
                            title: const Text('Hủy hóa đơn?'),
                            content: const Text(
                              'Hóa đơn sẽ được giữ trong lịch sử với trạng thái đã hủy.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Quay lại'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Hủy hóa đơn'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            _store.cancelInvoice(invoice);
                            if (context.mounted) Navigator.pop(context);
                          } on ArgumentError catch (error) {
                            if (context.mounted)
                              showLandlordMessage(
                                context,
                                error.message.toString(),
                              );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy hóa đơn'),
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
            color: bold ? landlordInk : landlordMuted,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
      ),
      Text(
        formatLandlordMoney(amount),
        style: TextStyle(
          color: landlordInk,
          fontSize: bold ? 14 : 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );

  Future<void> _createInvoice() async {
    final draft = await showDialog<_InvoiceDraft>(
      context: context,
      builder: (_) => _InvoiceEditor(leases: _store.activeLeases),
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
  const _InvoiceEditor({required this.leases});
  final List<LandlordLease> leases;

  @override
  State<_InvoiceEditor> createState() => _InvoiceEditorState();
}

class _InvoiceEditorState extends State<_InvoiceEditor> {
  late String _leaseId = widget.leases.first.id;
  late DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _dueDate = _dueDateFor(
    DateTime(DateTime.now().year, DateTime.now().month),
    widget.leases.first.dueDay,
  );
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

  List<DateTime> get _periods {
    final now = DateTime.now();
    return [
      for (var offset = -2; offset <= 1; offset++)
        DateTime(now.year, now.month + offset),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final periodByKey = {for (final period in _periods) _key(period): period};
    return AlertDialog(
      title: const Text('Lập hóa đơn'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _leaseId,
                decoration: const InputDecoration(
                  labelText: 'Hợp đồng / phòng',
                ),
                items: [
                  for (final lease in widget.leases)
                    DropdownMenuItem(
                      value: lease.id,
                      child: Text('${lease.room} · ${lease.tenantName}'),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _leaseId = value ?? _leaseId;
                  _electric.clear();
                  _water.clear();
                  _dueDate = _dueDateFor(_period, _lease.dueDay);
                }),
              ),
              DropdownButtonFormField<String>(
                initialValue: _key(_period),
                decoration: const InputDecoration(labelText: 'Kỳ hóa đơn'),
                items: [
                  for (final period in _periods)
                    DropdownMenuItem(
                      value: _key(period),
                      child: Text(landlordMonth(period)),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _period = periodByKey[value] ?? _period;
                  _dueDate = _dueDateFor(_period, _lease.dueDay);
                }),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Tiền thuê phòng: ${formatLandlordMoney(_lease.monthlyRent)}',
                    style: const TextStyle(
                      color: landlordInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _electric,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Điện tiêu thụ (kWh)',
                      ),
                    ),
                  ),
                  if (_lease.waterType == 'Theo m³') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _water,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nước tiêu thụ (m³)',
                          helperText:
                              '${formatLandlordMoney(_lease.waterPrice)}/m³',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_lease.waterType == 'Theo tháng')
                _contractChargeLine(
                  'Tiền nước',
                  '${formatLandlordMoney(_lease.waterPrice)}/tháng',
                ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _extraName,
                      decoration: const InputDecoration(
                        labelText: 'Khoản thu khác',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _extra,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền (đ)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                  decoration: const InputDecoration(
                    labelText: 'Ngày đến hạn',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(landlordDate(_dueDate)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đơn giá, tiền xe và dịch vụ lấy từ hợp đồng đang chọn.',
                style: TextStyle(color: landlordMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _save, child: const Text('Phát hành hóa đơn')),
      ],
    );
  }

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Widget _contractChargeLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: landlordMuted)),
        ),
        Text(
          value,
          style: const TextStyle(
            color: landlordInk,
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
