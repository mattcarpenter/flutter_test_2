import 'package:flutter/cupertino.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../theme/colors.dart';
import '../../../widgets/stock_chip.dart';
import '../../../services/ingredient_parser_service.dart';
import '../models/pantry_update_models.dart';

class PantryUpdateItemTile extends StatelessWidget {
  final PantryUpdateItem item;
  final bool isChecked;
  final ValueChanged<bool> onCheckedChanged;

  static final _parser = IngredientParserService();

  const PantryUpdateItemTile({
    super.key,
    required this.item,
    required this.isChecked,
    required this.onCheckedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = item.isNewItem;

    // Parse name to extract clean ingredient name (without quantities)
    final parseResult = _parser.parse(item.shoppingListItem.name);
    final displayName = parseResult.cleanName.isNotEmpty
        ? parseResult.cleanName
        : item.shoppingListItem.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.of(context).input,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: () => onCheckedChanged(!isChecked),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isChecked
                        ? AppColors.of(context).primary
                        : CupertinoColors.systemGrey3,
                    width: 2,
                  ),
                  color: isChecked
                      ? AppColors.of(context).primary
                      : CupertinoColors.transparent,
                ),
                child: isChecked
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 16,
                        color: CupertinoColors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Item name (truncates with ellipsis if too long)
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              const SizedBox(width: 12),

              // Stock status chips (right-aligned)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNew) ...[
                    StockChip(isNewItem: true),
                  ] else ...[
                    StockChip(status: item.matchingPantryItem!.stockStatus),
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.arrow_right,
                      size: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 8),
                    StockChip(status: StockStatus.inStock),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}