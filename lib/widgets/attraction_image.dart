import 'package:flutter/material.dart';

import '../models/attraction.dart';
import '../services/attraction_service.dart';

class AttractionImageView extends StatelessWidget {
  const AttractionImageView({
    required this.attraction,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final Attraction attraction;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = AttractionService().primaryImageUrl(attraction);
    final fallback = attraction.fallbackAssetPath;

    Widget placeholder() => ColoredBox(
      color: const Color(0xFFFFE2B5),
      child: SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: Icon(Icons.photo_outlined, color: Color(0xFF79571E)),
        ),
      ),
    );

    Widget localFallback() => fallback == null
        ? placeholder()
        : Image.asset(
            fallback,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => placeholder(),
          );

    final image = url == null
        ? localFallback()
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => localFallback(),
          );
    return ClipRRect(borderRadius: borderRadius, child: image);
  }
}
