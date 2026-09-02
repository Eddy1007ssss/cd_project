import 'attraction.dart';

class RecommendationResult {
  final Attraction attraction;
  final double totalScore;
  final double interestScore;
  final double budgetScore;
  final double distanceScore;
  final double ratingScore;
  final double lowCrowdScore;
  final double slotAvailabilityScore;
  final List<String> reasons; // human-readable, e.g. "Matches your interest in Nature"

  RecommendationResult({
    required this.attraction,
    required this.totalScore,
    required this.interestScore,
    required this.budgetScore,
    required this.distanceScore,
    required this.ratingScore,
    required this.lowCrowdScore,
    required this.slotAvailabilityScore,
    required this.reasons,
  });

  // Builds the human-readable reasons list from the individual scores.
  // Called after scoring, before displaying "Why recommended?" (UC-M2-10)
  factory RecommendationResult.withGeneratedReasons({
    required Attraction attraction,
    required double totalScore,
    required double interestScore,
    required double budgetScore,
    required double distanceScore,
    required double ratingScore,
    required double lowCrowdScore,
    required double slotAvailabilityScore,
  }) {
    final reasons = <String>[];

    if (interestScore > 0.6) {
      reasons.add('Matches your interests in ${attraction.category}');
    }
    if (budgetScore > 0.6) {
      reasons.add('Fits within your budget');
    }
    if (distanceScore > 0.6) {
      reasons.add('Close to your location');
    }
    if (ratingScore > 0.7) {
      reasons.add('Highly rated by other tourists');
    }
    if (lowCrowdScore > 0.6) {
      reasons.add('Currently has low crowd levels');
    }
    if (slotAvailabilityScore > 0.5) {
      reasons.add('Slots are available');
    }

    // Fallback for UC-M2-10 alt flow: detailed scoring unavailable
    if (reasons.isEmpty) {
      reasons.add('Recommended based on general popularity');
    }

    return RecommendationResult(
      attraction: attraction,
      totalScore: totalScore,
      interestScore: interestScore,
      budgetScore: budgetScore,
      distanceScore: distanceScore,
      ratingScore: ratingScore,
      lowCrowdScore: lowCrowdScore,
      slotAvailabilityScore: slotAvailabilityScore,
      reasons: reasons,
    );
  }
}