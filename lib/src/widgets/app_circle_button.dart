import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum AppCircleButtonIcon {
  plus,
  ellipsis,
  pencil,
  close,
  back,
  list,
}

enum AppCircleButtonVariant {
  primary,
  neutral,
  overlay,  // Always light, for use over images/photos
}

class AppCircleButton extends StatelessWidget {
  final AppCircleButtonIcon icon;
  final VoidCallback? onPressed;
  final double size;
  final AppCircleButtonVariant variant;

  /// Optional transition progress (0.0 to 1.0) for animating between overlay and neutral variants.
  /// When null, uses the variant directly without interpolation.
  /// When 0.0, uses overlay colors (light). When 1.0, uses neutral colors (theme-aware).
  final double? colorTransitionProgress;

  const AppCircleButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = 28.0,
    this.variant = AppCircleButtonVariant.primary,
    this.colorTransitionProgress,
  }) : super(key: key);

  IconData get _iconData {
    switch (icon) {
      case AppCircleButtonIcon.plus:
        return Icons.add;
      case AppCircleButtonIcon.ellipsis:
        return Icons.more_horiz;
      case AppCircleButtonIcon.pencil:
        return Icons.edit;
      case AppCircleButtonIcon.close:
        return Icons.close;
      case AppCircleButtonIcon.back:
        return Icons.arrow_back_rounded;
      case AppCircleButtonIcon.list:
        return Icons.format_list_bulleted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    // Adaptive colors based on variant
    Color backgroundColor;
    Color iconColor;
    Color pressedBackgroundColor;

    switch (variant) {
      case AppCircleButtonVariant.primary:
        backgroundColor = isLight
            ? AppColorSwatches.primary[150]! // Very light coral
            : AppColorSwatches.primary[900]!.withOpacity(0.3); // Dark coral with opacity
        iconColor = isLight
            ? AppColorSwatches.primary[500]! // Use base vibrant coral instead of dark
            : AppColorSwatches.primary[300]!; // Light coral
        pressedBackgroundColor = isLight
            ? AppColorSwatches.primary[200]! // Slightly darker on press
            : AppColorSwatches.primary[900]!.withOpacity(0.4);
        break;
      case AppCircleButtonVariant.neutral:
        backgroundColor = isLight
            ? AppColorSwatches.neutral[300]! // One shade darker neutral
            : AppColorSwatches.neutral[800]!.withOpacity(0.3); // Dark neutral with opacity
        iconColor = isLight
            ? AppColorSwatches.neutral[500]! // Medium neutral
            : AppColorSwatches.neutral[400]!; // Light neutral
        pressedBackgroundColor = isLight
            ? AppColorSwatches.neutral[400]! // Darker on press
            : AppColorSwatches.neutral[800]!.withOpacity(0.4);
        break;
      case AppCircleButtonVariant.overlay:
        // Always light, regardless of theme - for use over photos/images
        backgroundColor = AppColorSwatches.neutral[300]!;
        iconColor = AppColorSwatches.neutral[500]!;
        pressedBackgroundColor = AppColorSwatches.neutral[400]!;
        break;
    }

    // Handle color interpolation if colorTransitionProgress is set
    if (colorTransitionProgress != null) {
      final progress = colorTransitionProgress!.clamp(0.0, 1.0);

      // Define start colors (overlay variant - always light)
      final startBgColor = AppColorSwatches.neutral[300]!;
      final startIconColor = AppColorSwatches.neutral[500]!;

      // Define end colors (neutral variant - theme-aware)
      final endBgColor = isLight
          ? AppColorSwatches.neutral[300]!
          : AppColorSwatches.neutral[800]!.withOpacity(0.3);
      final endIconColor = isLight
          ? AppColorSwatches.neutral[500]!
          : AppColorSwatches.neutral[400]!;

      // Interpolate colors
      backgroundColor = Color.lerp(startBgColor, endBgColor, progress)!;
      iconColor = Color.lerp(startIconColor, endIconColor, progress)!;
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Center(
          child: Text(
            String.fromCharCode(_iconData.codePoint),
            style: TextStyle(
              inherit: false,
              fontSize: size * 0.6, // Icon is 60% of button size for better visibility
              fontWeight: FontWeight.w900, // Maximum boldness
              fontFamily: _iconData.fontFamily,
              package: _iconData.fontPackage,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
