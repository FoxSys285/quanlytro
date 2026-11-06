import 'dart:async';

import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../landlord_theme.dart';

import '../landlord_demo_store.dart';
import '../landlord_glass.dart';

import 'components/landlord_announcement_card.dart';
import 'components/landlord_announcement_composer.dart';
import 'data/landlord_announcement_demo_data.dart';
import 'models/landlord_announcement.dart';
import '../../shared/announcements/announcement_store.dart';

class LandlordAnnouncementsPage extends StatefulWidget {
  const LandlordAnnouncementsPage({
    super.key,
    this.store,
    this.showHeader = false,
    this.dark = false,
    this.onToggleTheme,
  });
  final AnnouncementStore? store;
  final bool showHeader;
  final bool dark;
  final VoidCallback? onToggleTheme;

  @override
  State<LandlordAnnouncementsPage> createState() =>
      _LandlordAnnouncementsPageState();
}

class _LandlordAnnouncementsPageState extends State<LandlordAnnouncementsPage> {
  AnnouncementStore get _store =>
      widget.store ??
      AnnouncementStore.forRental(LandlordDemoStore.activeInstance);
  List<LandlordAnnouncement> get _inbox => _store.inbox;
  List<LandlordAnnouncement> get _sent => _store.sent;
  Timer? _timer;
  String _query = '';
  String _readFilter = 'all';
  AnnouncementCategory? _category;
  bool _showSent = false;
  bool _urgentOnly = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  String _propertyName(String? id) => id == null
      ? 'Toàn hệ thống'
      : LandlordAnnouncementDemoData.properties
            .firstWhere((p) => p.id == id)
            .name;

