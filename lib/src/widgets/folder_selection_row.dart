import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/app_radio_button.dart';
import '../widgets/utils/grouped_list_styling.dart';

/// A row for selecting folders with checkbox on the left and label on the right
/// Uses grouped list styling for consistent appearance across the app
class FolderSelectionRow extends StatelessWidget {
  final String folderId;
  final String label;
  final bool checked;
  final VoidCallback? onToggle;
  final bool first;
  final bool last;

  const FolderSelectionRow({
    super.key,
    required this.folderId,
    required this.label,
    required this.checked,
    this.onToggle,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Get grouped styling
    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: first,
      isLastInGroup: last,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: first,
      isLastInGroup: last,
      isDragging: false,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.input,
        border: border,
        borderRadius: borderRadius,
      ),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AppRadioButton(
                selected: checked,
                onTap: onToggle,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}