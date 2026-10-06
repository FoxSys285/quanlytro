import 'package:flutter/material.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_ui.dart';

class LandlordPaymentsPage extends StatefulWidget {
  const LandlordPaymentsPage({super.key});

  @override
  State<LandlordPaymentsPage> createState() => _LandlordPaymentsPageState();
}

class _LandlordPaymentsPageState extends State<LandlordPaymentsPage> {
  final _store = LandlordDemoStore.instance;
  String _filter = 'Chờ duyệt';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final pending = _store.payments
          .where((payment) => payment.status == LandlordPaymentStatus.pending)
          .length;
      final payments = _store.payments.where((payment) {
        if (_filter == 'Chờ duyệt')
          return payment.status == LandlordPaymentStatus.pending;
        if (_filter == 'Đã xác nhận')
          return payment.status == LandlordPaymentStatus.approved;
        if (_filter == 'Từ chối')
          return payment.status == LandlordPaymentStatus.rejected;
        return true;
      }).toList()..sort((a, b) => b.paidAt.compareTo(a.paidAt));
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Duyệt thanh toán',
            subtitle: '$pending khoản đang chờ đối soát',
          ),
          if (pending > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                border: Border.all(color: const Color(0xFFF2E4BF)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFB17A23)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đối chiếu mã giao dịch và số tiền với tài khoản nhận trước khi xác nhận.',
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
          if (payments.isEmpty)
            const LandlordEmptyState(
              message: 'Không có khoản thanh toán nào trong danh sách này.',
            ),
          for (final payment in payments) _paymentCard(payment),
          const SizedBox(height: 4),
          const Text(
            'Bản xem trước chưa kết nối ngân hàng. Thao tác xác nhận chỉ cập nhật dữ liệu mẫu.',
            style: TextStyle(color: landlordMuted, fontSize: 11),
          ),
        ],
      );
    },
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
    return LandlordCard(
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
                      style: const TextStyle(
                        color: landlordInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${payment.id} · ${landlordDate(payment.paidAt)} ${payment.paidAt.hour.toString().padLeft(2, '0')}:${payment.paidAt.minute.toString().padLeft(2, '0')}',
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
              const Expanded(
                child: Text(
                  'Người thuê báo đã trả',
                  style: TextStyle(color: landlordMuted, fontSize: 12),
                ),
              ),
              Text(
                formatLandlordMoney(payment.reportedAmount),
                style: const TextStyle(
                  color: landlordInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Hóa đơn ${payment.invoiceId} · còn nợ ${formatLandlordMoney(invoice?.remaining ?? 0)}',
            style: const TextStyle(color: landlordMuted, fontSize: 11),
          ),
          const SizedBox(height: 7),
          Text(
            'Mã giao dịch: ${payment.reference}',
            style: const TextStyle(color: landlordMuted, fontSize: 11),
          ),
          if (payment.status == LandlordPaymentStatus.approved &&
              payment.approvedAmount != payment.reportedAmount) ...[
            const SizedBox(height: 7),
            Text(
              'Đã ghi nhận ${formatLandlordMoney(amount)}',
              style: const TextStyle(
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
              style: const TextStyle(color: Color(0xFFD64545), fontSize: 11),
            ),
          ],
          if (payment.status == LandlordPaymentStatus.pending) ...[
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _review(payment),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Kiểm tra và xử lý'),
              ),
            ),
          ],
        ],
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
              child: const Text('Đóng'),
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đối soát thanh toán'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.payment.tenantName} · phòng ${widget.payment.room}',
              style: const TextStyle(
                color: landlordInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Hóa đơn ${widget.invoice.id} · tổng ${formatLandlordMoney(widget.invoice.total)}',
              style: const TextStyle(color: landlordMuted, fontSize: 12),
            ),
            Text(
              'Đã xác nhận ${formatLandlordMoney(widget.invoice.paidAmount)} · còn nợ ${formatLandlordMoney(widget.invoice.remaining)}',
              style: const TextStyle(color: landlordMuted, fontSize: 12),
            ),
            const Divider(height: 22),
            _infoRow(
              'Số tiền người thuê báo',
              formatLandlordMoney(widget.payment.reportedAmount),
            ),
            const SizedBox(height: 8),
            _infoRow('Phương thức', widget.payment.method),
            const SizedBox(height: 8),
            _infoRow('Tham chiếu giao dịch', widget.payment.reference),
            const SizedBox(height: 13),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền xác nhận (đ)',
                helperText:
                    'Tối đa ${formatLandlordMoney(widget.invoice.remaining)} còn nợ',
              ),
            ),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối',
                hintText: 'Nhập nội dung để người thuê kiểm tra',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xác nhận khoản tiền sẽ cập nhật số đã thu của hóa đơn ngay lập tức.',
              style: TextStyle(color: landlordMuted, fontSize: 10, height: 1.4),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      TextButton(
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
        child: const Text('Từ chối'),
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
        icon: const Icon(Icons.check_rounded, size: 17),
        label: const Text('Xác nhận'),
      ),
    ],
  );

  Widget _infoRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 155,
        child: Text(
          label,
          style: const TextStyle(color: landlordMuted, fontSize: 11),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: landlordInk,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
