import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import 'components/tenant_message_bubble.dart';
import 'models/tenant_conversation.dart';
import 'models/tenant_conversation_message.dart';

class TenantLandlordConversationPage extends StatefulWidget {
  const TenantLandlordConversationPage({super.key, this.conversation});

  final TenantConversation? conversation;

  @override
  State<TenantLandlordConversationPage> createState() =>
      _TenantLandlordConversationPageState();
}

class _TenantLandlordConversationPageState
    extends State<TenantLandlordConversationPage> {
  final _controller = TextEditingController();
  late final _conversation =
      widget.conversation ?? TenantConversation.demoConversations.first;
  List<TenantConversationMessage> get _messages => _conversation.messages;

  @override
  void initState() {
    super.initState();
    _conversation.unread = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tenantCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFE8F2EE),
              child: Text(
                _conversation.initials,
                style: const TextStyle(
                  color: tenantGreenDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _conversation.contextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: tenantMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông tin cuộc trò chuyện',
            onPressed: () => showTenantPreviewNotice(context),
            icon: const Icon(Icons.info_outline_rounded, color: tenantGreen),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            color: const Color(0xFFEDF4F1),
            child: Row(
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 15,
                  color: tenantGreenDark,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _conversation.contextLabel,
                    style: const TextStyle(
                      color: tenantGreenDark,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(15, 18, 15, 14),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: TenantStatusPill(
                        'Cuộc trò chuyện',
                        color: tenantMuted,
                      ),
                    ),
                  );
                }
                final message = _messages[index - 1];
                return TenantMessageBubble(message: message);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: tenantLine)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => showTenantPreviewNotice(context),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: tenantMuted,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: tenantCanvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton.filled(
                    tooltip: 'Gửi tin nhắn',
                    onPressed: _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: tenantGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        TenantConversationMessage(
          text: text,
          time: TimeOfDay.now().format(context),
          fromTenant: true,
        ),
      );
      _controller.clear();
    });
  }
}
