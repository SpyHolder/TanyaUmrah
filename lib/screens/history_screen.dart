import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../services/storage_service.dart';
import 'main_navigation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showQuestionDetail(BuildContext context, ChatMessage userMsg, ChatMessage? botMsg) {
    final navScope = MainNavigationScope.of(context);
    final timeStr = DateFormat('d MMMM yyyy, HH:mm').format(userMsg.timestamp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AppConstants.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppConstants.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // User Question Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.softBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pertanyaan Anda:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userMsg.content,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Bot Answer (if present)
              if (botMsg != null && botMsg.content.isNotEmpty) ...[
                const Text(
                  'Jawaban Asisten AI:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.borderLight),
                  ),
                  child: MarkdownBody(
                    data: botMsg.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(fontSize: 12.5, height: 1.45, color: AppConstants.textDark),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppConstants.borderLight),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Tanyakan Ulang'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        navScope?.onAskQuestion(userMsg.content);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.forum_outlined, size: 16),
                      label: const Text('Buka di Tanya AI'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        navScope?.onSwitchTab(1);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final bookmarks = StorageService.getBookmarks();
    final allQuestions = chat.messages
        .where((m) => m.role == MessageRole.user)
        .toList();

    final filteredQuestions = _searchFilter.isEmpty
        ? allQuestions
        : allQuestions
            .where((q) => q.content.toLowerCase().contains(_searchFilter.toLowerCase()))
            .toList();

    final filteredBookmarks = _searchFilter.isEmpty
        ? bookmarks
        : bookmarks
            .where((b) => b.content.toLowerCase().contains(_searchFilter.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Riwayat & Tersimpan',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryBlue,
          labelColor: AppConstants.primaryBlue,
          unselectedLabelColor: AppConstants.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'Pertanyaan (${allQuestions.length})'),
            Tab(text: 'Tersimpan (${bookmarks.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          if (allQuestions.isNotEmpty || bookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.borderLight),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat pertanyaan atau catatan...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: AppConstants.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppConstants.textMuted),
                    suffixIcon: _searchFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchFilter = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchFilter = val.trim()),
                ),
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Chat History
                filteredQuestions.isEmpty
                    ? _buildEmptyState(
                        _searchFilter.isNotEmpty
                            ? 'Tidak ada pertanyaan yang sesuai kata kunci.'
                            : 'Belum ada riwayat pertanyaan.',
                        Icons.history_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredQuestions.length,
                        itemBuilder: (ctx, idx) {
                          final msg = filteredQuestions[idx];
                          final originalIdx = chat.messages.indexOf(msg);
                          ChatMessage? relatedBot;
                          if (originalIdx != -1 && originalIdx + 1 < chat.messages.length) {
                            final next = chat.messages[originalIdx + 1];
                            if (next.role == MessageRole.assistant) {
                              relatedBot = next;
                            }
                          }

                          final timeStr = DateFormat(
                            'd MMM yyyy, HH:mm',
                          ).format(msg.timestamp);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppConstants.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppConstants.softBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: AppConstants.primaryBlue,
                                ),
                              ),
                              title: Text(
                                msg.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textDark,
                                ),
                              ),
                              subtitle: Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppConstants.textMuted,
                              ),
                              onTap: () => _showQuestionDetail(context, msg, relatedBot),
                            ),
                          );
                        },
                      ),

                // Tab 2: Bookmarks
                filteredBookmarks.isEmpty
                    ? _buildEmptyState(
                        _searchFilter.isNotEmpty
                            ? 'Tidak ada catatan simpanan yang cocok.'
                            : 'Belum ada jawaban yang disimpan.',
                        Icons.bookmark_border_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookmarks.length,
                        itemBuilder: (ctx, idx) {
                          final item = filteredBookmarks[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppConstants.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.bookmark_rounded,
                                          size: 16,
                                          color: AppConstants.accentGold,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          DateFormat(
                                            'd MMMM yyyy',
                                          ).format(item.timestamp),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppConstants.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.copy_rounded,
                                            size: 16,
                                            color: AppConstants.textMuted,
                                          ),
                                          tooltip: 'Salin Teks',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: item.content));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Catatan disalin ke clipboard'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: AppConstants.errorRed,
                                          ),
                                          tooltip: 'Hapus Simpanan',
                                          onPressed: () async {
                                            try {
                                              await chat.toggleBookmark(item);
                                            } catch (_) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Gagal menghapus simpanan. Silakan coba lagi.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 12),
                                MarkdownBody(
                                  data: item.content,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                    p: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.45,
                                      color: AppConstants.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
