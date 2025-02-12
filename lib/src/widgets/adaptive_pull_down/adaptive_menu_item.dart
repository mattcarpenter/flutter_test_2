import 'package:flutter/widgets.dart';

class AdaptiveMenuItem {
  final String title;
  final Icon icon;
  final VoidCallback? onTap;

  AdaptiveMenuItem({
    required this.title,
    required this.icon,
    this.onTap,
  });
}
