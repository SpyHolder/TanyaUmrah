import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    _textController.clear();
    chat.sendMessage(query: text, student: auth.currentStudent);
    _scrollToBottom();
  }

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Input Suara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 48, color: AppConstants.primaryBlue),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan ucapkan pertanyaan akademik Anda...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _textController.text = 'Apakah saya bisa mengambil mata kuliah di semester atas?';
            },
            child: const Text('Simulasi Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Auto scroll when message streaming updates
    _scrollToBottom();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('tanyaUMRAH Asisten AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('RAG Knowledge Base Aktif', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Percakapan Baru',
            onPressed: () {
              chat.clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Percakapan baru dimulai'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat list
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppConstants.primaryBlue.withOpacity(0.08), shape: BoxShape.circle),
                            child: const Icon(Icons.auto_awesome, size: 36, color: AppConstants.primaryBlue),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ada yang bisa saya bantu seputar aturan kampus?',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tanyakan informasi KRS, cuti kuliah, syarat magang, etika akademik, hingga SOP layanan BAPKK.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chat.messages[index];
                      return ChatBubble(
                        message: msg,
                        onBookmarkTap: () => chat.toggleBookmark(msg),
                        onSuggestionTap: (suggestion) {
                          chat.sendMessage(query: suggestion, student: auth.currentStudent);
                        },
                      );
                    },
                  ),
          ),

          // Bottom Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: AppConstants.primaryBlue),
                    tooltip: 'Input Suara',
                    onPressed: _showVoiceInputDialog,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Ketik pertanyaan akademik...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: chat.isStreaming
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      onPressed: chat.isStreaming ? null : _send,
                    ),
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
