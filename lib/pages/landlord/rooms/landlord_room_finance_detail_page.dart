import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../layouts/landlord_navigation.dart';
import '../finance/landlord_finance_models.dart';
import '../finance/landlord_room_balance.dart';
import '../finance/landlord_room_balance_card.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import '../meter_readings/landlord_chisodiennuoc_page.dart';

class LandlordRoomFinanceDetailPage extends StatelessWidget {
  const LandlordRoomFinanceDetailPage({
    super.key,
    required this.store,
    required this.roomCode,
    required this.period,
    this.onCreateReceipt,
  });

  final LandlordDemoStore store;
  final String roomCode;
  final DateTime period;
  final Future<void> Function()? onCreateReceipt;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final balance = landlordRoomBalances(
        store,
        period,
      ).where((item) => item.details.room.code == roomCode).firstOrNull;
      if (balance == null) {
        return LandlordGlassPage(
          title: 'Chi tiết thu chi',
          subtitle: store.property.name,
          kicker: 'QUẢN LÝ TÀI CHÍNH',
          store: store,
          children: const [
            LandlordGlassCard(child: Text('Phòng không còn tồn tại.')),
          ],
        );
      }
      final details = balance.details;
      final lease = details.lease;
      final pending = balance.pendingPayment;
      final submitted = balance.latestReviewedPayment;
      final latestPayment = pending ?? submitted;
      final paymentInvoice = latestPayment == null
          ? null
          : store.invoiceById(latestPayment.invoiceId);
      final canRecordMeters = _canRecordMeters(balance, lease);

