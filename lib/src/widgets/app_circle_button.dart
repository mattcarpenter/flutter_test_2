import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum AppCircleButtonIcon {
  plus,
  ellipsis,
}

class AppCircleButton extends StatelessWidget {
  final AppCircleButtonIcon icon;
  final VoidCallback? onPressed;
  final double size;

  const AppCircleButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size = 32.0,
  }) : super(key: key);

  IconData get _iconData {
    switch (icon) {
      case AppCircleButtonIcon.plus:
        return CupertinoIcons.plus;
      case AppCircleButtonIcon.ellipsis:
        return CupertinoIcons.ellipsis;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    
    // Adaptive colors based on theme
    final backgroundColor = isLight
        ? AppColorSwatches.primary[100]! // Very light coral
        : AppColorSwatches.primary[900]!.withOpacity(0.3); // Dark coral with opacity
    
    final iconColor = isLight
        ? AppColorSwatches.primary[500]! // Use base vibrant coral instead of dark
        : AppColorSwatches.primary[300]!; // Light coral
    
    // Pressed state colors
    final pressedBackgroundColor = isLight
        ? AppColorSwatches.primary[200]! // Slightly darker on press
        : AppColorSwatches.primary[900]!.withOpacity(0.4);

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
            size: size * 0.5, // Icon is 50% of button size
            color: iconColor,
          ),
        ),
      ),
    );
  }
}