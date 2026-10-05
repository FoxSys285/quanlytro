import 'package:flutter/material.dart';

import '../../shared/viewings/components/viewing_status_badge.dart';
import '../../shared/viewings/viewing_store.dart';
import '../conversations/landlord_chat_page.dart';
import '../landlord_demo_store.dart';
import 'components/landlord_viewing_card.dart';
import 'data/viewing_conversation_store.dart';
import 'models/landlord_viewing.dart';

class LandlordViewingsPage extends StatefulWidget {
  const LandlordViewingsPage({
    super.key,
    this.viewings,
    this.store,
    this.conversations,
  }) : assert(viewings == null || store == null);

  // Supply database records here when the data source is connected.
  final List<LandlordViewing>? viewings;
  final ViewingStore? store;
  final ViewingConversationStore? conversations;

  @override
  State<LandlordViewingsPage> createState() => _LandlordViewingsPageState();
}

class _LandlordViewingsPageState extends State<LandlordViewingsPage> {
  ViewingStore? _localStore;
  ViewingStore get _store =>
      widget.store ?? _localStore ?? ViewingStore.instance;
  String get _propertyId => LandlordDemoStore.instance.property.id;
  String _query = '';
  ViewingStatus? _status;

  @override
  void initState() {
    super.initState();
    if (widget.viewings != null) _localStore = ViewingStore(widget.viewings!);
  }

  @override
  void didUpdateWidget(covariant LandlordViewingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewings != widget.viewings) {
      _localStore?.dispose();
      _localStore = widget.viewings == null
          ? null
          : ViewingStore(widget.viewings!);
    }
  }

  @override
  void dispose() {
    _localStore?.dispose();
    super.dispose();
  }

  void _confirm(LandlordViewing viewing) {
    if (_store.confirm(viewing.id, propertyId: _propertyId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận lịch xem phòng.')),
      );
    }
  }

  Future<void> _cancel(LandlordViewing viewing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch xem phòng?'),
        content: Text(
          'Hủy lịch của ${viewing.customerName} vào ${viewingTimeLabel(viewing.startsAt)}, '
          '${viewingDateLabel(viewing.startsAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lịch'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (_store.cancel(viewing.id, propertyId: _propertyId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy lịch xem phòng.')));
    }
  }

  void _message(LandlordViewing viewing) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final conversation =
        (widget.conversations ?? ViewingConversationStore.instance).forViewing(
          viewing,
        );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LandlordChatPage(conversation: conversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final query = _query.trim().toLowerCase();
      final source = _store.forProperty(_propertyId);
      final ordered =
          source.where((viewing) {
            final text =
                '${viewing.customerName} ${viewing.phone} '
                        '${viewing.roomName} ${viewing.address} ${viewing.personalNeeds}'
                    .toLowerCase();
            return text.contains(query) &&
                (_status == null || viewing.status == _status);
          }).toList()..sort((a, b) {
            final timeOrder = a.startsAt.compareTo(b.startsAt);
            return timeOrder == 0 ? a.id.compareTo(b.id) : timeOrder;
          });
      final groups = <DateTime, List<LandlordViewing>>{};
      for (final viewing in ordered) {
        final date = viewing.startsAt;
        final day = DateTime(date.year, date.month, date.day);
        (groups[day] ??= []).add(viewing);
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch xem phòng',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Người thuê đã đặt lịch tại nhà trọ của bạn. Lịch được xếp từ sớm đến muộn.',
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText:
                        'Tìm người đặt, số điện thoại, phòng hoặc nhu cầu',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _status == null,
                      onSelected: (_) => setState(() => _status = null),
                    ),
                    for (final status in ViewingStatus.values)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: _status == status,
                        onSelected: (selected) =>
                            setState(() => _status = selected ? status : null),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${ordered.length} lịch hẹn',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (ordered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Không có lịch xem phòng phù hợp.'),
                    ),
                  ),
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      viewingDateLabel(entry.key),
                      style: const TextStyle(
                        color: Color(0xFF3769D6),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final viewing in entry.value)
                    LandlordViewingCard(
                      key: ValueKey(viewing.id),
                      viewing: viewing,
                      onConfirm: viewing.status == ViewingStatus.pending
                          ? () => _confirm(viewing)
                          : null,
                      onCancel: viewing.status != ViewingStatus.cancelled
                          ? () => _cancel(viewing)
                          : null,
                      onMessage: () => _message(viewing),
                    ),
                ],
                if (widget.viewings == null && widget.store == null)
                  const Text(
                    'Tên, số điện thoại và nhu cầu trên trang là dữ liệu mẫu.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
