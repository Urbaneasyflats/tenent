import 'package:flutter/material.dart';

/// Opens a full-screen, zoomable image viewer as a dialog route.
///
/// Usage:
/// ```dart
/// FullScreenImageViewer.show(context, imageUrl: '...', tag: 'proof');
/// ```
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.tag,
  });

  final String imageUrl;
  final String? tag;

  /// Convenience method to push the viewer.
  static void show(
    BuildContext context, {
    required String imageUrl,
    String? tag,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenImageViewer(
          imageUrl: imageUrl,
          tag: tag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
            SizedBox(height: 8),
            Text(
              'Unable to load image',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
      loadingBuilder: (_, Widget child, ImageChunkEvent? progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null,
            color: Colors.white70,
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: tag != null
              ? Hero(tag: tag!, child: image)
              : image,
        ),
      ),
    );
  }
}
