import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'app_radio_button_row_condensed.dart';

/// Represents an option in a radio button group
class RadioOption<T> {
  final T value;
  final String label;

  const RadioOption({
    required this.value,
    required this.label,
  });
}

/// A grouped radio button component that follows the app's design system
/// Matches the styling and behavior of AppTextFieldGroup
class AppRadioButtonGroup<T> extends StatelessWidget {
  /// List of radio options to display
  final List<RadioOption<T>> options;
  
  /// The currently selected value
  final T selectedValue;
  
  /// Callback when a new option is selected
  final ValueChanged<T> onChanged;
  
  /// Optional error text to display
  final String? errorText;
  
  /// Whether the group is enabled
  final bool enabled;

  // Design tokens matching AppTextFieldGroup
  static const double _borderRadius = 8.0;

  const AppRadioButtonGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  Widget _buildDivider(AppColors colors) {
    final borderColor = errorText != null ? colors.error : colors.border;
    
    return Row(
      children: [
        // Left inset - background color
        Container(
          width: 16,
          height: 1,
          color: colors.surface,
        ),
        // Center divider line
        Expanded(
          child: Container(
            height: 1,
            color: borderColor,
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
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(context);
    final borderColor = errorText != null ? colors.error : colors.border;
    final backgroundColor = colors.surface;

    // Build the list of children with dividers between them
    final List<Widget> childrenWithDividers = [];
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      final isFirst = i == 0;
      final isLast = i == options.length - 1;
      final isSelected = option.value == selectedValue;
      
      childrenWithDividers.add(
        AppRadioButtonRowCondensed(
          label: option.label,
          selected: isSelected,
          onTap: enabled ? () => onChanged(option.value) : null,
          first: isFirst,
          last: isLast,
          grouped: true,
        ),
      );
      
      // Add divider between items (not after the last item)
      if (i < options.length - 1) {
        childrenWithDividers.add(_buildDivider(colors));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: childrenWithDividers,
          ),
        ),
        
        // Error text
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: 4.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Text(
              errorText!,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}