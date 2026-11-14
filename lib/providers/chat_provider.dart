import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/source_card.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String? _conversationId;

  List<ChatMessage> get messages => _messages;
  bool get isStreaming => _isStreaming;
  String? get conversationId => _conversationId;

  ChatProvider() {
    _loadHistory();
  }

  void _loadHistory() {
    _messages = StorageService.getChatHistory();
    notifyListeners();
  }

  Future<void> sendMessage({
    required String query,
    Student? student,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _isStreaming) return;

    // 1. Add user message
    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: cleanQuery,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // 2. Add placeholder assistant message
    final botMsgId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    final botMsg = ChatMessage(
      id: botMsgId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(botMsg);
    _isStreaming = true;
    notifyListeners();

    // 3. Connect to SSE stream
    try {
      final stream = ApiService.streamChatQuery(
        query: cleanQuery,
        nim: student?.nim,
        conversationId: _conversationId,
      );

      final sources = <SourceCard>[];
      final suggestions = <String>[];

      await for (final event in stream) {
        final type = event['type'];

        if (type == 'token') {
          botMsg.content += event['content'] ?? '';
          notifyListeners();
        } else if (type == 'sources') {
          final List list = event['data'] ?? [];
          sources.addAll(list.map((s) => SourceCard.fromJson(s)));
        } else if (type == 'suggestions') {
          final List list = event['data'] ?? [];
          suggestions.addAll(List<String>.from(list));
        } else if (type == 'meta') {
          _conversationId = event['conversation_id'];
        } else if (type == 'done') {
          break;
        }
      }

      // Finish streaming
      botMsg.isStreaming = false;
      botMsg.sources.addAll(sources);
      botMsg.suggestions.addAll(suggestions);
      _isStreaming = false;

      // Save updated history
      await StorageService.saveChatHistory(_messages);
      notifyListeners();

    } catch (e) {
      botMsg.content += '\n\n[Gagal memuat jawaban: $e]';
      botMsg.isStreaming = false;
      _isStreaming = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(ChatMessage msg) async {
    await StorageService.toggleBookmark(msg);
    notifyListeners();
  }

  Future<void> clearChat() async {
    _messages.clear();
    _conversationId = null;
    await StorageService.clearChatHistory();
    notifyListeners();
  }
}
