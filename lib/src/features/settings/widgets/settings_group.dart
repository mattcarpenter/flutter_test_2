import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

/// iOS-style grouped container for settings sections
/// Similar to AppTextFieldGroup but specifically designed for settings
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const SettingsGroup({
    super.key,
    required this.children,
    this.margin,
  });

  static const double _borderRadius = 8.0;

  Widget _buildDivider(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Row(
      children: [
        // Left inset - background color to match the group
        Container(
          width: 16,
          height: 1,
          color: colors.surface,
        ),
        // Center divider line
        Expanded(
          child: Container(
            height: 1,
            color: colors.border,
          ),
        ),
        // Right inset - background color
        Container(
          width: 16,
          height: 1,
          color: colors.surface,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    if (children.isEmpty) return const SizedBox.shrink();

    final List<Widget> childrenWithDividers = [];
    
    for (int i = 0; i < children.length; i++) {
      childrenWithDividers.add(children[i]);
      
      // Add divider between items (not after the last one)
      if (i < children.length - 1) {
        childrenWithDividers.add(_buildDivider(context));
      }
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: childrenWithDividers,
      ),
    );
  }
}