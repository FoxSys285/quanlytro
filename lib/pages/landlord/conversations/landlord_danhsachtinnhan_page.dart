import 'package:flutter/material.dart';

import '../../../layouts/landlord_navigation.dart';
import '../../shared/conversations/conversation_store.dart';
import '../../shared/widgets/list_pagination.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import 'landlord_tinnhan_page.dart';
import 'models/landlord_cuoctrochuyen.dart';

class LandlordDanhSachTinNhanPage extends StatefulWidget {
  const LandlordDanhSachTinNhanPage({super.key, this.profileName});
  final String? profileName;
  @override
  State<LandlordDanhSachTinNhanPage> createState() =>
      _LandlordDanhSachTinNhanPageState();
}

class _LandlordDanhSachTinNhanPageState
    extends State<LandlordDanhSachTinNhanPage> {
  String _query = '';
  bool _unreadOnly = false;
  int _page = 0;
  ConversationStore get _store => ConversationStore.instance;

  Future<void> _open(LandlordConversation conversation) async {
    _store.markRead(conversation, landlord: true);
    await LandlordNavigation.push<void>(
      context,
      page: LandlordTinNhanPage(conversation: conversation),
      destinationId: 'conversations',
    );
  }

  Future<void> _compose() async {
    final rental = LandlordDemoStore.activeInstance;
    final lease = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhắn tin cho người thuê',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (rental.activeLeases.isEmpty)
              const Text('Chưa có người thuê với hợp đồng đang có hiệu lực.'),
            for (final lease in rental.activeLeases)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(lease.tenantName),
                subtitle: Text('Phòng ${lease.room}'),
                trailing: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: propertyBlue,
                ),
                onTap: () => Navigator.pop(context, lease.id),
              ),
          ],
        ),
      ),
    );
    if (!mounted || lease == null) return;
    final record = rental.leaseById(lease);
    if (record == null) return;
    if (record.tenantId.isEmpty) {
      showLandlordMessage(
        context,
        'Người thuê chưa liên kết tài khoản để nhận tin nhắn.',
      );
      return;
    }
    final existing = _store
        .forProperty(rental.property.id)
        .where(
          (c) =>
              c.tenantId == record.tenantId &&
              (c.leaseId == record.id ||
                  rental.canonicalRoom(c.room) ==
                      rental.canonicalRoom(record.room)),
        )
        .firstOrNull;
    final conversation =
        existing ??
        _store.forRoom(
          propertyId: rental.property.id,
          roomId: rental.canonicalRoom(record.room),
          roomName: record.room,
          landlordName: rental.property.ownerName,
          propertyName: rental.property.name,
          tenantId: record.tenantId,
          tenantName: record.tenantName,
        );
    await _open(conversation);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_store, RentalPortfolio.instance]),
    builder: (context, _) {
      final all = _store.forProperty(
        LandlordDemoStore.activeInstance.property.id,
      );
      final unread = all.fold<int>(0, (sum, c) => sum + c.unread);
      final conversations = all
          .where(
            (c) =>
                (!_unreadOnly || c.unread > 0) &&
                '${c.tenantName} ${c.room} ${c.messages.lastOrNull?.text ?? ''}'
                    .toLowerCase()
                    .contains(_query.trim().toLowerCase()),
          )
          .toList();
      conversations.sort((a, b) {
        final aTime = a.messages.lastOrNull?.createdAt;
        final bTime = b.messages.lastOrNull?.createdAt;
        if (aTime != null && bTime != null) return bTime.compareTo(aTime);
        if (aTime != null) return -1;
        if (bTime != null) return 1;
        return all.indexOf(a).compareTo(all.indexOf(b));
      });
      final page = _page.clamp(
        0,
        ListPagination.lastPage(conversations.length, 20),
      );
      return LandlordGlassPage(
        profileName: widget.profileName,
        title: 'Tin nhắn',
        kicker: 'KẾT NỐI NGƯỜI THUÊ',
        subtitle: 'Trao đổi nhanh với người thuê theo từng phòng.',
        children: [
          LandlordBluePanel(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unread tin chưa đọc',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${all.length} cuộc trò chuyện của nhà trọ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDDEAFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LandlordGlassSearch(
            hint: 'Tìm người thuê, phòng hoặc tin nhắn',
            onChanged: (value) => setState(() {
              _query = value;
              _page = 0;
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: !_unreadOnly,
                        onSelected: (_) => setState(() {
                          _unreadOnly = false;
                          _page = 0;
                        }),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          'Chưa đọc · ${all.where((c) => c.unread > 0).length}',
                        ),
                        selected: _unreadOnly,
                        onSelected: (_) => setState(() {
                          _unreadOnly = true;
                          _page = 0;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Tin nhắn mới',
                onPressed: _compose,
                icon: const Icon(Icons.edit_square),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const LandlordGlassSection(
            title: 'Trao đổi gần đây',
            subtitle: 'Chạm cuộc trò chuyện để xem và trả lời',
          ),
          if (conversations.isEmpty)
            LandlordGlassCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: propertyBlue,
                    size: 35,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    all.isEmpty
                        ? 'Chưa có cuộc trò chuyện nào.'
                        : 'Không có cuộc trò chuyện phù hợp.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _compose,
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('Bắt đầu trò chuyện'),
                  ),
                ],
              ),
            ),
          for (final conversation in conversations.skip(page * 20).take(20))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ConversationCard(
                conversation: conversation,
                onTap: () => _open(conversation),
              ),
            ),
          ListPagination(
            total: conversations.length,
            page: page,
            pageSize: 20,
            onChanged: (value) => setState(() => _page = value),
          ),
        ],
      );
    },
  );
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation, required this.onTap});
  final LandlordConversation conversation;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final name = conversation.tenantName.trim();
    final last = conversation.messages.lastOrNull;
    return LandlordGlassCard(
      onTap: onTap,
      tint: conversation.unread > 0 ? propertyBlue : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8CDEFF), Color(0xFF0873F7)],
              ),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Người thuê' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: conversation.unread > 0
                        ? FontWeight.w800
                        : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng ${conversation.room}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: propertyBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  last == null
                      ? 'Chưa có tin nhắn'
                      : '${last.fromLandlord ? 'Bạn: ' : ''}${last.text}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                last?.time ?? '',
                style: TextStyle(color: palette.muted, fontSize: 10),
              ),
              const SizedBox(height: 10),
              if (conversation.unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: propertyBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${conversation.unread}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: palette.muted,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
