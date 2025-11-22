import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// iOS-style grouped container for settings sections
/// Handles header/footer text - individual rows handle their own borders via GroupedListStyling
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final String? header;
  final String? footer;

  const SettingsGroup({
    super.key,
    required this.children,
    this.margin,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: margin ?? EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          // Children (each row handles its own border/radius)
          ...children,
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
