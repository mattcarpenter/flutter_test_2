import 'package:flutter/widgets.dart';

class AdaptiveMenuItem {
  final String title;
  final Icon icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  AdaptiveMenuItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  });
}
