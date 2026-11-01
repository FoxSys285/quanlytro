import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../layouts/role_layout.dart';
import 'ai_chat_controller.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, required this.role, this.controller});
  final AppRole role;
  final AiChatController? controller;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  AiChatController get _chat =>
      widget.controller ?? AiChatController.forRole(widget.role);
  Color get _accent => widget.role == AppRole.landlord
      ? const Color(0xFF3769D6)
      : const Color(0xFF16836F);

  @override
  void initState() {
    super.initState();
    _chat.addListener(_refresh);
    _toBottom();
  }

  @override
  void didUpdateWidget(covariant AiChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old =
        oldWidget.controller ?? AiChatController.forRole(oldWidget.role);
    if (old != _chat) {
      old.removeListener(_refresh);
      _chat.addListener(_refresh);
      _input.clear();
      _toBottom();
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
      _toBottom();
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      if (_chat.messages.isEmpty) {
        _scroll.jumpTo(0);
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });

  void _send([String? suggestion]) {
    final text = suggestion ?? _input.text;
    if (text.trim().isEmpty || text.trim().length > 2000 || _chat.isLoading) {
      return;
    }
    _input.clear();
    _chat.send(text);
  }

  @override
  void dispose() {
    _chat.removeListener(_refresh);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Giải thích kiến trúc đồ án quản lý trọ',
      if (widget.role == AppRole.tenant)
        'Làm sao thêm người ở cùng?'
      else
        'Duyệt yêu cầu thêm người ở đâu?',
      'Cách tính tiền điện nước hằng tháng?',
      'Khi đi xem phòng trọ cần kiểm tra gì?',
    ];
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _accent.withValues(alpha: 0.12),
                      child: Icon(Icons.auto_awesome_rounded, color: _accent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trợ lý AI',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Hỏi về đồ án & cuộc sống ở trọ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cuộc trò chuyện mới',
                      onPressed: _chat.isLoading || _chat.messages.isEmpty
                          ? null
                          : _chat.clear,
                      icon: const Icon(Icons.add_comment_outlined),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_chat.messages.isEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Mình có thể giúp gì cho bạn?',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Bạn có thể hỏi cách dùng ứng dụng, nghiệp vụ quản lý trọ, giải thích đồ án hoặc kinh nghiệm thuê phòng.',
                        style: TextStyle(color: Colors.blueGrey, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      for (final suggestion in suggestions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton(
                            onPressed: () => _send(suggestion),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(16),
                              foregroundColor: _accent,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(suggestion),
                          ),
                        ),
                    ],
                    for (final message in _chat.messages)
                      Align(
                        alignment: message.role == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 720),
                          margin: EdgeInsets.only(
                            bottom: 14,
                            left: message.role == 'user' ? 30 : 0,
                            right: message.role == 'user' ? 0 : 20,
                          ),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: message.role == 'user'
                                ? _accent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: message.role == 'user'
                                ? null
                                : Border.all(color: const Color(0xFFE1E8ED)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.role == 'user' ? 'Bạn' : 'Trợ lý AI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: message.role == 'user'
                                      ? Colors.white70
                                      : _accent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (message.role == 'user')
                                SelectableText(
                                  message.content,
                                  style: TextStyle(
                                    color: message.role == 'user'
                                        ? Colors.white
                                        : const Color(0xFF1B2935),
                                    height: 1.5,
                                  ),
                                )
                              else
                                MarkdownBody(
                                  data: message.content,
                                  selectable: true,
                                  imageBuilder: (_, _, alt) =>
                                      Text(alt ?? 'Hình ảnh'),
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(
                                        Theme.of(context),
                                      ).copyWith(
                                        p: const TextStyle(
                                          color: Color(0xFF1B2935),
                                          height: 1.5,
                                        ),
                                        code: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (_chat.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Đang trả lời…'),
                          ],
                        ),
                      ),
                    if (_chat.error != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _chat.error!,
                              style: const TextStyle(color: Color(0xFFA54225)),
                            ),
                            TextButton.icon(
                              onPressed: _chat.retry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    if (_chat.truncated)
                      const Text(
                        'Câu trả lời đã rút gọn. Bạn có thể yêu cầu AI giải thích tiếp.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE1E8ED))),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 2000,
                            enabled: !_chat.isLoading,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Nhập câu hỏi về đồ án hoặc trọ…',
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF5F7FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Gửi câu hỏi',
                          onPressed:
                              _chat.isLoading || _input.text.trim().isEmpty
                              ? null
                              : () => _send(),
                          style: IconButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'AI có thể nhầm. Chỉ hỗ trợ tư vấn; hãy kiểm tra lại thông tin quan trọng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
