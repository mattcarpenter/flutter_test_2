import 'package:flutter/cupertino.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';

/// A row for selecting shopping lists with label on left and radio button on right
/// Matches the styling of ShoppingListItemTile for visual consistency
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
        color: AppColors.of(context).groupedListBackground,
        border: border,
        borderRadius: borderRadius,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Label on the left
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Radio button on the right (24x24 to match checkbox size)
              AppRadioButton(
                selected: selected,
                onTap: null, // Tap is handled by the row
                size: 24.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
