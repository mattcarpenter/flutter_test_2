import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Size constants for star rating widget
class StarRatingSize {
  static const double small = 16.0;
  static const double medium = 24.0;
  static const double large = 32.0;
}

/// A reusable star rating widget that can be used in both interactive and display modes
class StarRating extends StatelessWidget {
  /// Current rating value (0-5, where 0 or null means no rating)
  final int? rating;

  /// Callback when rating changes (null = non-interactive display mode)
  final ValueChanged<int>? onRatingChanged;

  /// Size of star icons
  final double size;

  /// Maximum rating (default 5)
  final int maxRating;

  /// Spacing between stars
  final double spacing;

  const StarRating({
    super.key,
    this.rating,
    this.onRatingChanged,
    this.size = StarRatingSize.medium,
    this.maxRating = 5,
    this.spacing = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currentRating = rating ?? 0;
    final isInteractive = onRatingChanged != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= currentRating;

        final starIcon = Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: isFilled
            ? colors.textPrimary
            : AppColorSwatches.neutral[400],
          weight: isFilled ? null : 300,
        );

        if (isInteractive) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // If tapping the same star, clear the rating (set to 0)
              // Otherwise, set to the tapped star's value
              if (currentRating == starValue) {
                onRatingChanged!(0);
              } else {
                onRatingChanged!(starValue);
              }
            },
            child: Padding(
              padding: EdgeInsets.only(
                right: index < maxRating - 1 ? spacing : 0,
              ),
              child: starIcon,
            ),
          );
        } else {
          // Display-only mode
          return Padding(
            padding: EdgeInsets.only(
              right: index < maxRating - 1 ? spacing : 0,
            ),
            child: starIcon,
          );
        }
      }),
    );
  }
}
