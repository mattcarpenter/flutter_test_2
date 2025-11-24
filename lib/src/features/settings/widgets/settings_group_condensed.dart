import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Condensed settings group matching recipe editor form style.
/// Uses offset dividers between items (16px inset) and single border around group.
class SettingsGroupCondensed extends StatelessWidget {
  final List<Widget> children;
  final String? header;
  final String? footer;
  final EdgeInsetsGeometry? margin;

  const SettingsGroupCondensed({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin,
  });

  static const double _borderRadius = 8.0;

  Widget _buildDivider(BuildContext context) {
    final colors = AppColors.of(context);
    final borderColor = colors.borderStrong;
    final insetColor = colors.input;

    return Row(
      children: [
        // Left inset - background color
        Container(
          width: 16,
          height: 1,
          color: insetColor,
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
          color: insetColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(context);

    // Build the list of children with dividers between them
    final List<Widget> childrenWithDividers = [];
    for (int i = 0; i < children.length; i++) {
      childrenWithDividers.add(children[i]);

      // Add divider between items (not after the last item)
      if (i < children.length - 1) {
        childrenWithDividers.add(_buildDivider(context));
      }
    }

    return Padding(
      padding: margin ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional header
          if (header != null) ...[
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                  letterSpacing: -0.08,
                ),
              ),
            ),
          ],

          // Container with border and rounded corners
          Container(
            decoration: BoxDecoration(
              color: colors.input,
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(color: colors.border, width: 1.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: childrenWithDividers,
            ),
          ),

          // Optional footer
          if (footer != null) ...[
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
              ),
              child: Text(
                footer!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
