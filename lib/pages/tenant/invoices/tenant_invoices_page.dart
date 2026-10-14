import 'package:flutter/material.dart';

import '../../landlord/landlord_demo_store.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../shared/rental/tenant_session.dart';

import '../tenant_ui.dart';
import 'components/tenant_invoice_card.dart';
import 'tenant_invoice_detail_page.dart';

class TenantInvoicesPage extends StatefulWidget {
  const TenantInvoicesPage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final LandlordDemoStore? store;
  final String tenantId;

  @override
  State<TenantInvoicesPage> createState() => _TenantInvoicesPageState();
}

class _TenantInvoicesPageState extends State<TenantInvoicesPage> {
  String _view = 'Cần thanh toán';

  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = _view == 'Lịch sử thanh toán';
    final invoices = _store.invoicesForTenant(widget.tenantId);
    final payments = _store.paymentsForTenant(widget.tenantId);
    final visibleInvoices =
        invoices
            .where(
              (invoice) => history
                  ? invoice.paidAmount > 0 || invoice.cancelled
                  : !invoice.cancelled && invoice.remaining > 0,
            )
            .toList()
          ..sort(
            (a, b) => history
                ? b.period.compareTo(a.period)
                : a.dueDate.compareTo(b.dueDate),
          );
    final outstanding = invoices
        .where((invoice) => !invoice.cancelled)
        .fold<int>(0, (sum, invoice) => sum + invoice.remaining);
    final paidTotal = invoices
        .where((invoice) => !invoice.cancelled)
        .fold<int>(0, (sum, invoice) => sum + invoice.paidAmount);

    return TenantPageFrame(
      children: [
        const TenantPageTitle(
          title: 'Hóa đơn',
          subtitle: 'Theo dõi khoản cần trả và các giao dịch đã hoàn tất.',
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: history
                  ? const [Color(0xFF167B69), Color(0xFF279780)]
                  : const [Color(0xFF9B6721), Color(0xFFC08A35)],
            ),
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: (history ? tenantGreen : const Color(0xFFB17A23))
                    .withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  history
                      ? Icons.verified_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history ? 'Đã thanh toán' : 'Còn cần thanh toán',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatTenantMoney(history ? paidTotal : outstanding),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${visibleInvoices.length} khoản',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0EE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _viewTab('Cần thanh toán', Icons.receipt_long_outlined),
              _viewTab('Lịch sử thanh toán', Icons.history_rounded),
            ],
          ),
        ),
        const SizedBox(height: 17),
        TenantSectionHeading(
          history ? 'Giao dịch đã ghi nhận' : 'Hóa đơn cần xử lý',
          trailing: Text(
            history ? 'Mới nhất trước' : 'Đến hạn trước',
            style: const TextStyle(color: tenantMuted, fontSize: 11),
          ),
        ),
        if (visibleInvoices.isEmpty && (!history || payments.isEmpty))
          TenantEmptyState(
            icon: history
                ? Icons.receipt_long_outlined
                : Icons.check_circle_outline_rounded,
            title: history
                ? 'Chưa có giao dịch thanh toán'
                : 'Bạn không còn hóa đơn cần trả',
            subtitle: history
                ? 'Các khoản đã thanh toán sẽ xuất hiện ở đây.'
                : 'Khi có hóa đơn mới, thông tin sẽ được cập nhật tại đây.',
          ),
        for (final invoice in visibleInvoices) ...[
          TenantInvoiceCard(
            month: landlordMonth(invoice.period),
            invoiceId: invoice.id,
            amount: history
                ? (invoice.cancelled ? invoice.total : invoice.paidAmount)
                : invoice.remaining,
            date: landlordDate(invoice.dueDate),
            paid: invoice.status == LandlordInvoiceStatus.paid,
            statusLabel: invoice.status.label,
            onTap: () => _showInvoiceDetails(context, invoice: invoice),
          ),
          const SizedBox(height: 11),
        ],
        if (history) ...[
          const TenantSectionHeading('Các lần gửi thanh toán'),
          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: TenantSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${payment.invoiceId} · ${formatTenantMoney(payment.reportedAmount)}',
                    ),
                    Text(
                      '${payment.method} · ${payment.reference} · ${landlordDate(payment.paidAt)}',
                    ),
                    Text(switch (payment.status) {
                      LandlordPaymentStatus.pending => 'Chờ chủ trọ duyệt',
                      LandlordPaymentStatus.approved =>
                        'Đã xác nhận ${formatTenantMoney(payment.approvedAmount ?? 0)}',
                      LandlordPaymentStatus.rejected =>
                        'Từ chối: ${payment.rejectionReason}',
                    }),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _viewTab(String label, IconData icon) {
    final selected = _view == label;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => setState(() => _view = label),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? tenantGreenDark : tenantMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? tenantInk : tenantMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInvoiceDetails(
    BuildContext context, {
    required LandlordInvoice invoice,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TenantInvoiceDetailPage(
          invoiceId: invoice.id,
          store: _store,
          tenantId: widget.tenantId,
        ),
      ),
    );
  }
}
