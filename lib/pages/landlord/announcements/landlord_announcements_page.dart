import 'dart:async';

import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../landlord_compact_header.dart';
import '../landlord_theme.dart';

import '../landlord_demo_store.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) ...[
                LandlordCompactHeader(
                  store: LandlordDemoStore.activeInstance,
                  dark: widget.dark,
                  onToggleTheme: widget.onToggleTheme,
                  onNotifications: () => setState(() {
                    _showSent = false;
                    _readFilter = 'all';
                    _urgentOnly = false;
                    _category = null;
                    _query = '';
                    _search.clear();
                  }),
                ),
                const SizedBox(height: 12),
              ],
              _AnnouncementHero(
                unread: unread,
                attention: attention,
                onCompose: _compose,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
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
                decoration: InputDecoration(
                  hintText: 'Tìm theo phòng, tên khách, nội dung...',
                  hintStyle: TextStyle(color: palette.muted, fontSize: 12),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: palette.muted,
                  ),
                  suffixIcon: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: palette.muted,
                  ),
                  filled: true,
                  fillColor: palette.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(color: palette.line),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              DropdownButtonFormField<AnnouncementCategory>(
                key: ValueKey('category:$_category'),
                initialValue: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Phân loại sự vụ',
                  labelStyle: TextStyle(color: palette.muted, fontSize: 11),
                  filled: true,
                  fillColor: palette.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem(child: Text('Tất cả nội dung')),
                  for (final category in AnnouncementCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: (value) => setState(() => _category = value),
              ),
              if (!_showSent) ...[
                const SizedBox(height: 11),
                SizedBox(
                  height: 39,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _readFilter == 'all' && !_urgentOnly,
                        onSelected: (_) => setState(() {
                          _readFilter = 'all';
                          _urgentOnly = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Chưa đọc'),
                        selected: _readFilter == 'unread' && !_urgentOnly,
                        onSelected: (_) => setState(() {
                          _readFilter = 'unread';
                          _urgentOnly = false;
                        }),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Khẩn cấp'),
                        selected: _urgentOnly,
                        onSelected: (_) => setState(() {
                          _readFilter = 'all';
                          _urgentOnly = true;
                        }),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Đã đọc'),
                        selected: _readFilter == 'read' && !_urgentOnly,
                        onSelected: (_) => setState(() {
                          _readFilter = 'read';
                          _urgentOnly = false;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _showSent
                          ? 'Thông báo đã gửi (${items.length})'
                          : 'Danh sách thông báo (${items.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!_showSent)
                    TextButton.icon(
                      onPressed: unread == 0
                          ? null
                          : _store.markAllLandlordRead,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                      ),
                      label: const Text(
                        'Đánh dấu tất cả đã đọc',
                        style: TextStyle(fontSize: 10),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
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
          ),
        ),
      ),
    );
  }
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

class _AnnouncementHero extends StatelessWidget {
  const _AnnouncementHero({
    required this.unread,
    required this.attention,
    required this.onCompose,
  });
  final int unread;
  final int attention;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0C5C91), Color(0xFF1682C4), Color(0xFF54A9D8)],
      ),
      borderRadius: BorderRadius.circular(19),
      boxShadow: const [
        BoxShadow(
          color: Color(0x301682C4),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: 15,
          top: 3,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x30FFFFFF), width: 18),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x2AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '◈  TRUNG TÂM VẬN HÀNH & KẾT NỐI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFE3EDFF),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '● Trực tuyến',
                    style: TextStyle(color: Color(0xFFD4FDEB), fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Thông báo & Vận hành',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$unread chưa đọc  ·  $attention việc cần chú ý giải quyết',
                style: const TextStyle(color: Color(0xFFEAF1FF), fontSize: 11),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 37,
                child: FilledButton.icon(
                  onPressed: onCompose,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E57DC),
                    minimumSize: const Size(0, 37),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text(
                    'Gửi thông báo cư dân',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
