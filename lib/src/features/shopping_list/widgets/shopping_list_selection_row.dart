import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_radio_button.dart';

/// A row for selecting shopping lists with radio button on the left and label on the right
/// Single-select version of FolderSelectionRow
class ShoppingListSelectionRow extends StatelessWidget {
  final String? listId; // null for default list
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool first;
  final bool last;

  const ShoppingListSelectionRow({
    super.key,
    required this.listId,
    required this.label,
    required this.selected,
    this.onTap,
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
          onTap: onTap,
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
                AppRadioButton(
                  selected: selected,
                  onTap: onTap,
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
