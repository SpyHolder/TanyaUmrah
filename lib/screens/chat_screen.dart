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
      if (mounted && _scrollController.hasClients) {
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

    if (chat.isStreaming) return;
    if (text.length > 4000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pertanyaan maksimal 4.000 karakter.')),
      );
      return;
    }
    _textController.clear();
    chat.sendMessage(query: text, student: auth.currentStudent);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter < 120) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'tanyaUMRAH Asisten AI',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: chat.isStreaming
                        ? AppConstants.accentGold
                        : AppConstants.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  chat.isStreaming
                      ? 'Sedang menuliskan jawaban...'
                      : 'Asisten resmi berbasis dokumen',
                  style: const TextStyle(fontSize: 10, color: AppConstants.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Percakapan Baru',
            onPressed: () {
              if (chat.messages.isEmpty) return;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Mulai Percakapan Baru?'),
                  content: const Text(
                    'Pesan saat ini akan dibersihkan dan sesi pertanyaan baru akan dimulai.',
                    style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.errorRed,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        chat.clearChat();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Percakapan baru telah dimulai.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Text('Mulai Baru'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Chat list
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryBlue.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 40,
                              color: AppConstants.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Ada yang bisa saya bantu seputar aturan kampus?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tanyakan informasi KRS, cuti kuliah, syarat magang, skripsi, hingga SOP layanan BAPKK UMRAH.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppConstants.textMuted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Quick Starter Questions
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pilihan Pertanyaan Cepat:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStarterChip(
                            context,
                            'Bagaimana syarat dan prosedur pengajuan cuti kuliah?',
                            Icons.event_busy_rounded,
                          ),
                          _buildStarterChip(
                            context,
                            'Berapa batas SKS yang boleh diambil semester ini berdasarkan IPK?',
                            Icons.fact_check_rounded,
                          ),
                          _buildStarterChip(
                            context,
                            'Apakah saya sudah memenuhi syarat untuk mengambil Kerja Praktek / Magang?',
                            Icons.work_outline_rounded,
                          ),
                          _buildStarterChip(
                            context,
                            'Apa saja syarat pendaftaran seminar proposal dan sidang skripsi?',
                            Icons.school_rounded,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chat.messages[index];
                      return ChatBubble(
                        key: ValueKey(msg.id),
                        message: msg,
                        onBookmarkTap: () => chat.toggleBookmark(msg),
                        onSuggestionTap: (suggestion) {
                          chat.sendMessage(
                            query: suggestion,
                            student: auth.currentStudent,
                          );
                        },
                      );
                    },
                  ),
          ),

          // Bottom Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppConstants.borderLight)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceAlt,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppConstants.borderLight),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Ketik pertanyaan akademik...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppConstants.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          fillColor: Colors.transparent,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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

  Widget _buildStarterChip(
    BuildContext context,
    String question,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          side: const BorderSide(color: AppConstants.borderLight),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 16, color: AppConstants.primaryBlue),
        label: Text(
          question,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textDark,
            fontWeight: FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final chat = Provider.of<ChatProvider>(context, listen: false);
          chat.sendMessage(query: question, student: auth.currentStudent);
        },
      ),
    );
  }
}
