import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/source_card.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final http.Client Function() _clientFactory;
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String? _conversationId;
  String? _accountId;
  http.Client? _client;
  int _epoch = 0;
  bool _disposed = false;

  ChatProvider({http.Client Function()? clientFactory})
    : _clientFactory = clientFactory ?? ApiService.clientFactory;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  String? get conversationId => _conversationId;

  bool _isActive(int epoch) =>
      epoch == _epoch &&
      !_disposed &&
      _accountId != null &&
      _accountId == StorageService.accountId;

  // Called by ProxyProvider before rebuilding its consumers.
  void setAccount(String? uid) {
    if (_accountId == uid) return;
    _cancel();
    _accountId = uid;
    _messages = uid == null ? [] : StorageService.getChatHistory();
    _conversationId = uid == null ? null : StorageService.getConversationId();
  }

  void _cancel() {
    ++_epoch;
    _client?.close();
    _client = null;
    _isStreaming = false;
  }

  Future<void> sendMessage({required String query, Student? student}) async {
    final clean = query.trim();
    if (clean.isEmpty || _isStreaming || !_isActive(_epoch)) return;
    if (clean.length > 4000) return;
    final epoch = ++_epoch;
    final history = _messages
        .where(
          (m) =>
              !m.hasError &&
              !m.isStreaming &&
              m.content.isNotEmpty &&
              m.content.length <= 4000,
        )
        .toList();
    final previous = history
        .skip(history.length > 10 ? history.length - 10 : 0)
        .map((m) => {'role': m.role.name, 'content': m.content})
        .toList();
    final now = DateTime.now();
    final user = ChatMessage(
      id: 'usr_${now.microsecondsSinceEpoch}',
      role: MessageRole.user,
      content: clean,
      timestamp: now,
      conversationId: _conversationId,
    );
    final bot = ChatMessage(
      id: 'bot_${now.microsecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: '',
      timestamp: now,
      isStreaming: true,
      conversationId: _conversationId,
    );
    _messages.addAll([user, bot]);
    _isStreaming = true;
    final client = _clientFactory();
    _client = client;
    notifyListeners();
    try {
      await for (final event in ApiService.streamChatQuery(
        query: clean,
        conversationId: _conversationId,
        history: previous,
        client: client,
      )) {
        if (!_isActive(epoch)) return;
        switch (event['type']) {
          case 'token':
            bot.content += event['content'] as String? ?? '';
          case 'sources':
            bot.sources.addAll(
              (event['data'] as List).map((s) => SourceCard.fromJson(s)),
            );
          case 'suggestions':
            bot.suggestions.addAll(List<String>.from(event['data']));
          case 'meta':
            _conversationId = event['conversation_id'] as String?;
            user.conversationId = _conversationId;
            bot.conversationId = _conversationId;
          case 'done':
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      if (!_isActive(epoch)) return;
      bot.hasError = true;
      bot.content += '\n\n[Gagal memuat jawaban: $e]';
    } finally {
      client.close();
      if (_isActive(epoch)) {
        bot.isStreaming = false;
        _isStreaming = false;
        _client = null;
        await StorageService.saveChatHistory(_messages);
        if (_isActive(epoch)) {
          await StorageService.saveConversationId(_conversationId);
          if (_isActive(epoch)) notifyListeners();
        }
      }
    }
  }

  Future<void> toggleBookmark(ChatMessage message) async {
    if (!_isActive(_epoch)) return;
    final epoch = _epoch;
    await StorageService.toggleBookmark(message);
    if (!_isActive(epoch)) return;
    for (final current in _messages.where((m) => m.id == message.id)) {
      current.isBookmarked = message.isBookmarked;
    }
    await StorageService.saveChatHistory(_messages);
    if (_isActive(epoch)) notifyListeners();
  }

  Future<void> clearChat() async {
    if (!_isActive(_epoch)) return;
    _cancel();
    _messages = [];
    _conversationId = null;
    await StorageService.clearChatHistory();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel();
    super.dispose();
  }
}
