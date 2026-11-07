import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import '../tenant_detail_ui.dart';
import '../tenant_inbox_hero.dart';
import '../../shared/announcements/announcement_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../../landlord/announcements/models/landlord_announcement.dart';
import '../invoices/tenant_invoice_detail_page.dart';
import 'components/tenant_announcement_card.dart';
import 'models/tenant_announcement.dart';

class TenantAnnouncementsPage extends StatefulWidget {
  const TenantAnnouncementsPage({
    super.key,
    this.store,
    String? tenantId,
    this.showHeader = false,
  }) : _tenantId = tenantId ?? '';
  final AnnouncementStore? store;
  final String _tenantId;
  String get tenantId =>
      _tenantId.isEmpty ? TenantSession.currentTenantId : _tenantId;
  final bool showHeader;

  @override
  State<TenantAnnouncementsPage> createState() =>
      _TenantAnnouncementsPageState();
}

class _TenantAnnouncementsPageState extends State<TenantAnnouncementsPage> {
  AnnouncementStore get _store => widget.store ?? AnnouncementStore.instance;
  bool _isRead(String id) => _store.isRead(id, widget.tenantId);
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

  bool _unreadOnly = false;

  void _open(TenantAnnouncement item) {
    _store.markTenantRead(item.id, widget.tenantId);
    if (item.id.startsWith('payment-rejected:')) {
      final paymentId = item.id.substring('payment-rejected:'.length);
      for (final payment in _store.rental.paymentsForTenant(widget.tenantId)) {
        if (payment.id != paymentId) continue;
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => TenantInvoiceDetailPage(
              invoiceId: payment.invoiceId,
              store: _store.rental,
              tenantId: widget.tenantId,
            ),
          ),
        );
        return;
      }
    }
    showDialog<void>(
      context: context,
      builder: (context) => TenantDetailTheme(
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            item.title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TenantDetailIcon(
                    tenantAnnouncementIcon(item.category),
                    size: 46,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TenantStatusPill(item.category, color: tenantGreen),
                      if (item.isImportant)
                        const TenantStatusPill(
                          'Quan trọng',
                          color: Color(0xFFD64545),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chủ trọ · ${_store.rental.property.ownerName}',
                    style: const TextStyle(
                      color: tenantInk,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.recipient}\n${formatTenantAnnouncementDate(item.publishedAt)}',
                    style: const TextStyle(
                      color: tenantMuted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const Divider(height: 28),
                  SelectableText(
                    item.content,
                    style: const TextStyle(
                      color: tenantInk,
                      fontSize: 14,
                      height: 1.65,
                    ),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _store
        .forTenant(widget.tenantId)
        .map(
          (item) => TenantAnnouncement(
            id: item.id,
            title: item.title,
            content: item.content,
            category: item.category.label,
            recipient:
                item.audienceLabel ?? 'Phòng ${item.recipients.join(', ')}',
            publishedAt: item.createdAt,
            isImportant: item.priority != AnnouncementPriority.normal,
          ),
        )
        .toList();
    final unreadCount = all.where((item) => !_isRead(item.id)).length;
    final items =
        all.where((item) => !_unreadOnly || !_isRead(item.id)).toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return TenantInboxPageFrame(
      imageAsset: 'assets/images/tenant_announcements_hero.png',
      title: 'Thông báo',
      subtitle: 'Thông tin từ chủ trọ dành cho ${_store.rental.property.name}.',
      showHeader: widget.showHeader,
      children: [
        TenantSurface(
          child: Row(
            children: [
              const TenantDetailIcon(
                Icons.mark_email_unread_outlined,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$unreadCount thông báo chưa đọc',
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unreadCount == 0
                          ? 'Bạn đã cập nhật tất cả thông tin.'
                          : 'Xem cập nhật mới nhất từ chủ trọ.',
                      style: const TextStyle(
                        color: tenantMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filter(
              'Tất cả',
              !_unreadOnly,
              () => setState(() => _unreadOnly = false),
            ),
            _filter(
              'Chưa đọc ($unreadCount)',
              _unreadOnly,
              () => setState(() => _unreadOnly = true),
            ),
          ],
        ),
        const SizedBox(height: 22),
        TenantSectionHeading(
          'Thông báo mới nhất',
          trailing: Text(
            '${items.length} thông báo',
            style: const TextStyle(color: tenantMuted, fontSize: 11),
          ),
        ),
        if (all.isEmpty)
          const TenantEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Chưa có thông báo',
            subtitle: 'Thông tin từ chủ trọ sẽ xuất hiện tại đây.',
          )
        else if (items.isEmpty)
          const TenantEmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'Bạn đã đọc hết thông báo',
            subtitle: 'Các thông báo đã đọc vẫn nằm trong mục Tất cả.',
          ),
        for (final item in items)
          TenantAnnouncementCard(
            key: ValueKey(item.id),
            announcement: item,
            isRead: _isRead(item.id),
            onTap: () => _open(item),
          ),
      ],
    );
  }

  Widget _filter(String label, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    selectedColor: const Color(0xFFE3F5E9),
    backgroundColor: Colors.white,
    side: BorderSide(color: selected ? const Color(0xFFC3E8CF) : tenantLine),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    labelStyle: TextStyle(
      color: selected ? tenantGreenDark : tenantMuted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );
}
