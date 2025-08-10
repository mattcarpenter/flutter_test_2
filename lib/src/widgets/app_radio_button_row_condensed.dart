import 'package:flutter/material.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';
import 'app_radio_button.dart';

/// A condensed radio button row with label on left and radio button on right
/// Matches the styling and behavior of AppTextFieldCondensed
class AppRadioButtonRowCondensed extends StatelessWidget {
  /// The text label to display
  final String label;
  
  /// Whether this option is selected
  final bool selected;
  
  /// Callback when the row is tapped
  final VoidCallback? onTap;
  
  /// Whether this is the first item in a group (affects border radius)
  final bool first;
  
  /// Whether this is the last item in a group (affects border radius)
  final bool last;
  
  /// Whether this row is part of a grouped layout
  final bool grouped;

  // Design tokens matching AppTextFieldCondensed
  static const double _condensedHeight = 48.0;
  static const double _borderRadius = 8.0;
  static const double _horizontalPadding = 16.0;

  const AppRadioButtonRowCondensed({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.first = true,
    this.last = true,
    this.grouped = false,
  });

  BorderRadius _getBorderRadius() {
    if (first && last) {
      return BorderRadius.circular(_borderRadius);
    } else if (first && !last) {
      return const BorderRadius.only(
        topLeft: Radius.circular(_borderRadius),
        topRight: Radius.circular(_borderRadius),
      );
    } else if (!first && last) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(_borderRadius),
        bottomRight: Radius.circular(_borderRadius),
      );
    } else {
      return BorderRadius.zero;
    }
  }

  Border _getBorder(Color borderColor) {
    const borderWidth = 1.0;

    if (first) {
      return Border.all(
        color: borderColor,
        width: borderWidth,
      );
    } else {
      // Non-first items omit top border to connect seamlessly
      return Border(
        left: BorderSide(color: borderColor, width: borderWidth),
        right: BorderSide(color: borderColor, width: borderWidth),
        bottom: BorderSide(color: borderColor, width: borderWidth),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    // When grouped, render without container decoration
    if (grouped) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: _condensedHeight,
          color: Colors.transparent, // Needed for tap detection
          child: Row(
            children: [
              const SizedBox(width: _horizontalPadding),
              
              // Label on the left
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.fieldLabel.copyWith(
                    color: colors.inputLabel,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Radio button on the right (no onTap - handled by row)
              AppRadioButton(
                selected: selected,
                onTap: null,
              ),
              
              const SizedBox(width: _horizontalPadding),
            ],
          ),
        ),
      );
    }

    // Standalone version with full decoration
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _condensedHeight,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: _getBorderRadius(),
          border: _getBorder(colors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: _horizontalPadding),
            
            // Label on the left
            Expanded(
              child: Text(
                label,
                style: AppTypography.fieldLabel.copyWith(
                  color: colors.inputLabel,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Radio button on the right (no onTap - handled by row)
            AppRadioButton(
              selected: selected,
              onTap: null,
            ),
            
            const SizedBox(width: _horizontalPadding),
          ],
        ),
      ),
    );
  }
}