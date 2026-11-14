class SourceCard {
  final String document;
  final int page;
  final String section;
  final double similarity;

  SourceCard({
    required this.document,
    required this.page,
    required this.section,
    required this.similarity,
  });

  factory SourceCard.fromJson(Map<String, dynamic> json) {
    return SourceCard(
      document: json['document'] ?? 'Dokumen UMRAH',
      page: json['page'] is int ? json['page'] : int.tryParse(json['page'].toString()) ?? 1,
      section: json['section'] ?? 'Umum',
      similarity: json['similarity'] is num ? (json['similarity'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document': document,
      'page': page,
      'section': section,
      'similarity': similarity,
    };
  }
}
