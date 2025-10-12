import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../database/database.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/utils/grouped_list_styling.dart';

class ShoppingListItemTile extends StatelessWidget {
  final ShoppingListItemEntry item;
  final Function(bool) onBoughtToggle;
  final VoidCallback onDelete;
  final bool isFirst;
  final bool isLast;

  const ShoppingListItemTile({
    super.key,
    required this.item,
    required this.onBoughtToggle,
    required this.onDelete,
    required this.isFirst,
    required this.isLast,
  });

  String get _quantityText {
    final amount = item.amount;
    final unit = item.unit;

    if (amount == null) return '';

    String amountStr;
    if (amount == amount.floor()) {
      amountStr = amount.floor().toString();
    } else {
      amountStr = amount.toString();
    }

    if (unit != null && unit.isNotEmpty) {
      return 'Qty. $amountStr $unit';
    } else {
      return 'Qty. $amountStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed,
          borderRadius: borderRadius,
        ),
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.white,
          size: 20,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Delete Item'),
            content: Text('Are you sure you want to delete "${item.name}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).input,
          border: border,
          borderRadius: borderRadius,
        ),
        child: GestureDetector(
          onTap: () => onBoughtToggle(!item.bought),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.bought
                        ? AppColors.of(context).primary
                        : CupertinoColors.systemGrey3,
                      width: 2,
                    ),
                    color: item.bought
                      ? AppColors.of(context).primary
                      : AppColors.of(context).input,
                  ),
                  child: item.bought
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 16,
                        color: CupertinoColors.white,
                      )
                    : null,
                ),

                SizedBox(width: AppSpacing.md),

                // Item name
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: item.bought ? TextDecoration.lineThrough : null,
                      color: item.bought
                        ? CupertinoColors.secondaryLabel
                        : CupertinoColors.label,
                    ),
                  ),
                ),

                // Quantity (right-aligned)
                if (_quantityText.isNotEmpty) ...[
                  SizedBox(width: AppSpacing.md),
                  Text(
                    _quantityText,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.bought
                        ? CupertinoColors.tertiaryLabel
                        : CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}