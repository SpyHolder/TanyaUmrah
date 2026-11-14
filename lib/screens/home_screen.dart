import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/stat_card.dart';
import 'chat_screen.dart';
import 'documents_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _askQuestion(BuildContext context, String query) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);
    
    chat.sendMessage(query: query, student: auth.currentStudent);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = auth.currentStudent;

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('tU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('tanyaUMRAH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Jelajah Dokumen Resmi',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Halo, ${student?.nama.split(" ").first ?? "Mahasiswa"}! 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ada informasi akademik apa yang ingin Anda tanyakan hari ini?',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 18),

            // Academic Progress Card
            if (student != null) AcademicStatCard(student: student),
            const SizedBox(height: 20),

            // Quick Ask Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tanyakan sesuatu (KRS, cuti, magang...)...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) _askQuestion(context, val.trim());
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Topik Populer
            const Text('Topik Populer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTopicCard(context, 'Cuti Kuliah', Icons.hotel_class_outlined, Colors.amber, 'Bagaimana syarat dan prosedur pengajuan cuti kuliah?'),
                const SizedBox(width: 10),
                _buildTopicCard(context, 'KRS & SKS', Icons.fact_check_outlined, Colors.blue, 'Berapa batas SKS yang boleh diambil semester ini berdasarkan IPK?'),
                const SizedBox(width: 10),
                _buildTopicCard(context, 'Magang / KP', Icons.work_outline, const Color(0xFF10B981), 'Apakah saya sudah memenuhi syarat untuk mengambil Kerja Praktek / Magang?'),
              ],
            ),
            const SizedBox(height: 24),

            // Pertanyaan Sering Ditanyakan (FAQ)
            const Text('Pertanyaan Terakhir & FAQ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            _buildFaqItem(
              context,
              'Berapa SKS minimal untuk mengajukan cuti akademik?',
              'Berdasarkan Pasal 57 Peraturan Akademik 2025, minimal 2 semester.',
            ),
            _buildFaqItem(
              context,
              'Apa saja kriteria penghargaan Geliga Gurindam UMRAH?',
              'Penghargaan prestasi akademik, inovasi, dan kemahasiswaan tingkat nasional/internasional.',
            ),
            _buildFaqItem(
              context,
              'Bagaimana sanksi bagi tindakan plagiarisme tugas akhir?',
              'Dapat dikenakan pembatalan nilai hingga pencabutan status kelulusan (Pedoman Etika).',
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

  Widget _buildTopicCard(BuildContext context, String title, IconData icon, Color color, String query) {
    return Expanded(
      child: InkWell(
        onTap: () => _askQuestion(context, query),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: const Icon(Icons.help_outline_rounded, color: AppConstants.primaryBlue, size: 20),
        title: Text(question, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () => _askQuestion(context, question),
      ),
    );
  }
}
