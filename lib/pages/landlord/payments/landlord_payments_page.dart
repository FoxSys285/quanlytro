import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../landlord_theme.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_ui.dart';
import '../../../layouts/role_layout.dart';

class LandlordPaymentsPage extends StatefulWidget {
  const LandlordPaymentsPage({super.key, this.focusPaymentId});

  final String? focusPaymentId;

  static String? _requestedPaymentId;

  static bool navigateToPayment(BuildContext context, String paymentId) {
    _requestedPaymentId = paymentId;
    final navigated = RoleLayoutShell.tryNavigateTo(context, 'payments');
    if (!navigated) _requestedPaymentId = null;
    return navigated;
  }

  @override
  State<LandlordPaymentsPage> createState() => _LandlordPaymentsPageState();
}

class _LandlordPaymentsPageState extends State<LandlordPaymentsPage> {
  final _store = LandlordDemoStore.activeInstance;
  String _filter = 'Chờ duyệt';
  late final String? _focusPaymentId =
      widget.focusPaymentId ?? LandlordPaymentsPage._requestedPaymentId;

  @override
  void initState() {
    super.initState();
    LandlordPaymentsPage._requestedPaymentId = null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final pending = _store.payments
          .where((payment) => payment.status == LandlordPaymentStatus.pending)
          .length;
      final pendingAmount = _store.payments
          .where((payment) => payment.status == LandlordPaymentStatus.pending)
          .fold<int>(0, (sum, payment) => sum + payment.reportedAmount);
      final approvedCount = _store.payments
          .where((payment) => payment.status == LandlordPaymentStatus.approved)
          .length;
      final rejectedCount = _store.payments
          .where((payment) => payment.status == LandlordPaymentStatus.rejected)
          .length;
      final payments =
          _store.payments.where((payment) {
            if (_filter == 'Chờ duyệt') {
              return payment.status == LandlordPaymentStatus.pending;
            }
            if (_filter == 'Đã xác nhận') {
              return payment.status == LandlordPaymentStatus.approved;
            }
            if (_filter == 'Từ chối') {
              return payment.status == LandlordPaymentStatus.rejected;
            }
            return true;
          }).toList()..sort((a, b) {
            if (a.id == _focusPaymentId) return -1;
            if (b.id == _focusPaymentId) return 1;
            return b.paidAt.compareTo(a.paidAt);
          });
      return LandlordFeaturePage(
        title: 'Duyệt thanh toán',
        subtitle: 'Đối soát giao dịch và cập nhật hóa đơn người thuê.',
        icon: Icons.fact_check_outlined,
        children: [
          LandlordGlassSection(
            title: 'Tổng quan',
            subtitle:
                '$pending khoản đang chờ · khoản mới nhất hiển thị trước.',
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF438EFF), Color(0xFF154BCC)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30366BDA),
                  blurRadius: 22,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 7.0;
                final metricWidth = (constraints.maxWidth - spacing * 2) / 3;
                return Wrap(
                  spacing: spacing,
                  children: [
                    _paymentMetric(
                      width: metricWidth,
                      label: 'Chờ đối soát',
                      value: '$pending khoản',
                      caption: formatLandlordMoney(pendingAmount),
                      icon: Icons.pending_actions_rounded,
                    ),
                    _paymentMetric(
                      width: metricWidth,
                      label: 'Đã xác nhận',
                      value: '$approvedCount khoản',
                      caption: 'Đã ghi nhận hóa đơn',
                      icon: Icons.verified_outlined,
                    ),
                    _paymentMetric(
                      width: metricWidth,
                      label: 'Đã từ chối',
                      value: '$rejectedCount khoản',
                      caption: 'Đã lưu lý do',
                      icon: Icons.highlight_off_rounded,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 13),
          if (pending > 0)
            LandlordGlassCard(
              tint: const Color(0xFFFFC247),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFB17A23)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đối chiếu mã giao dịch, số tiền và hóa đơn trước khi xác nhận.',
                      style: TextStyle(
                        color: Color(0xFF765B31),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 13),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in const [
                  'Chờ duyệt',
                  'Đã xác nhận',
                  'Từ chối',
                  'Tất cả',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$label · ${_paymentCount(label)}'),
                      selected: _filter == label,
                      selectedColor: landlordBlue,
                      backgroundColor: LandlordPalette.of(context).surface,
                      side: BorderSide(
                        color: _filter == label
                            ? Colors.transparent
                            : Colors.white,
                      ),
                      labelStyle: TextStyle(
                        color: _filter == label ? Colors.white : landlordBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LandlordGlassSection(
            title: _focusPaymentId == null
                ? 'Khoản thanh toán'
                : 'Phiếu thu cần đối soát',
            subtitle: _focusPaymentId != null
                ? 'Đã mở phiếu thu được chọn. Kiểm tra giao dịch để duyệt hoặc không duyệt.'
                : '${payments.length} khoản trong danh sách này.',
          ),
          if (payments.isEmpty)
            const LandlordGlassCard(
              child: Center(
                child: Text(
                  'Không có khoản thanh toán nào trong danh sách này.',
                ),
              ),
            ),
          for (final payment in payments) _paymentCard(payment),
          const SizedBox(height: 4),
          Text(
            'Đối chiếu giao dịch ngân hàng thực tế trước khi xác nhận khoản thanh toán.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LandlordPalette.of(context).muted,
              fontSize: 11,
            ),
          ),
        ],
      );
    },
  );

  int _paymentCount(String label) => _store.payments.where((payment) {
    if (label == 'Chờ duyệt') {
      return payment.status == LandlordPaymentStatus.pending;
    }
    if (label == 'Đã xác nhận') {
      return payment.status == LandlordPaymentStatus.approved;
    }
    if (label == 'Từ chối') {
      return payment.status == LandlordPaymentStatus.rejected;
    }
    return true;
  }).length;

  Widget _paymentMetric({
    required double width,
    required String label,
    required String value,
    required String caption,
    required IconData icon,
  }) => Container(
    width: width,
    padding: const EdgeInsets.fromLTRB(10, 11, 7, 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFE4EEFF), fontSize: 8),
        ),
      ],
    ),
  );

  Widget _paymentCard(LandlordPayment payment) {
    final (label, color) = switch (payment.status) {
      LandlordPaymentStatus.pending => ('Chờ duyệt', const Color(0xFFE08A1E)),
      LandlordPaymentStatus.approved => (
        'Đã xác nhận',
        const Color(0xFF16836F),
      ),
      LandlordPaymentStatus.rejected => ('Từ chối', const Color(0xFFD64545)),
    };
    final invoice = _store.invoiceById(payment.invoiceId);
    final amount = payment.approvedAmount ?? payment.reportedAmount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: LandlordGlassCard(
        onTap: () => _review(payment),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(Icons.payments_outlined, color: color),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${payment.tenantName} · ${payment.room}',
                        style: TextStyle(
                          color: LandlordPalette.of(context).ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${payment.id} · ${landlordDate(payment.paidAt)} ${payment.paidAt.hour.toString().padLeft(2, '0')}:${payment.paidAt.minute.toString().padLeft(2, '0')}',
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
                    'Người thuê báo đã trả',
                    style: TextStyle(
                      color: LandlordPalette.of(context).muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  formatLandlordMoney(payment.reportedAmount),
                  style: TextStyle(
                    color: LandlordPalette.of(context).ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              'Hóa đơn ${payment.invoiceId} · còn nợ ${formatLandlordMoney(invoice?.remaining ?? 0)}',
              style: TextStyle(
                color: LandlordPalette.of(context).muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Mã giao dịch: ${payment.reference}',
              style: TextStyle(
                color: LandlordPalette.of(context).muted,
                fontSize: 11,
              ),
            ),
            if (payment.status == LandlordPaymentStatus.approved &&
                payment.approvedAmount != payment.reportedAmount) ...[
              const SizedBox(height: 7),
              Text(
                'Đã ghi nhận ${formatLandlordMoney(amount)}',
                style: TextStyle(
                  color: Color(0xFF16836F),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (payment.rejectionReason != null) ...[
              const SizedBox(height: 7),
              Text(
                'Lý do: ${payment.rejectionReason}',
                style: TextStyle(color: Color(0xFFD64545), fontSize: 11),
              ),
            ],
            if (payment.status == LandlordPaymentStatus.pending) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _review(payment),
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Kiểm tra và duyệt'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _reject(payment),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Không duyệt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD64545),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _review(LandlordPayment payment) async {
    final invoice = _store.invoiceById(payment.invoiceId);
    if (invoice == null) {
      showLandlordMessage(
        context,
        'Không tìm thấy hóa đơn của khoản thanh toán này.',
      );
      return;
    }
    if (payment.status != LandlordPaymentStatus.pending) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            payment.status == LandlordPaymentStatus.approved
                ? 'Khoản đã xác nhận'
                : 'Khoản đã từ chối',
          ),
          content: Text(
            payment.status == LandlordPaymentStatus.approved
                ? 'Đã ghi nhận ${formatLandlordMoney(payment.approvedAmount ?? payment.reportedAmount)} vào hóa đơn ${payment.invoiceId}.'
                : 'Lý do từ chối: ${payment.rejectionReason ?? 'Không có ghi chú'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }
    final result = await showDialog<_PaymentReviewResult>(
      context: context,
      builder: (_) => _PaymentReviewDialog(payment: payment, invoice: invoice),
    );
    if (result == null || !mounted) return;
    try {
      if (result.action == _PaymentReviewAction.approve) {
        _store.approvePayment(payment, result.amount!);
        showLandlordMessage(
          context,
          'Đã xác nhận ${formatLandlordMoney(result.amount!)} cho hóa đơn ${invoice.id}.',
        );
      } else {
        _store.rejectPayment(payment, result.reason ?? '');
        showLandlordMessage(
          context,
          'Đã từ chối khoản thanh toán và lưu lý do.',
        );
      }
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  Future<void> _reject(LandlordPayment payment) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Không duyệt khoản thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${payment.tenantName} · phòng ${payment.room}'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Lý do không duyệt',
                  hintText: 'Nêu rõ thông tin người thuê cần bổ sung',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      dialogContext,
                      reasonController.text.trim(),
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
              ),
              child: const Text('Gửi lý do'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    try {
      _store.rejectPayment(payment, reason);
      showLandlordMessage(context, 'Đã gửi lý do không duyệt cho người thuê.');
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }
}

enum _PaymentReviewAction { approve, reject }

class _PaymentReviewResult {
  const _PaymentReviewResult.approve(this.amount)
    : action = _PaymentReviewAction.approve,
      reason = null;
  const _PaymentReviewResult.reject(this.reason)
    : action = _PaymentReviewAction.reject,
      amount = null;
  final _PaymentReviewAction action;
  final int? amount;
  final String? reason;
}

class _PaymentReviewDialog extends StatefulWidget {
  const _PaymentReviewDialog({required this.payment, required this.invoice});
  final LandlordPayment payment;
  final LandlordInvoice invoice;

  @override
  State<_PaymentReviewDialog> createState() => _PaymentReviewDialogState();
}

class _PaymentReviewDialogState extends State<_PaymentReviewDialog> {
  late final _amount = TextEditingController(
    text: widget.payment.reportedAmount.toString(),
  );
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LandlordFormDialog(
    title: 'Đối soát thanh toán',
    subtitle: 'Kiểm tra minh chứng trước khi xác nhận khoản thu.',
    icon: Icons.fact_check_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.payment.tenantName} · phòng ${widget.payment.room}',
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Hóa đơn ${widget.invoice.id} · tổng ${formatLandlordMoney(widget.invoice.total)}',
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 12,
          ),
        ),
        Text(
          'Đã xác nhận ${formatLandlordMoney(widget.invoice.paidAmount)} · còn nợ ${formatLandlordMoney(widget.invoice.remaining)}',
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 12,
          ),
        ),
        Divider(height: 22, color: LandlordPalette.of(context).line),
        _infoRow(
          'Số tiền người thuê báo',
          formatLandlordMoney(widget.payment.reportedAmount),
        ),
        const SizedBox(height: 8),
        _infoRow('Phương thức', widget.payment.method),
        const SizedBox(height: 8),
        _infoRow('Tham chiếu giao dịch', widget.payment.reference),
        if (widget.payment.proofBytes != null ||
            (widget.payment.proofUrl?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 12),
          Text(widget.payment.proofName ?? 'Minh chứng thanh toán'),
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: widget.payment.proofBytes != null
                ? Image.memory(
                    Uint8List.fromList(widget.payment.proofBytes!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('Không đọc được ảnh minh chứng.'),
                  )
                : Image.network(
                    widget.payment.proofUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('Không tải được ảnh minh chứng.'),
                  ),
          ),
        ],
        const SizedBox(height: 13),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          decoration: landlordModernInputDecoration(
            'Số tiền xác nhận (đ)',
            helperText:
                'Tối đa ${formatLandlordMoney(widget.invoice.remaining)} còn nợ',
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reason,
          maxLines: 2,
          decoration: landlordModernInputDecoration(
            'Lý do từ chối',
            hintText: 'Nhập nội dung để người thuê kiểm tra',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Xác nhận khoản tiền sẽ cập nhật số đã thu của hóa đơn ngay lập tức.',
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    ),
    footer: Wrap(
      alignment: WrapAlignment.end,
      spacing: 7,
      runSpacing: 7,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            if (_reason.text.trim().isEmpty) {
              showLandlordMessage(context, 'Nhập lý do trước khi từ chối.');
              return;
            }
            Navigator.pop(
              context,
              _PaymentReviewResult.reject(_reason.text.trim()),
            );
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD64545)),
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Không duyệt'),
        ),
        FilledButton.icon(
          onPressed: () {
            final value = int.tryParse(_amount.text.trim());
            if (value == null ||
                value <= 0 ||
                value > widget.payment.reportedAmount ||
                value > widget.invoice.remaining) {
              showLandlordMessage(context, 'Số tiền xác nhận không hợp lệ.');
              return;
            }
            Navigator.pop(context, _PaymentReviewResult.approve(value));
          },
          style: FilledButton.styleFrom(backgroundColor: landlordBlue),
          icon: const Icon(Icons.check_rounded, size: 17),
          label: const Text('Xác nhận'),
        ),
      ],
    ),
  );

  Widget _infoRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 155,
        child: Text(
          label,
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 11,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
