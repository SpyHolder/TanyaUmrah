class CalendarEvent {
  final int id;
  final String title;
  final String? description;
  final String startDate; // YYYY-MM-DD
  final String? endDate;   // YYYY-MM-DD
  final String category;
  final bool isApproved;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.category,
    this.isApproved = true,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Kegiatan Akademik',
      description: json['description'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'],
      category: json['category'] ?? 'akademik',
      isApproved: json['is_approved'] ?? true,
    );
  }

  DateTime? get parsedStartDate => DateTime.tryParse(startDate);
  DateTime? get parsedEndDate => endDate != null ? DateTime.tryParse(endDate!) : null;
}
