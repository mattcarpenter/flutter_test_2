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
    this.size = 28.0,
    this.variant = AppCircleButtonVariant.primary,
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
            ? AppColorSwatches.primary[500]! // Use base vibrant coral instead of dark
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
            ? AppColorSwatches.neutral[500]! // Medium neutral
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
