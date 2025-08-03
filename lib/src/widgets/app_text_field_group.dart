import 'package:flutter/material.dart';
import 'app_text_field.dart' show AppTextFieldVariant;
import '../theme/colors.dart';

class AppTextFieldGroup extends StatefulWidget {
  final List<Widget> children;
  final AppTextFieldVariant variant;
  final String? errorText;
  final bool enabled;

  const AppTextFieldGroup({
    Key? key,
    required this.children,
    this.variant = AppTextFieldVariant.outline,
    this.errorText,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<AppTextFieldGroup> createState() => _AppTextFieldGroupState();
}

class _AppTextFieldGroupState extends State<AppTextFieldGroup> {
  // Design tokens - matching AppTextFieldCondensed
  static const double _borderRadius = 8.0;

  Widget _buildDivider() {
    final colors = AppColors.of(context);
    final borderColor = widget.errorText != null ? colors.error : colors.border;
    
    return Row(
      children: [
        // Left inset - background color
        Container(
          width: 16,
          height: 1,
          color: widget.variant == AppTextFieldVariant.filled 
              ? colors.inputBackgroundFilled 
              : colors.surface,
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
          color: widget.variant == AppTextFieldVariant.filled 
              ? colors.inputBackgroundFilled 
              : colors.surface,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(context);
    final borderColor = widget.errorText != null ? colors.error : colors.border;
    final backgroundColor = widget.variant == AppTextFieldVariant.filled
        ? (widget.enabled ? colors.inputBackgroundFilled : colors.inputBackgroundFilled.withOpacity(0.5))
        : colors.surface;

    // Build the list of children with dividers between them
    final List<Widget> childrenWithDividers = [];
    for (int i = 0; i < widget.children.length; i++) {
      childrenWithDividers.add(widget.children[i]);
      
      // Add divider between items (not after the last item)
      if (i < widget.children.length - 1) {
        childrenWithDividers.add(_buildDivider());
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
            border: widget.variant == AppTextFieldVariant.outline
                ? Border.all(color: borderColor, width: 1.0)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: childrenWithDividers,
          ),
        ),
        
        // Error text
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: 4.0,
              left: 16.0,
              right: 16.0,
            ),
            child: Text(
              widget.errorText!,
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