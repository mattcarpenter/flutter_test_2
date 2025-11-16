import 'package:flutter/material.dart';

/// A widget that displays the standard recipe placeholder image.
///
/// This provides a consistent placeholder across the app when recipe images
/// are not available. Uses the no-image-thumb.jpg asset with configurable
/// sizing and border radius.
class RecipePlaceholderImage extends StatelessWidget {
  /// The width of the placeholder container
  final double? width;

  /// The height of the placeholder container
  final double? height;

  /// The border radius for rounded corners
  final BorderRadius? borderRadius;

  /// How the placeholder image should be inscribed into the container
  final BoxFit fit;

  const RecipePlaceholderImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: Image.asset(
        'assets/images/no-image-thumb.jpg',
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
