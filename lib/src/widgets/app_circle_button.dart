import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum AppCircleButtonIcon {
  plus,
  ellipsis,
  pencil,
  close,
}

enum AppCircleButtonVariant {
  primary,
  neutral,
}

class AppCircleButton extends StatelessWidget {
  final AppCircleButtonIcon icon;
  final VoidCallback? onPressed;
  final double size;
  final AppCircleButtonVariant variant;

  const AppCircleButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = 26.0,
    this.variant = AppCircleButtonVariant.primary,
  }) : super(key: key);

  IconData get _iconData {
    switch (icon) {
      case AppCircleButtonIcon.plus:
        return CupertinoIcons.plus;
      case AppCircleButtonIcon.ellipsis:
        return CupertinoIcons.ellipsis;
      case AppCircleButtonIcon.pencil:
        return CupertinoIcons.pencil;
      case AppCircleButtonIcon.close:
        return CupertinoIcons.clear;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    // Adaptive colors based on variant
    final Color backgroundColor;
    final Color iconColor;
    final Color pressedBackgroundColor;

    switch (variant) {
      case AppCircleButtonVariant.primary:
        backgroundColor = isLight
            ? AppColorSwatches.primary[150]! // Very light coral
            : AppColorSwatches.primary[900]!.withOpacity(0.3); // Dark coral with opacity
        iconColor = isLight
            ? AppColorSwatches.primary[600]! // Use base vibrant coral instead of dark
            : AppColorSwatches.primary[300]!; // Light coral
        pressedBackgroundColor = isLight
            ? AppColorSwatches.primary[200]! // Slightly darker on press
            : AppColorSwatches.primary[900]!.withOpacity(0.4);
        break;
      case AppCircleButtonVariant.neutral:
        backgroundColor = isLight
            ? AppColorSwatches.neutral[250]! // Light neutral
            : AppColorSwatches.neutral[800]!.withOpacity(0.3); // Dark neutral with opacity
        iconColor = isLight
            ? AppColorSwatches.neutral[600]! // Medium neutral
            : AppColorSwatches.neutral[400]!; // Light neutral
        pressedBackgroundColor = isLight
            ? AppColorSwatches.neutral[300]! // Slightly darker on press
            : AppColorSwatches.neutral[800]!.withOpacity(0.4);
        break;
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
          child: Icon(
            _iconData,
            size: size * 0.55, // Icon is 55% of button size for bolder appearance
            color: iconColor,
            weight: 800, // Make icons bolder
          ),
        ),
      ),
    );
  }
}
