class VisitOption {
  const VisitOption({
    required this.bookingId,
    required this.bookingCode,
    required this.attractionId,
    required this.attractionName,
    required this.startsAt,
  });

  final String bookingId;
  final String bookingCode;
  final String attractionId;
  final String attractionName;
  final DateTime startsAt;

  factory VisitOption.fromMap(Map<String, dynamic> map) {
    final slot = (map['slot'] as Map).cast<String, dynamic>();
    final attraction = (slot['attraction'] as Map).cast<String, dynamic>();
    return VisitOption(
      bookingId: map['id'] as String,
      bookingCode: map['booking_code'] as String,
      attractionId: attraction['id'] as String,
      attractionName: attraction['name'] as String,
      startsAt: DateTime.parse(slot['starts_at'] as String).toLocal(),
    );
  }
}

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.bookingCode,
    required this.attractionName,
    required this.overallRating,
    required this.crowdComfort,
    required this.tags,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String bookingCode;
  final String attractionName;
  final int overallRating;
  final int crowdComfort;
  final List<String> tags;
  final String comment;
  final DateTime createdAt;

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) => FeedbackEntry(
    id: map['id'] as String,
    bookingCode: ((map['booking'] as Map)['booking_code'] as String),
    attractionName: ((map['attraction'] as Map)['name'] as String),
    overallRating: map['overall_rating'] as int,
    crowdComfort: map['crowd_comfort'] as int,
    tags: List<String>.from(map['tags'] as List? ?? const []),
    comment: map['comment'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  );
}

class IssueReport {
  const IssueReport({
    required this.id,
    required this.code,
    required this.category,
    required this.location,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.attractionName,
    this.resolutionNote,
  });

  final String id;
  final String code;
  final String category;
  final String location;
  final String description;
  final String priority;
  final String status;
  final DateTime createdAt;
  final String? attractionName;
  final String? resolutionNote;

  factory IssueReport.fromMap(Map<String, dynamic> map) => IssueReport(
    id: map['id'] as String,
    code: map['report_code'] as String,
    category: map['category'] as String,
    location: map['location_note'] as String,
    description: map['description'] as String,
    priority: map['priority'] as String,
    status: map['status'] as String,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    attractionName: (map['attraction'] as Map?)?['name'] as String?,
    resolutionNote: map['resolution_note'] as String?,
  );
}

class CrowdSnapshot {
  const CrowdSnapshot({
    required this.attractionName,
    required this.currentVisitors,
    required this.maximumCapacity,
    required this.recentArrivals,
  });

  final String attractionName;
  final int currentVisitors;
  final int maximumCapacity;
  final int recentArrivals;
  int get availableCapacity =>
      (maximumCapacity - currentVisitors).clamp(0, maximumCapacity);
  double get occupancy =>
      maximumCapacity == 0 ? 0 : currentVisitors / maximumCapacity;
}

enum StaffBookingStatus {
  valid,
  invalid,
  alreadyUsed,
  wrongAttraction,
  wrongSlot,
  checkedIn;

  factory StaffBookingStatus.fromWireValue(String value) => switch (value) {
    'valid' => StaffBookingStatus.valid,
    'already_used' => StaffBookingStatus.alreadyUsed,
    'wrong_attraction' => StaffBookingStatus.wrongAttraction,
    'wrong_slot' => StaffBookingStatus.wrongSlot,
    'checked_in' => StaffBookingStatus.checkedIn,
    _ => StaffBookingStatus.invalid,
  };

  String get label => switch (this) {
    StaffBookingStatus.valid => 'Valid',
    StaffBookingStatus.invalid => 'Invalid',
    StaffBookingStatus.alreadyUsed => 'Already Used',
    StaffBookingStatus.wrongAttraction => 'Wrong Attraction',
    StaffBookingStatus.wrongSlot => 'Wrong Slot',
    StaffBookingStatus.checkedIn => 'Checked In',
  };
}

class StaffBookingVerification {
  const StaffBookingVerification({
    required this.status,
    this.bookingId,
    this.bookingCode,
    this.visitorName,
    this.visitorCount,
    this.attractionName,
    this.startsAt,
    this.endsAt,
    this.currentVisitorCount,
  });

  final StaffBookingStatus status;
  final String? bookingId;
  final String? bookingCode;
  final String? visitorName;
  final int? visitorCount;
  final String? attractionName;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? currentVisitorCount;

  bool get canCheckIn => status == StaffBookingStatus.valid;
  bool get hasBookingDetails => bookingId != null;

  factory StaffBookingVerification.invalid([String? bookingCode]) =>
      StaffBookingVerification(
        status: StaffBookingStatus.invalid,
        bookingCode: bookingCode,
      );

  factory StaffBookingVerification.fromMap(Map<String, dynamic> map) =>
      StaffBookingVerification(
        status: StaffBookingStatus.fromWireValue(
          map['status'] as String? ?? 'invalid',
        ),
        bookingId: map['booking_id'] as String?,
        bookingCode: map['booking_code'] as String?,
        visitorName: map['visitor_name'] as String?,
        visitorCount: (map['visitor_count'] as num?)?.toInt(),
        attractionName: map['attraction_name'] as String?,
        startsAt: _optionalDateTime(map['starts_at']),
        endsAt: _optionalDateTime(map['ends_at']),
        currentVisitorCount: (map['current_visitor_count'] as num?)?.toInt(),
      );
}

DateTime? _optionalDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.parse(value).toLocal();
}
