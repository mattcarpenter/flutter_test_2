import 'package:flutter/cupertino.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';

/// A row for selecting shopping lists with label on left and radio button on right
/// Matches the styling of ShoppingListItemTile for visual consistency
class ShoppingListSelectionRow extends StatelessWidget {
  final String? listId; // null for default list
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool first;
  final bool last;

  /// Whether to show the radio button (selection mode) or menu button (manage mode)
  final bool showRadio;

  /// Called when delete is tapped from the menu (only used when showRadio is false)
  final VoidCallback? onDelete;

  const ShoppingListSelectionRow({
    super.key,
    required this.listId,
    required this.label,
    required this.selected,
    this.onTap,
    this.first = false,
    this.last = false,
    this.showRadio = true,
    this.onDelete,
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

              // Radio button or menu button on the right
              if (showRadio)
                AppRadioButton(
                  selected: selected,
                  onTap: null, // Tap is handled by the row
                  size: 24.0,
                )
              else if (onDelete != null)
                AdaptivePullDownButton(
                  items: [
                    AdaptiveMenuItem(
                      title: 'Delete',
                      icon: const Icon(CupertinoIcons.trash),
                      isDestructive: true,
                      onTap: onDelete,
                    ),
                  ],
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 20,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
