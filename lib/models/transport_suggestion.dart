enum TransportMode {
  walking,
  carEhailing,
  publicTransport,
}

class TransportSuggestion {
  const TransportSuggestion({
    required this.mode,
    required this.title,
    required this.estimatedMinutesMin,
    required this.estimatedMinutesMax,
    required this.description,
    this.fareMinMyr,
    this.fareMaxMyr,
    this.recommended = false,
  });

  final TransportMode mode;
  final String title;

  final int estimatedMinutesMin;
  final int estimatedMinutesMax;

  final double? fareMinMyr;
  final double? fareMaxMyr;

  final String description;

  final bool recommended;

  String get timeLabel {
    if (estimatedMinutesMin == estimatedMinutesMax) {
      return '~$estimatedMinutesMin min';
    }

    return '$estimatedMinutesMin–$estimatedMinutesMax min';
  }

  String get fareLabel {
    if (fareMinMyr == null || fareMaxMyr == null) {
      return 'No fare';
    }

    return 'RM ${fareMinMyr!.toStringAsFixed(0)}–'
        '${fareMaxMyr!.toStringAsFixed(0)}';
  }
}