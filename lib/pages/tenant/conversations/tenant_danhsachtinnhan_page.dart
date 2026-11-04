import 'package:flutter/material.dart';

import '../tenant_inbox_hero.dart';
import '../tenant_ui.dart';
import '../../shared/conversations/conversation_store.dart';
import 'components/tenant_conversation_card.dart';
import 'models/tenant_cuoctrochuyen.dart';
import 'tenant_tinnhan_page.dart';

class TenantDanhSachTinNhanPage extends StatefulWidget {
  const TenantDanhSachTinNhanPage({super.key, this.showHeader = false});

  final bool showHeader;

  @override
  State<TenantDanhSachTinNhanPage> createState() =>
      _TenantDanhSachTinNhanPageState();
}

class _TenantDanhSachTinNhanPageState extends State<TenantDanhSachTinNhanPage> {
  final _search = TextEditingController();
  bool _unreadOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(TenantConversation conversation) async {
    if (conversation.source != null) {
      ConversationStore.instance.markRead(
        conversation.source!,
        landlord: false,
      );
    } else {
      setState(() => conversation.unread = 0);
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TenantTinNhanPage(conversation: conversation),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ConversationStore.instance,
    builder: (context, _) {
      final all = TenantConversation.demoConversations;
      final unreadCount = all.where((item) => item.unread > 0).length;
      final query = _search.text.trim().toLowerCase();
      final conversations = all
          .where(
            (item) =>
                (!_unreadOnly || item.unread > 0) &&
                '${item.landlordName} ${item.contextLabel} ${item.source?.propertyName ?? ''}'
                    .toLowerCase()
                    .contains(query),
          )
          .toList();
      return TenantInboxPageFrame(
        imageAsset: 'assets/images/tenant_messages_hero.png',
        title: 'Tin nhắn',
        subtitle: 'Kết nối với chủ trọ về chỗ ở và những phòng bạn quan tâm.',
        showHeader: widget.showHeader,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm chủ trọ, nhà trọ hoặc phòng...',
              hintStyle: const TextStyle(color: tenantMuted, fontSize: 12),
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () => setState(_search.clear),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filter(
                'Tất cả (${all.length})',
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
            'Cuộc trò chuyện',
            trailing: Text(
              '${conversations.length} hội thoại',
              style: const TextStyle(color: tenantMuted, fontSize: 11),
            ),
          ),
          if (conversations.isEmpty)
            TenantEmptyState(
              icon: query.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.mark_chat_read_outlined,
              title: query.isNotEmpty
                  ? 'Không tìm thấy cuộc trò chuyện'
                  : _unreadOnly
                  ? 'Bạn đã đọc hết tin nhắn'
                  : 'Chưa có cuộc trò chuyện',
              subtitle: query.isNotEmpty
                  ? 'Thử tìm bằng tên chủ trọ, nhà trọ hoặc số phòng khác.'
                  : _unreadOnly
                  ? 'Các hội thoại đã đọc vẫn nằm trong mục Tất cả.'
                  : 'Hội thoại với chủ trọ sẽ xuất hiện tại đây.',
            ),
          for (final conversation in conversations) ...[
            TenantConversationCard(
              conversation: conversation,
              onTap: () => _open(conversation),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );

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
