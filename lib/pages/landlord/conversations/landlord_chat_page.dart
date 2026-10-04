import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import 'models/landlord_conversation.dart';

class LandlordChatPage extends StatefulWidget {
  const LandlordChatPage({super.key, required this.conversation});

  final LandlordConversation conversation;

  @override
  State<LandlordChatPage> createState() => _LandlordChatPageState();
}

class _LandlordChatPageState extends State<LandlordChatPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.conversation.messages.add(
        LandlordMessage(
          text: text,
          time: TimeOfDay.now().format(context),
          fromLandlord: true,
        ),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.conversation.messages;

    return Scaffold(
      backgroundColor: landlordCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.conversation.tenantName} · ${widget.conversation.room}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _Bubble(message: message);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: landlordCanvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(backgroundColor: landlordBlue),
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
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final LandlordMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromLandlord;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? landlordBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: mine ? null : Border.all(color: landlordLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: mine ? Colors.white : landlordInk,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              message.time,
              style: TextStyle(
                color: mine ? Colors.white70 : landlordMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