  Future<void> _compose() async {
    final result = await showDialog<LandlordAnnouncement>(
      context: context,
      builder: (_) => LandlordAnnouncementComposer(
        properties: LandlordAnnouncementDemoData.properties,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _store.send(result);
      _showSent = true;
      _query = '';
      _search.clear();
      _readFilter = 'all';
      _category = null;
      _urgentOnly = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi thông báo đến người thuê.')),
    );
  }

  final _search = TextEditingController();

  void _open(LandlordAnnouncement item) {
    if (!_showSent && !item.isRead) {
      _store.markLandlordRead(item.id);
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_propertyName(item.propertyId)} · ${item.category.label}',
                ),
                const SizedBox(height: 8),
                Text(announcementTimeLabel(item.createdAt, DateTime.now())),
                if (item.priority != AnnouncementPriority.normal) ...[
                  const SizedBox(height: 8),
                  Text(item.priority.label),
                ],
                const Divider(height: 28),
                SelectableText(
                  item.content,
                  style: const TextStyle(height: 1.6),
                ),
                if (item.recipients.isNotEmpty) ...[
                  const Divider(height: 28),
                  Text('Đối tượng: ${item.audienceLabel}'),
                  Text('Phòng ${item.recipients.join(', ')}'),
                  const SizedBox(height: 8),
                ],
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

  void _goTo(LandlordAnnouncement item) {
    if (!item.isRead) _store.markLandlordRead(item.id);
    final destination = switch (item.category) {
      AnnouncementCategory.finance => 'billing',
      AnnouncementCategory.incident => 'incidents',
      AnnouncementCategory.viewing => 'viewings',
      AnnouncementCategory.lease => 'leases',
      _ => null,
    };
    if (destination == null ||
        !RoleLayoutShell.tryNavigateTo(context, destination)) {
      _open(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final palette = LandlordPalette.of(context);
    final inbox = _inbox;
    final sent = _sent;
    final unread = inbox.where((item) => !item.isRead).length;
    final attention = inbox
        .where(
          (item) =>
              !item.isRead && item.priority != AnnouncementPriority.normal,
        )
        .length;
    final query = _query.trim().toLowerCase();
    final items = (_showSent ? sent : inbox).where((item) {
      final text =
          '${item.title} ${item.content} ${_propertyName(item.propertyId)}';
      return text.toLowerCase().contains(query) &&
          (_category == null || item.category == _category) &&
          (_showSent ||
              _readFilter == 'all' ||
              (_readFilter == 'unread' ? !item.isRead : item.isRead)) &&
          (!_urgentOnly || item.priority == AnnouncementPriority.urgent);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return LandlordFeaturePage(
      title: 'Thông báo',
      subtitle: 'Gửi thông tin vận hành và theo dõi phản hồi của người thuê.',
      icon: Icons.campaign_outlined,
      kicker: 'THÔNG BÁO CƯ DÂN',
      children: [
        LandlordGlassSection(
          title: 'Hộp thư',
          subtitle: '$unread chưa đọc · $attention thông báo cần chú ý.',
        ),
        _AnnouncementSummary(
          unread: unread,
          attention: attention,
          onCompose: _compose,
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: [
              Expanded(
                child: _InboxTab(
                  label: 'Nhận được',
                  count: inbox.length,
                  selected: !_showSent,
                  onTap: () => setState(() => _showSent = false),
                ),
              ),
              Expanded(
                child: _InboxTab(
                  label: 'Đã gửi',
                  count: sent.length,
                  selected: _showSent,
                  onTap: () => setState(() => _showSent = true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        TextField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          decoration: landlordModernInputDecoration(
            'Tìm thông báo',
            hintText: 'Tìm theo phòng, tên khách, nội dung...',
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<AnnouncementCategory>(
          key: ValueKey('category:$_category'),
          initialValue: _category,
          isExpanded: true,
          decoration: landlordModernInputDecoration('Phân loại sự vụ'),
          items: [
            const DropdownMenuItem(child: Text('Tất cả nội dung')),
            for (final category in AnnouncementCategory.values)
              DropdownMenuItem(value: category, child: Text(category.label)),
          ],
          onChanged: (value) => setState(() => _category = value),
        ),
        if (!_showSent) ...[
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _filterChip('Tất cả', _readFilter == 'all' && !_urgentOnly, () {
                setState(() {
                  _readFilter = 'all';
                  _urgentOnly = false;
                });
              }),
              _filterChip(
                'Chưa đọc',
                _readFilter == 'unread' && !_urgentOnly,
                () {
                  setState(() {
                    _readFilter = 'unread';
                    _urgentOnly = false;
                  });
                },
              ),
              _filterChip('Khẩn cấp', _urgentOnly, () {
                setState(() {
                  _readFilter = 'all';
                  _urgentOnly = true;
                });
              }),
              _filterChip('Đã đọc', _readFilter == 'read' && !_urgentOnly, () {
                setState(() {
                  _readFilter = 'read';
                  _urgentOnly = false;
                });
              }),
            ],
          ),
        ],
        const SizedBox(height: 12),
        LandlordGlassSection(
          title: _showSent ? 'Thông báo đã gửi' : 'Thông báo nhận được',
          subtitle: '${items.length} thông báo',
          trailing: !_showSent
              ? TextButton.icon(
                  onPressed: unread == 0 ? null : _store.markAllLandlordRead,
                  icon: const Icon(Icons.done_all_rounded, size: 17),
                  label: const Text('Đánh dấu đã đọc'),
                )
              : null,
        ),
        if (items.isEmpty)
          const LandlordGlassCard(
            child: Center(child: Text('Không có thông báo phù hợp.')),
          ),
        for (final item in items)
          LandlordAnnouncementCard(
            key: ValueKey(item.id),
            announcement: item,
            propertyName: _propertyName(item.propertyId),
            now: now,
            isSent: _showSent,
            onTap: () => _open(item),
            onAction: _showSent ? null : () => _goTo(item),
          ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: propertyBlue,
        backgroundColor: LandlordPalette.of(context).surface,
        side: BorderSide(color: selected ? Colors.transparent : Colors.white),
        labelStyle: TextStyle(
          color: selected ? Colors.white : propertyBlue,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        onSelected: (_) => onTap(),
      );
}

class _InboxTab extends StatelessWidget {
  const _InboxTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Material(
      color: selected ? palette.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 13, color: palette.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? palette.primary : palette.muted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(color: palette.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementSummary extends StatelessWidget {
  const _AnnouncementSummary({
    required this.unread,
    required this.attention,
    required this.onCompose,
  });
  final int unread;
  final int attention;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF438EFF), propertyBlue],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30366BDA),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tổng quan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .3)),
              ),
              child: const Text(
                'Hộp thư',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                'Chưa đọc',
                unread,
                Icons.mark_email_unread_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryTile(
                'Cần chú ý',
                attention,
                Icons.priority_high_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCompose,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: propertyBlue,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo thông báo'),
          ),
        ),
      ],
    ),
  );

  Widget _summaryTile(String label, int value, IconData icon) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(height: 7),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEAF1FF),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
