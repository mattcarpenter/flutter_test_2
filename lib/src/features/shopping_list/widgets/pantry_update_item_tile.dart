import 'package:flutter/cupertino.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../theme/colors.dart';
import '../../../widgets/stock_status_chip.dart';
import '../models/pantry_update_models.dart';

class PantryUpdateItemTile extends StatelessWidget {
  final PantryUpdateItem item;
  final bool isChecked;
  final ValueChanged<bool> onCheckedChanged;

  const PantryUpdateItemTile({
    super.key,
    required this.item,
    required this.isChecked,
    required this.onCheckedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = item.isNewItem;
    
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
              
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.shoppingListItem.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isNew) ...[
                          StockStatusChip(isNewItem: true),
                        ] else ...[
                          StockStatusChip(status: item.matchingPantryItem!.stockStatus),
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.arrow_right,
                            size: 16,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          const SizedBox(width: 8),
                          StockStatusChip(status: StockStatus.inStock),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}