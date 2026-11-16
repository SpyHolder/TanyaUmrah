import 'source_card.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  String content;
  final List<SourceCard> sources;
  final List<String> suggestions;
  final DateTime timestamp;
  bool isBookmarked;
  bool isStreaming;
  bool hasError;
  String? conversationId;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    List<SourceCard> sources = const [],
    List<String> suggestions = const [],
    required this.timestamp,
    this.isBookmarked = false,
    this.isStreaming = false,
    this.hasError = false,
    this.conversationId,
  }) : sources = List.of(sources),
       suggestions = List.of(suggestions);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: json['content'] ?? '',
      sources: json['sources'] != null
          ? (json['sources'] as List)
                .map((s) => SourceCard.fromJson(s))
                .toList()
          : [],
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isBookmarked: json['is_bookmarked'] ?? false,
      isStreaming: false,
      hasError: json['has_error'] == true,
      conversationId: json['conversation_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role == MessageRole.user ? 'user' : 'assistant',
      'content': content,
      'sources': sources.map((s) => s.toJson()).toList(),
      'suggestions': suggestions,
      'timestamp': timestamp.toIso8601String(),
      'is_bookmarked': isBookmarked,
      'has_error': hasError,
      'conversation_id': conversationId,
    };
  }
}
