import 'dart:math' as math;

import '../models/transport_suggestion.dart';

class TransportSuggestionService {
  const TransportSuggestionService();

  List<TransportSuggestion> suggestionsForDistance(
      double? distanceKm,
      ) {
    if (distanceKm == null ||
        distanceKm.isNaN ||
        distanceKm < 0) {
      return const [];
    }

    final suggestions = <TransportSuggestion>[];

    // ============================================================
    // WALKING
    // ============================================================

    if (distanceKm <= 5) {
      final baseMinutes =
      (distanceKm / 4.8 * 60).ceil();

      final maximumMinutes =
      math.max(
        baseMinutes + 5,
        (baseMinutes * 1.20).ceil(),
      );

      suggestions.add(
        TransportSuggestion(
          mode: TransportMode.walking,
          title: 'Walking',
          estimatedMinutesMin:
          math.max(1, baseMinutes),
          estimatedMinutesMax:
          math.max(5, maximumMinutes),
          description: distanceKm <= 1.5
              ? 'Suitable for a short-distance trip.'
              : 'Possible if you prefer walking and the route is suitable.',
          recommended:
          distanceKm <= 1.5,
        ),
      );
    }

    // ============================================================
    // CAR / E-HAILING
    // ============================================================

    final carBaseMinutes =
    (distanceKm / 28 * 60).ceil();

    final carMinimum =
    math.max(
      5,
      carBaseMinutes + 5,
    );

    final carMaximum =
    math.max(
      carMinimum + 5,
      (carBaseMinutes * 1.35).ceil() + 10,
    );

    final fareMinimum =
    math.max(
      6.0,
      4 + (distanceKm * 1.2),
    );

    final fareMaximum =
    math.max(
      fareMinimum + 3,
      7 + (distanceKm * 2),
    );

    suggestions.add(
      TransportSuggestion(
        mode: TransportMode.carEhailing,
        title: 'Car / E-hailing',
        estimatedMinutesMin:
        carMinimum,
        estimatedMinutesMax:
        carMaximum,
        fareMinMyr:
        fareMinimum,
        fareMaxMyr:
        fareMaximum,
        description:
        'A practical option for direct travel to the attraction.',
        recommended:
        distanceKm > 1.5,
      ),
    );

    // ============================================================
    // PUBLIC TRANSPORT
    // ============================================================

    final publicBaseMinutes =
    (distanceKm / 18 * 60).ceil();

    final publicMinimum =
    math.max(
      15,
      publicBaseMinutes + 15,
    );

    final publicMaximum =
        publicMinimum + 20;

    final publicFareMaximum =
    math.min(
      12.0,
      math.max(
        4.0,
        3 + (distanceKm * .3),
      ),
    );

    suggestions.add(
      TransportSuggestion(
        mode:
        TransportMode.publicTransport,
        title: 'Public Transport',
        estimatedMinutesMin:
        publicMinimum,
        estimatedMinutesMax:
        publicMaximum,
        fareMinMyr: 2,
        fareMaxMyr:
        publicFareMaximum,
        description:
        'A budget-friendly option when public transport is available.',
      ),
    );

    // Recommended first.
    suggestions.sort(
          (a, b) {
        if (a.recommended &&
            !b.recommended) {
          return -1;
        }

        if (!a.recommended &&
            b.recommended) {
          return 1;
        }

        return a.estimatedMinutesMin
            .compareTo(
          b.estimatedMinutesMin,
        );
      },
    );

    return suggestions;
  }

  TransportSuggestion? recommendedForDistance(
      double? distanceKm,
      ) {
    final suggestions =
    suggestionsForDistance(
      distanceKm,
    );

    if (suggestions.isEmpty) {
      return null;
    }

    for (final suggestion
    in suggestions) {
      if (suggestion.recommended) {
        return suggestion;
      }
    }

    return suggestions.first;
  }
}