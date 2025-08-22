import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'app_checkbox_row_condensed.dart';

/// Represents an option in a checkbox group
class CheckboxOption<T> {
  final T value;
  final String label;

  const CheckboxOption({
    required this.value,
    required this.label,
  });
}

/// A grouped checkbox component that follows the app's design system
/// Similar to AppRadioButtonGroup but supports multiple selections
class AppCheckboxGroup<T> extends StatelessWidget {
  /// List of checkbox options to display
  final List<CheckboxOption<T>> options;
  
  /// The currently selected values
  final Set<T> selectedValues;
  
  /// Callback when selections change
  final ValueChanged<Set<T>> onChanged;
  
  /// Optional error text to display
  final String? errorText;
  
  /// Whether the group is enabled
  final bool enabled;

  // Design tokens matching AppRadioButtonGroup
  static const double _borderRadius = 8.0;

  const AppCheckboxGroup({
    super.key,
    required this.options,
    required this.selectedValues,
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
      final isChecked = selectedValues.contains(option.value);
      
      childrenWithDividers.add(
        AppCheckboxRowCondensed(
          label: option.label,
          checked: isChecked,
          onTap: enabled ? () {
            final newSelection = Set<T>.from(selectedValues);
            if (isChecked) {
              newSelection.remove(option.value);
            } else {
              newSelection.add(option.value);
            }
            onChanged(newSelection);
          } : null,
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