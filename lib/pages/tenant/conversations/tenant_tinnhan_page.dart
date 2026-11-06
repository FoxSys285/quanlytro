import 'package:flutter/material.dart';

import '../tenant_detail_ui.dart';
import '../tenant_ui.dart';
import '../../shared/conversations/conversation_store.dart';
import '../../shared/rental/tenant_session.dart';
import 'components/tenant_bongbongtinnhan.dart';
import 'models/tenant_cuoctrochuyen.dart';
import '../../landlord/landlord_demo_store.dart';

class TenantTinNhanPage extends StatefulWidget {
  const TenantTinNhanPage({super.key, this.conversation});

  final TenantConversation? conversation;

  @override
  State<TenantTinNhanPage> createState() => _TenantTinNhanPageState();
}

class _TenantTinNhanPageState extends State<TenantTinNhanPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  late final TenantConversation _conversation;

  String get _tenantId {
    final id = _conversation.source?.tenantId.trim();
    return id == null || id.isEmpty ? TenantSession.currentTenantId : id;
  }

  String get _tenantPhone {
    final source = _conversation.source;
    if (source == null) return TenantSession.phone;
    final store = RentalPortfolio.instance.byId(source.propertyId);
    final lease = source.leaseId == null
        ? null
        : store?.leaseById(source.leaseId!);
    final currentLease =
        lease ??
        (store == null
            ? null
            : store
                  .leasesForTenant(source.tenantId)
                  .where((item) => item.isCurrent)
                  .firstOrNull);
    final phone = currentLease?.phone.trim();
    return phone == null || phone.isEmpty ? TenantSession.phone : phone;
  }

  @override
  void initState() {
    super.initState();
    _conversation =
        widget.conversation ?? TenantConversation.demoConversations.first;
    if (_conversation.source == null) _conversation.unread = 0;
    ConversationStore.instance.addListener(_refresh);
    _scrollToLatest();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    _scrollToLatest();
  }

  @override
  void dispose() {
    ConversationStore.instance.removeListener(_refresh);
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    final source = _conversation.source;
    if (source != null && source.tenantUnread > 0) {
      ConversationStore.instance.markRead(source, landlord: false);
    }
  });

  void _showInfo() {
    final source = _conversation.source;
    final property = source == null
        ? null
        : RentalPortfolio.instance.byId(source.propertyId)?.property;
    showDialog<void>(
      context: context,
      builder: (context) => TenantDetailTheme(
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Thông tin cuộc trò chuyện',
            style: TextStyle(
              color: tenantInk,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TenantProfileAvatar(
                        name: _conversation.landlordName,
                        radius: 25,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _conversation.landlordName,
                          style: const TextStyle(
                            color: tenantInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TenantDetailNote(
                    _conversation.contextLabel,
                    icon: Icons.home_outlined,
                  ),
                  if (property != null) ...[
                    const SizedBox(height: 12),
                    TenantDetailRow(label: 'Nhà trọ', value: property.name),
                    TenantDetailRow(label: 'Địa chỉ', value: property.address),
                    TenantDetailRow(label: 'Điện thoại', value: property.phone),
                  ],
                  if (source?.leaseId != null)
                    TenantDetailRow(label: 'Hợp đồng', value: source!.leaseId!),
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

  Future<void> _quickMessage() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TenantDetailTheme(
        child: TenantBottomSheetSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const TenantSheetHandle(),
              const Text(
                'Tin nhắn gợi ý',
                style: TextStyle(
                  color: tenantInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn mẫu rồi chỉnh sửa trước khi gửi.',
                style: TextStyle(color: tenantMuted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 18),
              for (final (title, text) in [
                (
                  'Gửi mã người thuê trọ',
                  'Mã người thuê trọ của tôi là $_tenantId.',
                ),
                (
                  'Gửi số điện thoại',
                  'Số điện thoại của tôi là $_tenantPhone.',
                ),
              ]) ...[
                TenantSurface(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: const TenantDetailIcon(
                      Icons.chat_bubble_outline_rounded,
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      text,
                      style: const TextStyle(
                        color: tenantMuted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: tenantMuted,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () => Navigator.pop(context, text),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
    if (!mounted || text == null) return;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _focus.requestFocus();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final time = TimeOfDay.now().format(context);
    setState(() {
      _conversation.send(text, time);
      _controller.clear();
    });
    _scrollToLatest();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation.messages;
    final propertyName = _conversation.source?.propertyName.trim();
    return TenantDetailTheme(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8F5),
        appBar: AppBar(
          backgroundColor: tenantCanvas,
          titleSpacing: 0,
          title: Row(
            children: [
              TenantProfileAvatar(name: _conversation.landlordName, radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _conversation.landlordName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      propertyName == null || propertyName.isEmpty
                          ? 'Chủ trọ'
                          : propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: tenantMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Thông tin cuộc trò chuyện',
              onPressed: _showInfo,
              icon: const Icon(
                Icons.info_outline_rounded,
                color: tenantGreenDark,
                size: 23,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: Center(
                              child: TenantStatusPill(
                                messages.isEmpty
                                    ? 'Bắt đầu cuộc trò chuyện'
                                    : 'Cuộc trò chuyện',
                                color: tenantMuted,
                              ),
                            ),
                          );
                        }
                        return TenantMessageBubble(
                          message: messages[index - 1],
                        );
                      },
                    ),
                  ),
                  _composer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer() => ColoredBox(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: tenantLine)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Tin nhắn gợi ý',
              onPressed: _quickMessage,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: tenantGreenDark,
                size: 25,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 14,
                  height: 1.5,
                ),
                onTap: _scrollToLatest,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: tenantMuted, fontSize: 13),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => IconButton.filled(
                tooltip: 'Gửi tin nhắn',
                onPressed: value.text.trim().isEmpty ? null : _send,
                style: IconButton.styleFrom(
                  minimumSize: const Size(46, 46),
                  backgroundColor: tenantGreen,
                  disabledBackgroundColor: const Color(0xFFEAF0EC),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF9DAAA1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
