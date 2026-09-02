import 'attraction.dart';

class RecommendationResult {
  const RecommendationResult({
    required this.attraction,
    required this.score,
    required this.reasons,
    this.recommendedSlot,
  });

  final Attraction attraction;
  final double score;
  final List<String> reasons;
  final AttractionSlotPreview? recommendedSlot;

  int get percentage => (score.clamp(0, 100)).round();
}
