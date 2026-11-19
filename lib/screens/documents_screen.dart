import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/api_service.dart';
import 'document_viewer_screen.dart';
import 'main_navigation.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDocs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDocs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getDocuments();
      if (!mounted) return;
      setState(() {
        _documents = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat dokumen knowledge base. Pastikan koneksi internet atau server backend aktif.';
      });
    }
  }

  List<String> get _categories {
    final cats = <String>{'Semua'};
    for (final doc in _documents) {
      final cat = doc['kategori']?.toString().trim();
      if (cat != null && cat.isNotEmpty) {
        cats.add(cat);
      }
    }
    return cats.toList();
  }

  List<Map<String, dynamic>> get _filteredDocuments {
    return _documents.where((doc) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          (doc['kategori']?.toString().toLowerCase() == _selectedCategory.toLowerCase());
      final query = _searchQuery.toLowerCase();
      final nama = (doc['nama'] ?? '').toString().toLowerCase();
      final filename = (doc['filename'] ?? '').toString().toLowerCase();
      final matchesSearch = query.isEmpty || nama.contains(query) || filename.contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _onAskAboutDoc(Map<String, dynamic> doc) {
    final title = (doc['nama'] ?? 'Dokumen Akademik').toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppConstants.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanyakan ke AI Akademik',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                          ),
                        ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Pilih pertanyaan cepat atau eksplorasi dokumen:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPromptOption(
                bottomSheetCtx,
                icon: Icons.summarize_rounded,
                title: 'Rangkuman Isi Pokok',
                query: 'Rangkumkan poin-poin penting dan aturan utama yang ada di dokumen $title.',
              ),
              const SizedBox(height: 8),
              _buildPromptOption(
                bottomSheetCtx,
                icon: Icons.rule_rounded,
                title: 'Syarat & Ketentuan Mahasiswa',
                query: 'Apa saja syarat dan ketentuan penting bagi mahasiswa berdasarkan dokumen $title?',
              ),
              const SizedBox(height: 8),
              _buildPromptOption(
                bottomSheetCtx,
                icon: Icons.help_outline_rounded,
                title: 'Prosedur & Alur Pelaksanaan',
                query: 'Bagaimana prosedur dan alur administratif yang dijelaskan pada dokumen $title?',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromptOption(
    BuildContext bottomSheetCtx, {
    required IconData icon,
    required String title,
    required String query,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(bottomSheetCtx);
        if (Navigator.canPop(context)) {
          Navigator.pop(context, query);
        } else {
          MainNavigationScope.of(context)?.onAskQuestion(query);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppConstants.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppConstants.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDocuments;
    final totalDocs = _documents.length;
    final totalPages = _documents.fold<int>(
      0,
      (sum, d) => sum + ((d['jumlah_halaman'] as num?)?.toInt() ?? 0),
    );
    final totalChunks = _documents.fold<int>(
      0,
      (sum, d) => sum + ((d['jumlah_chunk'] as num?)?.toInt() ?? 0),
    );

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Basis Pengetahuan Resmi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _fetchDocs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5),
                  SizedBox(height: 16),
                  Text(
                    'Sinkronisasi basis pengetahuan...',
                    style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 40,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _fetchDocs,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _documents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppConstants.softBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.folder_open_rounded,
                                size: 40,
                                color: AppConstants.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Dokumen Terindeks',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Knowledge base RAG sedang dipersiapkan oleh administrator akademik.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Knowledge Base Summary Metrics
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppConstants.primaryNavy, AppConstants.primaryBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppConstants.primaryNavy.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.verified_rounded,
                                          color: AppConstants.accentGold,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Sistem RAG Terverifikasi UMRAH',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildMetricItem(
                                        label: 'Dokumen',
                                        value: '$totalDocs',
                                        icon: Icons.menu_book_rounded,
                                      ),
                                      Container(
                                        height: 32,
                                        width: 1,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      _buildMetricItem(
                                        label: 'Halaman',
                                        value: '$totalPages',
                                        icon: Icons.auto_stories_rounded,
                                      ),
                                      Container(
                                        height: 32,
                                        width: 1,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      _buildMetricItem(
                                        label: 'Vektor AI',
                                        value: '$totalChunks',
                                        icon: Icons.hub_rounded,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Search Input
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Cari nama dokumen atau peraturan...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Categories filter (if more than 1 category exists)
                        if (_categories.length > 1)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 4),
                              child: SizedBox(
                                height: 38,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _categories.length,
                                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                                  itemBuilder: (ctx, idx) {
                                    final cat = _categories[idx];
                                    final isSelected = cat == _selectedCategory;
                                    return ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedCategory = cat;
                                          });
                                        }
                                      },
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.white : AppConstants.textSecondary,
                                      ),
                                      selectedColor: AppConstants.primaryBlue,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                        color: isSelected ? AppConstants.primaryBlue : AppConstants.borderLight,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        // List of Document Cards
                        if (filtered.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Tidak ada dokumen yang sesuai dengan pencarian Anda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppConstants.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, idx) {
                                  final doc = filtered[idx];
                                  return _buildDocCard(doc);
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppConstants.accentGold),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final nama = doc['nama'] ?? 'Dokumen Resmi UMRAH';
    final filename = doc['filename'] ?? '';
    final tahun = doc['tahun']?.toString() ?? '-';
    final halaman = doc['jumlah_halaman']?.toString() ?? '-';
    final chunk = doc['jumlah_chunk']?.toString() ?? '-';
    final status = doc['status_ingest'] ?? 'ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppConstants.textDark,
                          height: 1.3,
                        ),
                      ),
                      if (filename.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          filename,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppConstants.borderLight),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildTag(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tahun $tahun',
                  color: AppConstants.primaryBlue,
                ),
                _buildTag(
                  icon: Icons.auto_stories_rounded,
                  label: '$halaman Halaman',
                  color: const Color(0xFF7C3AED),
                ),
                _buildTag(
                  icon: Icons.hub_rounded,
                  label: '$chunk Vektor',
                  color: AppConstants.stateSuccess,
                ),
                _buildTag(
                  icon: Icons.verified_rounded,
                  label: status == 'ready' ? 'Siap Dicari' : 'Status: $status',
                  color: AppConstants.stateInfo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentViewerScreen(
                            documentId: (doc['id'] as num?)?.toInt(),
                            documentName: nama.toString(),
                            initialPage: 1,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: AppConstants.primaryBlue,
                    ),
                    label: const Text(
                      'Baca Dokumen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: AppConstants.primaryBlue.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onAskAboutDoc(doc),
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppConstants.primaryBlue,
                    ),
                    label: const Text(
                      'Tanya ke AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          AppConstants.softBlue.withValues(alpha: 0.5),
                      side: BorderSide(
                        color: AppConstants.primaryBlue.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
