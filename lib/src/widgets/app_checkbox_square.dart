import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A square-styled checkbox component for tag selection
/// Uses neutral colors and square shape (different from circular folder checkboxes)
class AppCheckboxSquare extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;
  final bool enabled;

  static const double _size = 20.0;
  static const double _borderRadius = 4.0;

  const AppCheckboxSquare({
    super.key,
    required this.checked,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    Widget checkboxWidget = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: checked 
          ? colors.textSecondary 
          : colors.surface,
        border: Border.all(
          color: checked 
            ? colors.textSecondary 
            : AppColorSwatches.neutral[400]!,
          width: checked ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: checked
          ? Icon(
              Icons.check,
              size: 14,
              color: colors.surface,
            )
          : null,
    );

    if (onTap != null && enabled) {
      return GestureDetector(
        onTap: onTap,
        child: checkboxWidget,
      );
    }

    return checkboxWidget;
  }
}