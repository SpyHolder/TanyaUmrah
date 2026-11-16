import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import 'source_card_widget.dart';
import 'suggestion_chips.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final Function(String) onSuggestionTap;
  final VoidCallback onBookmarkTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.onSuggestionTap,
    required this.onBookmarkTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  String? _feedbackGiven;
  bool _isFeedbackPending = false;
  int _feedbackRequest = 0;

  @override
  void didUpdateWidget(covariant ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.conversationId != widget.message.conversationId) {
      _feedbackRequest++;
      _feedbackGiven = null;
      _isFeedbackPending = false;
    }
  }

  Future<void> _giveFeedback(String rating) async {
    if (!mounted ||
        _isFeedbackPending ||
        widget.message.hasError ||
        widget.message.isStreaming) {
      return;
    }
    final request = ++_feedbackRequest;
    setState(() => _isFeedbackPending = true);
    try {
      await ApiService.sendFeedback(
        messageId: widget.message.id,
        rating: rating,
        conversationId: widget.message.conversationId,
      );
      if (!mounted || request != _feedbackRequest) return;
      setState(() {
        _isFeedbackPending = false;
        if (!widget.message.hasError) _feedbackGiven = rating;
      });
      if (widget.message.hasError) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rating == 'helpful'
                ? 'Terima kasih atas feedback positif Anda! 👍'
                : 'Terima kasih, kami akan meningkatkan jawaban ini! 📝',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted || request != _feedbackRequest) return;
      setState(() => _isFeedbackPending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback gagal dikirim. Silakan coba lagi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final timeStr = DateFormat('HH:mm').format(widget.message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppConstants.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'tU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppConstants.primaryBlue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser)
                        Text(
                          widget.message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        )
                      else ...[
                        if (widget.message.content.isEmpty &&
                            widget.message.isStreaming)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConstants.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sedang menyusun jawaban...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        else
                          MarkdownBody(
                            data: widget.message.content,
                            selectable: true,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    color: Color(0xFF1E293B),
                                  ),
                                  h3: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryBlue,
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                          ),

                        // Source Cards
                        if (widget.message.sources.isNotEmpty)
                          SourceCardWidget(sources: widget.message.sources),

                        // Streaming cursor
                        if (widget.message.isStreaming)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              width: 8,
                              height: 14,
                              child: Container(color: AppConstants.primaryBlue),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                // Assistant Message Actions (Copy, Bookmark, Feedback)
                if (!isUser &&
                    !widget.message.hasError &&
                    !widget.message.isStreaming &&
                    widget.message.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.message.content),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jawaban disalin ke clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onBookmarkTap,
                          child: Icon(
                            widget.message.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 15,
                            color: widget.message.isBookmarked
                                ? AppConstants.primaryBlue
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _isFeedbackPending
                              ? null
                              : () => _giveFeedback('helpful'),
                          child: Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 14,
                            color: _feedbackGiven == 'helpful'
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _isFeedbackPending
                              ? null
                              : () => _giveFeedback('not_helpful'),
                          child: Icon(
                            Icons.thumb_down_alt_outlined,
                            size: 14,
                            color: _feedbackGiven == 'not_helpful'
                                ? Colors.red
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),

                // Suggestion chips
                if (!isUser &&
                    !widget.message.hasError &&
                    widget.message.suggestions.isNotEmpty &&
                    !widget.message.isStreaming)
                  SuggestionChips(
                    suggestions: widget.message.suggestions,
                    onSelect: widget.onSuggestionTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
