class OperatorLiveCrowdSummary {
  const OperatorLiveCrowdSummary({
    required this.attractionId,
    required this.attractionName,
    required this.maximumCapacity,
    required this.currentVisitors,
    required this.occupancyPercent,
    required this.visitorsLast15Min,
    required this.avgVisitMinutes,
    required this.crowdLevel,
  });

  final String attractionId;
  final String attractionName;

  final int maximumCapacity;
  final int currentVisitors;
  final int occupancyPercent;

  final int visitorsLast15Min;
  final int? avgVisitMinutes;

  final String crowdLevel;

  factory OperatorLiveCrowdSummary.fromJson(
      Map<String, dynamic> json,
      ) {
    return OperatorLiveCrowdSummary(
      attractionId:
      json['attraction_id']?.toString() ?? '',
      attractionName:
      json['attraction_name']?.toString() ??
          'Attraction',
      maximumCapacity:
      (json['maximum_capacity'] as num?)?.toInt() ??
          0,
      currentVisitors:
      (json['current_visitors'] as num?)?.toInt() ??
          0,
      occupancyPercent:
      (json['occupancy_percent'] as num?)?.toInt() ??
          0,
      visitorsLast15Min:
      (json['visitors_last_15_min'] as num?)
          ?.toInt() ??
          0,
      avgVisitMinutes:
      (json['avg_visit_minutes'] as num?)?.toInt(),
      crowdLevel:
      json['crowd_level']
          ?.toString()
          .toUpperCase() ??
          'LOW',
    );
  }
}

// ============================================================
// HOURLY INTERVAL
// ============================================================

class LiveCrowdInterval {
  const LiveCrowdInterval({
    required this.label,
    required this.visitors,
  });

  final String label;
  final int visitors;

  factory LiveCrowdInterval.fromJson(
      Map<String, dynamic> json,
      ) {
    return LiveCrowdInterval(
      label: json['label']?.toString() ?? '',
      visitors:
      (json['visitors'] as num?)?.toInt() ?? 0,
    );
  }
}

// ============================================================
// LIVE CROWD DETAILS
// ============================================================

class OperatorLiveCrowdDetails {
  const OperatorLiveCrowdDetails({
    required this.attractionId,
    required this.attractionName,
    required this.maximumCapacity,
    required this.currentVisitors,
    required this.occupancyPercent,
    required this.visitorsLast1Hour,
    required this.expectedVisitors,
    required this.avgVisitMinutes,
    required this.crowdLevel,
    required this.hourlyIntervals,
  });

  final String attractionId;
  final String attractionName;

  final int maximumCapacity;
  final int currentVisitors;
  final int occupancyPercent;

  final int visitorsLast1Hour;
  final int expectedVisitors;
  final int avgVisitMinutes;

  final String crowdLevel;

  final List<LiveCrowdInterval> hourlyIntervals;

  factory OperatorLiveCrowdDetails.fromJson(
      Map<String, dynamic> json,
      ) {
    final intervalRows =
        json['hourly_intervals'] as List<dynamic>? ??
            const [];

    return OperatorLiveCrowdDetails(
      attractionId:
      json['attraction_id']?.toString() ?? '',
      attractionName:
      json['attraction_name']?.toString() ??
          'Attraction',
      maximumCapacity:
      (json['maximum_capacity'] as num?)?.toInt() ??
          0,
      currentVisitors:
      (json['current_visitors'] as num?)?.toInt() ??
          0,
      occupancyPercent:
      (json['occupancy_percent'] as num?)?.toInt() ??
          0,
      visitorsLast1Hour:
      (json['visitors_last_1_hour'] as num?)
          ?.toInt() ??
          0,
      expectedVisitors:
      (json['expected_visitors'] as num?)
          ?.toInt() ??
          0,
      avgVisitMinutes:
      (json['avg_visit_minutes'] as num?)?.toInt() ??
          0,
      crowdLevel:
      json['crowd_level']
          ?.toString()
          .toUpperCase() ??
          'LOW',
      hourlyIntervals: intervalRows
          .map(
            (row) => LiveCrowdInterval.fromJson(
          Map<String, dynamic>.from(
            row as Map,
          ),
        ),
      )
          .toList(),
    );
  }
}