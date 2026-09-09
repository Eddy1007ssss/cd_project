class SavedItinerary {
  const SavedItinerary({
    required this.id,
    required this.title,
    required this.date,
    required this.bookingIds,
    this.isPublished = false,
    this.endDate,
  });
  final String id;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final List<String> bookingIds;
  final bool isPublished;

  SavedItinerary copyWithPublished(bool value) => SavedItinerary(
    id: id,
    title: title,
    date: date,
    endDate: endDate,
    bookingIds: bookingIds,
    isPublished: value,
  );

  factory SavedItinerary.fromMap(Map<String, dynamic> row) {
    final items = List<Map<String, dynamic>>.from(
        (row['itinerary_items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)))
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    return SavedItinerary(id: row['id'] as String, title: row['title'] as String,
      date: DateTime.parse(row['itinerary_date'] as String),
      endDate: DateTime.tryParse(row['end_date']?.toString() ?? ''),
      bookingIds: items.map((e) => e['booking_id'] as String).toList());
  }
}
