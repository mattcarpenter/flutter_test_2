import 'package:flutter/material.dart';

class AdaptiveMenuItem {
  final String title;
  final Icon icon;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isDivider;

  AdaptiveMenuItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  }) : isDivider = false;

  // Factory constructor for creating a divider
  AdaptiveMenuItem.divider()
      : title = '',
        icon = const Icon(Icons.remove), // Dummy icon
        onTap = null,
        isDestructive = false,
        isDivider = true;
}
