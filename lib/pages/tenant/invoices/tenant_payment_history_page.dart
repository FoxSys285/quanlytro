import 'package:flutter/material.dart';

import '../../landlord/finance/landlord_finance_models.dart';
import '../../landlord/landlord_demo_store.dart';
import '../tenant_detail_ui.dart';
import '../tenant_ui.dart';
import 'components/tenant_invoice_card.dart';
import 'components/tenant_invoice_dashboard_widgets.dart';
import 'tenant_invoice_detail_page.dart';

class TenantPaymentHistoryPage extends StatefulWidget {
  const TenantPaymentHistoryPage({
    super.key,
    required this.store,
    required this.tenantId,
  });
  final LandlordDemoStore store;
  final String tenantId;
  @override
  State<TenantPaymentHistoryPage> createState() =>
      _TenantPaymentHistoryPageState();
}

class _TenantPaymentHistoryPageState extends State<TenantPaymentHistoryPage> {
  bool _allInvoices = false;
  @override
  Widget build(BuildContext context) => TenantSubpageScaffold(
    title: 'Lịch sử thanh toán',
    child: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final invoices =
            widget.store.invoicesForTenant(widget.tenantId).toList()
              ..sort((a, b) => b.period.compareTo(a.period));
        final transactions = tenantInvoiceTransactions(
          invoices,
          widget.store.paymentsForTenant(widget.tenantId),
        );
        return TenantDetailFrame(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Giao dịch'),
                  selected: !_allInvoices,
                  onSelected: (_) => setState(() => _allInvoices = false),
                ),
                ChoiceChip(
                  label: const Text('Tất cả hóa đơn'),
                  selected: _allInvoices,
                  onSelected: (_) => setState(() => _allInvoices = true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_allInvoices) ...[
              if (transactions.isEmpty)
                const TenantEmptyState(
                  icon: Icons.history_rounded,
                  title: 'Chưa có giao dịch thanh toán',
                  subtitle:
                      'Các giao dịch sẽ xuất hiện khi bạn gửi thanh toán.',
                ),
              for (final transaction in transactions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: TenantInvoiceTransactionTile(
                    transaction: transaction,
                    onTap: () => _openInvoice(transaction.invoiceId),
                  ),
                ),
            ] else ...[
              if (invoices.isEmpty)
                const TenantEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Chưa có hóa đơn',
                  subtitle: 'Hóa đơn sẽ xuất hiện khi chủ trọ phát hành.',
                ),
              for (final invoice in invoices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TenantInvoiceCard(
                    month: landlordMonth(invoice.period),
                    invoiceId: invoice.id,
                    amount: invoice.total,
                    date: landlordDate(invoice.dueDate),
                    paid: invoice.status == LandlordInvoiceStatus.paid,
                    statusLabel: invoice.status.label,
                    onTap: () => _openInvoice(invoice.id),
                  ),
                ),
            ],
          ],
        );
      },
    ),
  );

  void _openInvoice(String id) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TenantInvoiceDetailPage(
        invoiceId: id,
        store: widget.store,
        tenantId: widget.tenantId,
      ),
    ),
  );
}
