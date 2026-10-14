import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import '../../shared/announcements/announcement_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../../landlord/announcements/models/landlord_announcement.dart';
import 'components/tenant_announcement_card.dart';
import 'models/tenant_announcement.dart';

class TenantAnnouncementsPage extends StatefulWidget {
  const TenantAnnouncementsPage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final AnnouncementStore? store;
  final String tenantId;

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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
                  style: TextStyle(
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
    return TenantPageFrame(
      children: [
        TenantPageTitle(
          title: 'Thông báo nhà trọ',
          subtitle:
              'Thông tin từ chủ trọ dành cho ${_store.rental.property.name}.',
        ),
        TenantSurface(
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined, color: tenantGreen, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _store.rental.property.name,
                      style: TextStyle(
                        color: tenantInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unreadCount thông báo chưa đọc',
                      style: const TextStyle(color: tenantMuted, fontSize: 12),
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
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: !_unreadOnly,
              onSelected: (_) => setState(() => _unreadOnly = false),
            ),
            ChoiceChip(
              label: Text('Chưa đọc ($unreadCount)'),
              selected: _unreadOnly,
              onSelected: (_) => setState(() => _unreadOnly = true),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
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
}
