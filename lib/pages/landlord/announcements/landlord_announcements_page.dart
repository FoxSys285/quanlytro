import 'dart:async';

import 'package:flutter/material.dart';

import 'components/landlord_announcement_card.dart';
import 'components/landlord_announcement_composer.dart';
import 'data/landlord_announcement_demo_data.dart';
import 'models/landlord_announcement.dart';
import '../../shared/announcements/announcement_store.dart';

class LandlordAnnouncementsPage extends StatefulWidget {
  const LandlordAnnouncementsPage({super.key, this.store});
  final AnnouncementStore? store;

  @override
  State<LandlordAnnouncementsPage> createState() =>
      _LandlordAnnouncementsPageState();
}

class _LandlordAnnouncementsPageState extends State<LandlordAnnouncementsPage> {
  AnnouncementStore get _store => widget.store ?? AnnouncementStore.instance;
  List<LandlordAnnouncement> get _inbox => _store.inbox;
  List<LandlordAnnouncement> get _sent => _store.sent;
  Timer? _timer;
  String _query = '';
  String _readFilter = 'all';
  AnnouncementCategory? _category;
  bool _showSent = false;

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
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi thông báo đến người thuê trong phiên hiện tại.'),
      ),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final unread = _inbox.where((item) => !item.isRead).length;
    final query = _query.trim().toLowerCase();
    final items =
        (_showSent ? _sent : _inbox)
            .where(
              (item) =>
                  '${item.title} ${item.content} ${_propertyName(item.propertyId)}'
                      .toLowerCase()
                      .contains(query) &&
                  (_category == null || item.category == _category) &&
                  (_showSent ||
                      _readFilter == 'all' ||
                      (_readFilter == 'unread' ? !item.isRead : item.isRead)),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông báo & vận hành',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '$unread chưa đọc · ${_inbox.where((item) => !item.isRead && item.priority != AnnouncementPriority.normal).length} cần chú ý',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _compose,
                icon: const Icon(Icons.add),
                label: const Text('Tạo thông báo'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3769D6),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Nhận được (${_inbox.length})'),
                    selected: !_showSent,
                    onSelected: (_) => setState(() => _showSent = false),
                  ),
                  ChoiceChip(
                    label: Text('Đã gửi (${_sent.length})'),
                    selected: _showSent,
                    onSelected: (_) => setState(() => _showSent = true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Tìm theo phòng hoặc nội dung',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<AnnouncementCategory>(
                      key: ValueKey('category:$_category'),
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Phân loại'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tất cả nội dung'),
                        ),
                        for (final category in AnnouncementCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          ),
                      ],
                      onChanged: (value) => setState(() => _category = value),
                    ),
                  ),
                ],
              ),
              if (!_showSent) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in {
                      'all': 'Tất cả',
                      'unread': 'Chưa đọc',
                      'read': 'Đã đọc',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _readFilter == entry.key,
                        onSelected: (_) =>
                            setState(() => _readFilter = entry.key),
                      ),
                    TextButton(
                      onPressed: unread == 0
                          ? null
                          : _store.markAllLandlordRead,
                      child: const Text('Đánh dấu tất cả đã đọc'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Text(
                '${items.length} thông báo',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
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
                ),
              const SizedBox(height: 12),
              const Text(
                'Thông báo và trạng thái đọc được lưu trong phiên hiện tại.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
