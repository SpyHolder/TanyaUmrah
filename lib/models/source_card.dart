class SourceCard {
  final String document;
  final int page;
  final String section;
  final double similarity;
  final int? documentId;
  final String? excerpt;

  SourceCard({
    required this.document,
    required this.page,
    required this.section,
    required this.similarity,
    this.documentId,
    this.excerpt,
  });

  factory SourceCard.fromJson(Map<String, dynamic> json) {
    int? parsedDocId;
    if (json['document_id'] is int) {
      parsedDocId = json['document_id'] as int;
    } else if (json['document_id'] != null) {
      parsedDocId = int.tryParse(json['document_id'].toString());
    }

    return SourceCard(
      document: json['document'] ?? 'Dokumen UMRAH',
      page: json['page'] is int
          ? json['page']
          : int.tryParse(json['page'].toString()) ?? 1,
      section: json['section'] ?? 'Umum',
      similarity: json['similarity'] is num
          ? (json['similarity'] as num).toDouble()
          : 0.0,
      documentId: parsedDocId,
      excerpt: json['excerpt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document': document,
      'page': page,
      'section': section,
      'similarity': similarity,
      if (documentId != null) 'document_id': documentId,
      if (excerpt != null && excerpt!.isNotEmpty) 'excerpt': excerpt,
    };
  }
}
