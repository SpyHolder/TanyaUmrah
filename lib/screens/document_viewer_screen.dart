import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../services/api_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  final int? documentId;
  final String documentName;
  final int initialPage;
  final String? section;
  final String? excerpt;

  const DocumentViewerScreen({
    super.key,
    this.documentId,
    required this.documentName,
    this.initialPage = 1,
    this.section,
    this.excerpt,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  int? _resolvedDocId;
  late int _currentPage;
  int _totalPages = 1;
  bool _isLoading = true;
  bool _showVisualPdf = true;
  String? _error;

  String _pageText = '';
  Uint8List? _pageImageBytes;
  final TransformationController _zoomController = TransformationController();

  final Map<int, Map<String, dynamic>> _pageMetaCache = {};
  final Map<int, Uint8List> _pageImageCache = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage < 1 ? 1 : widget.initialPage;
    _totalPages = _currentPage;
    _initAndLoadPage(_currentPage);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoadPage(int targetPage) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _resolvedDocId ??= await ApiService.resolveDocumentId(
        documentId: widget.documentId,
        documentName: widget.documentName,
      );

      if (_resolvedDocId == null) {
        throw const ApiException('Dokumen rujukan tidak ditemukan di server.');
      }

      final docId = _resolvedDocId!;

      // Fetch page info (text & total_pages)
      Map<String, dynamic> pageInfo;
      if (_pageMetaCache.containsKey(targetPage)) {
        pageInfo = _pageMetaCache[targetPage]!;
      } else {
        pageInfo = await ApiService.getDocumentPage(
          documentId: docId,
          page: targetPage,
        );
        _pageMetaCache[targetPage] = pageInfo;
      }

      // Fetch rendered PDF page image
      Uint8List? imgBytes;
      if (_pageImageCache.containsKey(targetPage)) {
        imgBytes = _pageImageCache[targetPage];
      } else {
        try {
          imgBytes = await ApiService.getDocumentPageImageBytes(
            documentId: docId,
            page: targetPage,
          );
          _pageImageCache[targetPage] = imgBytes;
        } catch (_) {
          // Fallback to text mode if image endpoint fails
          imgBytes = null;
        }
      }

      if (!mounted) return;
      _zoomController.value = Matrix4.identity();
      setState(() {
        _currentPage = (pageInfo['page'] as num?)?.toInt() ?? targetPage;
        _totalPages = (pageInfo['total_pages'] as num?)?.toInt() ?? _currentPage;
        _pageText = (pageInfo['text'] ?? '').toString();
        _pageImageBytes = imgBytes;
        if (imgBytes == null && _pageText.isNotEmpty) {
          _showVisualPdf = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
        if (widget.excerpt != null && widget.excerpt!.isNotEmpty) {
          _showVisualPdf = false;
        }
      });
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage || _isLoading) {
      return;
    }
    _initAndLoadPage(page);
  }

  Future<void> _showJumpPageDialog() async {
    final ctrl = TextEditingController(text: '$_currentPage');
    final target = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(
              Icons.find_in_page_rounded,
              color: AppConstants.primaryBlue,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Lompat ke Halaman',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nomor Halaman (1 - $_totalPages)',
            prefixIcon: const Icon(Icons.auto_stories_rounded, size: 18),
          ),
          onSubmitted: (val) {
            final parsed = int.tryParse(val.trim());
            Navigator.pop(ctx, parsed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Buka'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (target != null && target >= 1 && target <= _totalPages) {
      _goToPage(target);
    } else if (target != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan nomor halaman antara 1 hingga $_totalPages.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReferencedPage = _currentPage == widget.initialPage;

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Halaman $_currentPage dari $_totalPages'
              '${isReferencedPage && widget.section != null ? " • ${widget.section}" : ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_pageImageBytes != null)
            IconButton(
              tooltip: _showVisualPdf
                  ? 'Lihat Mode Teks Terbaca'
                  : 'Lihat Mode Halaman PDF Asli',
              icon: Icon(
                _showVisualPdf
                    ? Icons.article_outlined
                    : Icons.picture_as_pdf_rounded,
              ),
              onPressed: () {
                setState(() {
                  _showVisualPdf = !_showVisualPdf;
                });
              },
            ),
          IconButton(
            tooltip: 'Muat ulang halaman',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading
                ? null
                : () {
                    _pageMetaCache.remove(_currentPage);
                    _pageImageCache.remove(_currentPage);
                    _initAndLoadPage(_currentPage);
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Mode Toggle & Rujukan Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppConstants.borderLight),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: isReferencedPage
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.softBlue,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppConstants.primaryBlue.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: AppConstants.primaryBlue,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Halaman Rujukan AI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          onPressed: () => _goToPage(widget.initialPage),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.bookmark_rounded, size: 14),
                          label: Text(
                            'Ke Rujukan (Hal. ${widget.initialPage})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                // Segmented View Switcher
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeTab(
                        label: 'PDF Asli',
                        icon: Icons.picture_as_pdf_rounded,
                        selected: _showVisualPdf,
                        onTap: () {
                          setState(() {
                            _showVisualPdf = true;
                          });
                        },
                      ),
                      _buildModeTab(
                        label: 'Teks',
                        icon: Icons.notes_rounded,
                        selected: !_showVisualPdf,
                        onTap: () {
                          setState(() {
                            _showVisualPdf = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2.5),
                        SizedBox(height: 14),
                        Text(
                          'Memuat halaman dokumen resmi...',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _showVisualPdf && _pageImageBytes != null
                    ? _buildVisualPdfView(isReferencedPage)
                    : _buildTextExtractView(isReferencedPage),
          ),

          // Bottom Page Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: AppConstants.borderLight),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentPage > 1 && !_isLoading
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chevron_left_rounded, size: 18),
                          SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'Sebelumnya',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _totalPages > 1 ? _showJumpPageDialog : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.softBlue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppConstants.primaryBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            size: 13,
                            color: AppConstants.primaryBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Hal. $_currentPage / $_totalPages',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentPage < _totalPages && !_isLoading
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 9,
                        ),
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Berikutnya',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
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

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppConstants.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : AppConstants.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualPdfView(bool isReferencedPage) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _zoomController,
            minScale: 1.0,
            maxScale: 4.0,
            panEnabled: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    _pageImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'reset_pdf_zoom',
            tooltip: 'Reset Perbesaran (Zoom)',
            backgroundColor: AppConstants.primaryBlue,
            foregroundColor: Colors.white,
            onPressed: () {
              _zoomController.value = Matrix4.identity();
            },
            child: const Icon(Icons.zoom_out_map_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildTextExtractView(bool isReferencedPage) {
    final hasExcerpt =
        isReferencedPage && widget.excerpt != null && widget.excerpt!.isNotEmpty;
    final hasPageText = _pageText.trim().isNotEmpty;

    if (!hasExcerpt && !hasPageText && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: AppConstants.errorRed,
              ),
              const SizedBox(height: 12),
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
                onPressed: () => _initAndLoadPage(_currentPage),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasExcerpt) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppConstants.softGold,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppConstants.accentGold.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 18,
                        color: AppConstants.primaryDark,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Kutipan Rujukan (${widget.section ?? "Halaman $_currentPage"})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.excerpt!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppConstants.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConstants.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 17,
                      color: AppConstants.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Isi Teks Halaman $_currentPage',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textDark,
                        ),
                      ),
                    ),
                    if (hasPageText)
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _pageText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teks halaman berhasil disalin.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text(
                          'Salin',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 16, color: AppConstants.borderLight),
                SelectableText(
                  hasPageText
                      ? _pageText
                      : (widget.excerpt ??
                          'Teks halaman tidak tersedia untuk ditampilkan.'),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppConstants.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
