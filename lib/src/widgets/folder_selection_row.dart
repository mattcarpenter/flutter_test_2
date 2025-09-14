import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/app_checkbox_square.dart';

/// A row for selecting folders with checkbox on the left and label on the right
/// Matches the style of TagSelectionRow but simplified for folders
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

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: first ? const Radius.circular(8) : Radius.zero,
          bottom: last ? const Radius.circular(8) : Radius.zero,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.vertical(
            top: first ? const Radius.circular(8) : Radius.zero,
            bottom: last ? const Radius.circular(8) : Radius.zero,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                AppCheckboxSquare(
                  checked: checked,
                  onTap: onToggle,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}