      return LandlordGlassPage(
        title: 'Chi tiết thu chi phòng $roomCode',
        subtitle: '${store.property.name} · Kỳ ${landlordMonth(period)}',
        kicker: 'QUẢN LÝ TÀI CHÍNH',
        store: store,
        children: [
          LandlordGlassSection(
            title: 'Phòng $roomCode',
            subtitle: details.typeName,
            trailing: IconButton.filledTonal(
              tooltip: 'Quay lại danh sách phòng',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          LandlordBluePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        lease?.tenantName ?? 'Lịch sử người thuê cũ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    LandlordStatusPill(
                      balance.label,
                      color: roomPaymentColor(balance.state),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  lease == null
                      ? 'Phòng hiện không có người thuê. Bạn có thể xem lại hóa đơn các kỳ trước.'
                      : 'Tầng ${details.room.floor} · Hạn đóng ngày ${lease.dueDay} · ${formatLandlordMoney(balance.remaining)} còn phải thu',
                  style: const TextStyle(
                    color: Color(0xFFDCEBFF),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (lease != null &&
              latestPayment != null &&
              paymentInvoice != null) ...[
            const SizedBox(height: 22),
            LandlordGlassSection(
              title: 'Phiếu thu đã lập',
              subtitle:
                  '${paymentInvoice.id} · ${landlordMonth(paymentInvoice.period)}',
            ),
            _PaymentSubmissionCard(
              payment: latestPayment,
              invoice: paymentInvoice,
              approved: submitted != null,
            ),
            const SizedBox(height: 12),
            if (pending != null)
              _pendingActions(context, pending, paymentInvoice, lease)
            else
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Đóng'),
                ),
              ),
          ],
          if (lease != null && balance.monthlyInvoices.isEmpty) ...[
            const SizedBox(height: 22),
            LandlordGlassCard(
              tint: const Color(0xFFD99412),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chưa lập phiếu thu',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Phòng ${details.room.code} chưa có phiếu thu cho kỳ ${landlordMonth(period)}.',
                    style: TextStyle(
                      color: LandlordPalette.of(context).muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      if (onCreateReceipt != null)
                        FilledButton.icon(
                          onPressed: () async => onCreateReceipt!.call(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Lập phiếu thu'),
                        ),
                      if (canRecordMeters)
                        OutlinedButton.icon(
                          onPressed: () => _openMeters(context),
                          icon: const Icon(Icons.bolt_outlined),
                          label: const Text('Ghi điện nước'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (canRecordMeters) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openMeters(context),
                icon: const Icon(Icons.bolt_outlined),
                label: const Text('Ghi điện nước kỳ này'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          LandlordGlassSection(
            title: 'Lịch sử hóa đơn',
            subtitle: '${balance.invoices.length} hóa đơn của phòng',
          ),
          if (balance.invoices.isEmpty)
            const LandlordGlassCard(
              child: Text('Chưa có hóa đơn ở kỳ này hoặc các kỳ trước.'),
            ),
          for (final invoice in balance.invoices)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _InvoiceHistoryCard(
                invoice: invoice,
                payments: store.payments
                    .where((payment) => payment.invoiceId == invoice.id)
                    .toList(),
              ),
            ),
        ],
      );
    },
  );

  bool _canRecordMeters(LandlordRoomBalance balance, LandlordLease? lease) {
    if (lease == null ||
        !lease.isCurrent ||
        balance.monthlyInvoices.isNotEmpty) {
      return false;
    }
    final now = DateTime.now();
    if (period.year != now.year || period.month != now.month) return false;
    return !now.isBefore(DateTime(now.year, now.month, lease.dueDay));
  }

  Widget _pendingActions(
    BuildContext context,
    LandlordPayment payment,
    LandlordInvoice invoice,
    LandlordLease? lease,
  ) => Wrap(
    spacing: 9,
    runSpacing: 9,
    children: [
      FilledButton.icon(
        onPressed: () => _approve(context, payment, invoice),
        icon: const Icon(Icons.verified_outlined),
        label: const Text('Duyệt'),
      ),
      OutlinedButton.icon(
        onPressed: () => _reject(context, payment),
        icon: const Icon(Icons.close_rounded),
        label: const Text('Không duyệt'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD64545),
        ),
      ),
      OutlinedButton.icon(
        onPressed: lease == null
            ? null
            : () => _contact(context, lease.phone, call: true),
        icon: const Icon(Icons.call_outlined),
        label: const Text('Gọi điện thoại'),
      ),
      OutlinedButton.icon(
        onPressed: lease == null
            ? null
            : () => _contact(context, lease.phone, call: false),
        icon: const Icon(Icons.sms_outlined),
        label: const Text('Nhắn tin'),
      ),
    ],
  );

  Future<void> _approve(
    BuildContext context,
    LandlordPayment payment,
    LandlordInvoice invoice,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duyệt phiếu thu?'),
        content: Text(
          'Xác nhận ${formatLandlordMoney(payment.reportedAmount)} cho phòng $roomCode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Duyệt phiếu'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    try {
      store.approvePayment(
        payment,
        payment.reportedAmount > invoice.remaining
            ? invoice.remaining
            : payment.reportedAmount,
      );
      showLandlordMessage(context, 'Đã duyệt phiếu thu ${payment.id}.');
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  Future<void> _reject(BuildContext context, LandlordPayment payment) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Không duyệt phiếu thu'),
          content: TextField(
            controller: reasonController,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setDialogState(() {}),
            decoration: const InputDecoration(
              labelText: 'Lý do không duyệt',
              hintText: 'Nhập lý do để người thuê biết cách nộp lại',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
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
    if (reason == null || !context.mounted) return;
    try {
      store.rejectPayment(payment, reason);
      showLandlordMessage(context, 'Đã gửi lý do không duyệt cho người thuê.');
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  Future<void> _contact(
    BuildContext context,
    String phone, {
    required bool call,
  }) async {
    final number = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri(scheme: call ? 'tel' : 'sms', path: number);
    try {
      if (!await launchUrl(uri) && context.mounted) {
        showLandlordMessage(context, 'Không mở được ứng dụng liên hệ.');
      }
    } catch (_) {
      if (context.mounted) {
        showLandlordMessage(context, 'Không mở được ứng dụng liên hệ.');
      }
    }
  }

  void _openMeters(BuildContext context) => LandlordNavigation.push<void>(
    context,
    destinationId: 'meter_readings',
    title: 'Ghi điện nước',
    page: LandlordChiSoDienNuocPage(store: store, initialRoom: roomCode),
  );
}

class _PaymentSubmissionCard extends StatelessWidget {
  const _PaymentSubmissionCard({
    required this.payment,
    required this.invoice,
    required this.approved,
  });
  final LandlordPayment payment;
  final LandlordInvoice invoice;
  final bool approved;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final color = approved ? const Color(0xFF16836F) : const Color(0xFFD99412);
    return LandlordGlassCard(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.id,
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              LandlordStatusPill(
                approved ? 'Đã nộp' : 'Đang chờ duyệt',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 13),
          _detailRow(context, 'Người thuê', payment.tenantName),
          _detailRow(
            context,
            'Số tiền đã nộp',
            formatLandlordMoney(payment.reportedAmount),
          ),
          _detailRow(
            context,
            'Thời gian',
            '${landlordDate(payment.paidAt)} ${payment.paidAt.hour.toString().padLeft(2, '0')}:${payment.paidAt.minute.toString().padLeft(2, '0')}',
          ),
          _detailRow(context, 'Phương thức', payment.method),
          _detailRow(context, 'Mã giao dịch', payment.reference),
          _detailRow(context, 'Phiếu thu', invoice.id),
          if (payment.proofName?.isNotEmpty ?? false) ...[
            const SizedBox(height: 9),
            Text(
              payment.proofName!,
              style: TextStyle(color: palette.muted, fontSize: 11),
            ),
          ],
          if (payment.proofBytes != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                Uint8List.fromList(payment.proofBytes!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _proofPlaceholder(context),
              ),
            ),
          ] else if (payment.proofUrl?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                payment.proofUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _proofPlaceholder(context),
              ),
            ),
          ] else if (payment.reference.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                'Mã giao dịch: ${payment.reference}',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _proofPlaceholder(BuildContext context) => Container(
    height: 140,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: LandlordPalette.of(context).surfaceAlt,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text('Không tải được hình ảnh minh chứng.'),
  );
}

class _InvoiceHistoryCard extends StatelessWidget {
  const _InvoiceHistoryCard({required this.invoice, required this.payments});
  final LandlordInvoice invoice;
  final List<LandlordPayment> payments;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final color = invoice.remaining == 0
        ? const Color(0xFF16836F)
        : invoice.status == LandlordInvoiceStatus.overdue
        ? const Color(0xFFD64545)
        : const Color(0xFFD99412);
    return LandlordGlassCard(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${landlordMonth(invoice.period)} · ${invoice.id}',
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invoice.tenantName,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              LandlordStatusPill(invoice.status.label, color: color),
            ],
          ),
          const Divider(height: 22),
          for (final charge in invoice.charges)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      charge.name,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ),
                  Text(
                    formatLandlordMoney(charge.amount),
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          _totalRow(context, 'Tổng phiếu thu', invoice.total, bold: true),
          const SizedBox(height: 6),
          _totalRow(context, 'Đã xác nhận', invoice.paidAmount),
          const SizedBox(height: 6),
          _totalRow(context, 'Còn phải thu', invoice.remaining, bold: true),
          if (payments.isNotEmpty) ...[
            const Divider(height: 22),
            Text(
              'Giao dịch thanh toán',
              style: TextStyle(
                color: palette.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final payment in payments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: roomPaymentColor(
                        payment.status == LandlordPaymentStatus.pending
                            ? RoomPaymentState.pendingReview
                            : RoomPaymentState.paid,
                      ),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${payment.id} · ${payment.reference}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 10),
                      ),
                    ),
                    Text(
                      formatLandlordMoney(
                        payment.approvedAmount ?? payment.reportedAmount,
                      ),
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(
    BuildContext context,
    String label,
    int amount, {
    bool bold = false,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: bold
                ? LandlordPalette.of(context).ink
                : LandlordPalette.of(context).muted,
            fontSize: 11,
            fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
      ),
      Text(
        formatLandlordMoney(amount),
        style: TextStyle(
          color: LandlordPalette.of(context).ink,
          fontSize: bold ? 13 : 11,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}
