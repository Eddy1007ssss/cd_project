import 'package:flutter/material.dart';
import 'package:cd_project/l10n/tourflow_localization.dart';

class FullscreenNetworkImageViewer extends StatelessWidget {
  const FullscreenNetworkImageViewer({
    super.key,
    required this.imageUrl,
    required this.fileName,
    required this.heroTag,
    this.height = 190,
  });

  final String imageUrl;
  final String fileName;
  final Object heroTag;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View $fileName full screen',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _FullscreenImagePage(
                imageUrl: imageUrl,
                fileName: fileName,
                heroTag: heroTag,
              ),
            ),
          ),
          child: Stack(
            children: [
              Hero(
                tag: heroTag,
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => SizedBox(
                    height: height,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenImagePage extends StatelessWidget {
  const _FullscreenImagePage({
    required this.imageUrl,
    required this.fileName,
    required this.heroTag,
  });

  final String imageUrl;
  final String fileName;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: TourFlowText(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: .8,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(80),
          child: Center(
            child: Hero(
              tag: heroTag,
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    TourFlowText(
                      'Unable to load this image.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
