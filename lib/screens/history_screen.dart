import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../services/storage_service.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    final bookmarks = StorageService.getBookmarks();

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: const Text('Riwayat & Tersimpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryBlue,
          labelColor: AppConstants.primaryBlue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Percakapan (${chat.messages.where((m) => m.role == MessageRole.user).length})'),
            Tab(text: 'Tersimpan (${bookmarks.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Chat History
          chat.messages.isEmpty
              ? _buildEmptyState('Belum ada riwayat percakapan.', Icons.history_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.messages.length,
                  itemBuilder: (ctx, idx) {
                    final msg = chat.messages[idx];
                    if (msg.role != MessageRole.user) return const SizedBox.shrink();

                    final timeStr = DateFormat('d MMM yyyy, HH:mm').format(msg.timestamp);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline, size: 18, color: AppConstants.primaryBlue),
                        ),
                        title: Text(
                          msg.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                        },
                      ),
                    );
                  },
                ),

          // Tab 2: Bookmarks
          bookmarks.isEmpty
              ? _buildEmptyState('Belum ada jawaban yang disimpan.', Icons.bookmark_border_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookmarks.length,
                  itemBuilder: (ctx, idx) {
                    final item = bookmarks[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bookmark_rounded, size: 16, color: AppConstants.primaryBlue),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('d MMMM yyyy').format(item.timestamp),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                tooltip: 'Hapus Simpanan',
                                onPressed: () async {
                                  await StorageService.toggleBookmark(item);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          MarkdownBody(
                            data: item.content,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
