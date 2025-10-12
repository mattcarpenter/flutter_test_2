import 'package:flutter/cupertino.dart';
import '../../../../database/database.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../services/ingredient_parser_service.dart';

class ShoppingListItemTile extends StatelessWidget {
  final ShoppingListItemEntry item;
  final Function(bool) onBoughtToggle;
  final VoidCallback onDelete;
  final bool isFirst;
  final bool isLast;

  static final _parser = IngredientParserService();

  const ShoppingListItemTile({
    super.key,
    required this.item,
    required this.onBoughtToggle,
    required this.onDelete,
    required this.isFirst,
    required this.isLast,
  });

  /// Builds a RichText widget with bold quantities parsed from item name
  Widget _buildParsedItemText(BuildContext context) {
    final text = item.name;
    final isBought = item.bought;

    try {
      final parseResult = _parser.parse(text);

      if (parseResult.quantities.isEmpty) {
        // No quantities found, return plain text
        return Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: isBought ? TextDecoration.lineThrough : null,
            color: isBought
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.label,
          ),
        );
      }

      final children = <InlineSpan>[];
      int currentIndex = 0;

      // Build TextSpan with bold quantities, normal ingredient names
      for (final quantity in parseResult.quantities) {
        // Text before quantity (ingredient name)
        if (quantity.start > currentIndex) {
          children.add(TextSpan(
            text: text.substring(currentIndex, quantity.start),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isBought
                  ? CupertinoColors.secondaryLabel
                  : CupertinoColors.label,
            ),
          ));
        }

        // Quantity with bold formatting
        children.add(TextSpan(
          text: text.substring(quantity.start, quantity.end),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isBought
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.label,
          ),
        ));

        currentIndex = quantity.end;
      }

      // Remaining text after last quantity
      if (currentIndex < text.length) {
        children.add(TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isBought
                ? CupertinoColors.secondaryLabel
                : CupertinoColors.label,
          ),
        ));
      }

      return RichText(
        text: TextSpan(
          children: children,
          style: isBought ? const TextStyle(
            decoration: TextDecoration.lineThrough,
          ) : null,
        ),
      );
    } catch (e) {
      // Fallback to plain text if parsing fails
      return Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration: isBought ? TextDecoration.lineThrough : null,
          color: isBought
              ? CupertinoColors.secondaryLabel
              : CupertinoColors.label,
        ),
      );
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

                // Item name with parsed quantities in bold
                Expanded(
                  child: _buildParsedItemText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}