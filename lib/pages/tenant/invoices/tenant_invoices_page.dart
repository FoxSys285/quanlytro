import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/finance/landlord_finance_models.dart';
import '../../shared/help/help_page.dart';
import '../../shared/payments/vietqr_service.dart';
import '../../shared/rental/tenant_session.dart';
import '../tenant_ui.dart';
import '../tenant_detail_ui.dart';
import 'components/tenant_invoice_dashboard_widgets.dart';
import 'components/tenant_payment_instructions_sheet.dart';
import 'components/tenant_payment_methods_sheet.dart';
import 'tenant_invoice_detail_page.dart';
import 'tenant_payment_history_page.dart';

class TenantInvoicesPage extends StatefulWidget {
  const TenantInvoicesPage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
    this.qrService,
  });
  final LandlordDemoStore? store;
  final String tenantId;
  final VietQrService? qrService;

  @override
  State<TenantInvoicesPage> createState() => _TenantInvoicesPageState();
}

class _TenantInvoicesPageState extends State<TenantInvoicesPage> {
  String? _selectedInvoiceId;
  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final invoices = _store.invoicesForTenant(widget.tenantId);
      final payments = _store.paymentsForTenant(widget.tenantId);
      final outstanding =
          invoices
              .where((invoice) => !invoice.cancelled && invoice.remaining > 0)
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final selected = outstanding.where(
        (invoice) => invoice.id == _selectedInvoiceId,
      );
      final current = selected.isNotEmpty
          ? selected.first
          : outstanding.firstOrNull;
      final pending =
          current != null &&
          payments.any(
            (payment) =>
                payment.invoiceId == current.id &&
                payment.status == LandlordPaymentStatus.pending,
          );
      final transactions = tenantInvoiceTransactions(invoices, payments);

      return TenantDetailTheme(
        child: TenantPageFrame(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [invoiceMint, Colors.white, Colors.white],
                  stops: [0, 0.47, 1],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TenantInvoiceHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 0, 13, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (current != null)
                          TenantCurrentInvoiceCard(
                            invoice: current,
                            store: _store,
                            pending: pending,
                            onPay: () => showTenantPaymentInstructions(
                              context,
                              invoiceId: current.id,
                              store: _store,
                              tenantId: widget.tenantId,
                            ),
                          )
                        else
                          TenantSurface(
                            child: TenantEmptyState(
                              icon: invoices.isEmpty
                                  ? Icons.receipt_long_outlined
                                  : Icons.check_circle_outline_rounded,
                              title: invoices.isEmpty
                                  ? 'Chưa có hóa đơn'
                                  : 'Bạn không còn hóa đơn cần trả',
                              subtitle: 'Hóa đơn mới sẽ xuất hiện khi chủ trọ phát hành.',
                            ),
                          ),
                        if (outstanding.length > 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _chooseInvoice(outstanding),
                              icon: const Icon(
                                Icons.swap_horiz_rounded,
                                size: 17,
                              ),
                              label: Text(
                                'Còn ${outstanding.length} hóa đơn cần thanh toán',
                              ),
                            ),
                          ),
                        const SizedBox(height: 13),
                        TenantInvoiceQuickActions(
                          onDetails: current == null
                              ? null
                              : () => _openInvoice(current.id),
                          onMethods: () => showTenantPaymentMethods(
                            context,
                            store: _store,
                            tenantId: widget.tenantId,
                            invoiceId: current?.id,
                            qrService: widget.qrService,
                          ),
                          onHistory: _openHistory,
                          onSupport: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const TenantSubpageScaffold(
                                title: 'Hỗ trợ thanh toán',
                                child: HelpPage(role: AppRole.tenant),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: Color(0xFF008E45),
                              size: 25,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Lịch sử giao dịch',
                                style: TextStyle(
                                  color: tenantInk,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _openHistory,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Xem tất cả',
                                    style: TextStyle(
                                      color: Color(0xFF009D44),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFF009D44),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (transactions.isEmpty)
                          const TenantSurface(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    color: tenantGreenDark,
                                    size: 29,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Chưa có giao dịch thanh toán',
                                    style: TextStyle(
                                      color: tenantInk,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Các giao dịch của bạn sẽ được cập nhật tại đây.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: tenantMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final transaction in transactions.take(3))
                            TenantInvoiceTransactionTile(
                              transaction: transaction,
                              onTap: () => _openInvoice(transaction.invoiceId),
                            ),
                        const SizedBox(height: 13),
                        const TenantInvoiceSecurityBanner(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  void _openInvoice(String id) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TenantInvoiceDetailPage(
        invoiceId: id,
        store: _store,
        tenantId: widget.tenantId,
      ),
    ),
  );

  void _openHistory() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          TenantPaymentHistoryPage(store: _store, tenantId: widget.tenantId),
    ),
  );

  void _chooseInvoice(List<LandlordInvoice> invoices) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TenantDetailTheme(
        child: TenantBottomSheetSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TenantSheetHandle(),
              const Text(
                'Chọn hóa đơn thanh toán',
                style: TextStyle(
                  color: tenantInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final invoice in invoices)
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.receipt_long_rounded,
                      color: tenantGreenDark,
                    ),
                    title: Text(
                      landlordMonth(invoice.period),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Phòng ${invoice.room} • Hạn ${landlordDate(invoice.dueDate)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      formatTenantMoney(invoice.remaining),
                      style: const TextStyle(
                        color: tenantGreenDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedInvoiceId = invoice.id);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
