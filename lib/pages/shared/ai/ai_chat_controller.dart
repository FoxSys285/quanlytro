import 'package:flutter/foundation.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_demo_store.dart';
import 'ai_chat_service.dart';

class AiChatController extends ChangeNotifier {
  AiChatController({
    required this.role,
    AiChatService? service,
    LandlordDemoStore? store,
  }) : _service = service ?? AiChatService(),
       _store = store ?? LandlordDemoStore.instance;

  static final _sessions = <AppRole, AiChatController>{};
  static AiChatController forRole(AppRole role) =>
      _sessions.putIfAbsent(role, () => AiChatController(role: role));

  final AppRole role;
  final AiChatService _service;
  final LandlordDemoStore _store;
  final _messages = <AiMessage>[];
  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool isLoading = false;
  String? error;
  bool truncated = false;
  bool _disposed = false;

  Future<void> send(String text) async {
    final question = text.trim();
    if (isLoading || question.isEmpty || question.length > 2000) return;
    if (error != null &&
        _messages.isNotEmpty &&
        _messages.last.role == 'user') {
      _messages.removeLast();
    }
    _messages.add(AiMessage(role: 'user', content: question));
    await _answer();
  }

  Future<void> retry() async {
    if (isLoading || error == null || _messages.isEmpty) return;
    await _answer();
  }

  Future<void> _answer() async {
    isLoading = true;
    error = null;
    truncated = false;
    notifyListeners();
    try {
      final reply = await _service.reply(
        role: role,
        messages: messages,
        context: buildAiContext(role, _store),
      );
      if (_disposed) return;
      _messages.add(AiMessage(role: 'assistant', content: reply.text));
      truncated = reply.truncated;
    } on AiChatException catch (failure) {
      if (!_disposed) error = failure.message;
    } catch (_) {
      if (!_disposed) error = 'Chưa xử lý được câu hỏi. Bạn thử lại nhé.';
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    if (isLoading) return;
    _messages.clear();
    error = null;
    truncated = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
