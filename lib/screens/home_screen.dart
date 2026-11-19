import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/stat_card.dart';
import 'documents_screen.dart';
import 'main_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ask(BuildContext context, String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    _searchController.clear();
    FocusScope.of(context).unfocus();

    final navScope = MainNavigationScope.of(context);
    if (navScope != null) {
      navScope.onAskQuestion(clean);
    } else {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final chat = Provider.of<ChatProvider>(context, listen: false);
      chat.sendMessage(query: clean, student: auth.currentStudent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chat = Provider.of<ChatProvider>(context);
    final student = auth.currentStudent;

    final recentQuestions = chat.messages
        .where((m) => m.role == MessageRole.user)
        .toList()
        .reversed
        .take(2)
        .toList();

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryBlue, AppConstants.lightPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'tU',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'tanyaUMRAH',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Layanan AI Akademik',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Jelajah Dokumen Resmi',
            onPressed: () async {
              final query = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsScreen()),
              );
              if (query != null && context.mounted) {
                MainNavigationScope.of(context)?.onAskQuestion(query);
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header (No Emoticon - Material Icon Used)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Halo, ${student?.nama.split(" ").first ?? "Mahasiswa"}!',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textDark,
                                letterSpacing: -0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.waving_hand_rounded,
                            size: 19,
                            color: AppConstants.accentGold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Ada informasi akademik yang ingin Anda tanyakan hari ini?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Academic Progress Card
            if (student != null) AcademicStatCard(student: student),
            const SizedBox(height: 18),

            // Quick Ask Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppConstants.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Tanyakan sesuatu (KRS, cuti, magang)...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: AppConstants.textMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _ask(context, val),
                    ),
                  ),
                  IconButton(
                    icon: chat.isStreaming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            size: 20,
                            color: AppConstants.primaryBlue,
                          ),
                    tooltip: 'Kirim Pertanyaan',
                    onPressed: chat.isStreaming
                        ? null
                        : () => _ask(context, _searchController.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Recent Inquiries (If any)
            if (recentQuestions.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AppConstants.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Pertanyaan Terakhir Anda',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...recentQuestions.map((q) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.borderLight),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppConstants.softBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                  title: Text(
                    q.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppConstants.textMuted,
                  ),
                  onTap: () {
                    MainNavigationScope.of(context)?.onSwitchTab(1);
                  },
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Topik Populer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Topik Populer Akademik',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                  label: const Text(
                    'Buka Chat',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  onPressed: () {
                    MainNavigationScope.of(context)?.onSwitchTab(1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTopicCard(
                  context,
                  'Cuti Kuliah',
                  Icons.event_busy_rounded,
                  AppConstants.warningAmber,
                  'Bagaimana syarat dan prosedur pengajuan cuti kuliah?',
                ),
                const SizedBox(width: 10),
                _buildTopicCard(
                  context,
                  'KRS & SKS',
                  Icons.fact_check_rounded,
                  AppConstants.lightPrimary,
                  'Berapa batas SKS yang boleh diambil semester ini berdasarkan IPK?',
                ),
                const SizedBox(width: 10),
                _buildTopicCard(
                  context,
                  'Magang / KP',
                  Icons.work_outline_rounded,
                  AppConstants.successGreen,
                  'Apakah saya sudah memenuhi syarat untuk mengambil Kerja Praktek / Magang?',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTopicCard(
                  context,
                  'Skripsi & TA',
                  Icons.school_rounded,
                  Colors.indigo,
                  'Apa saja syarat pendaftaran seminar proposal dan sidang skripsi?',
                ),
                const SizedBox(width: 10),
                _buildTopicCard(
                  context,
                  'Etika & Sanksi',
                  Icons.gavel_rounded,
                  AppConstants.primaryDark,
                  'Bagaimana sanksi bagi tindakan plagiarisme atau kecurangan akademik?',
                ),
                const SizedBox(width: 10),
                _buildTopicCard(
                  context,
                  'Geliga Gurindam',
                  Icons.emoji_events_rounded,
                  AppConstants.accentGold,
                  'Apa saja kriteria penerima penghargaan Geliga Gurindam UMRAH?',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pertanyaan Sering Ditanyakan (FAQ)
            const Text(
              'Pertanyaan Umum (FAQ Resmi)',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 10),
            _buildFaqItem(
              context,
              'Berapa semester minimal untuk mengajukan cuti akademik?',
              'Berdasarkan Pasal 57 Peraturan Akademik 2025, minimal setelah 2 semester.',
            ),
            _buildFaqItem(
              context,
              'Bagaimana ketentuan predikat kelulusan Pujian (Cumlaude)?',
              'Berdasarkan Pasal 54, IPK > 3.50 dengan masa studi maksimal 4 tahun.',
            ),
            _buildFaqItem(
              context,
              'Bagaimana alur pengisian LIRS di SIPA UMRAH?',
              'Melalui SIPA setelah melakukan registrasi ulang semester berjalan (Pasal 26).',
            ),
            _buildFaqItem(
              context,
              'Bagaimana alur legalisir ijazah dan transkrip di BAPKK?',
              'Prosedur pengajuan legalisir offline dan online melalui loket layanan akademik BAPKK.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String query,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => _ask(context, query),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    String question,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderLight),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppConstants.softBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.help_outline_rounded,
            color: AppConstants.primaryBlue,
            size: 18,
          ),
        ),
        title: Text(
          question,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppConstants.textMuted,
        ),
        onTap: () => _ask(context, question),
      ),
    );
  }
}
