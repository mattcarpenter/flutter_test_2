import 'package:flutter/cupertino.dart';
import '../../../../database/models/pantry_items.dart';
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
        color: CupertinoColors.systemGrey6.resolveFrom(context),
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
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isChecked
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey3,
                    width: 2,
                  ),
                  color: isChecked
                      ? CupertinoColors.activeBlue
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
                          _buildTag(
                            'New item',
                            CupertinoColors.activeGreen,
                            context,
                          ),
                        ] else ...[
                          _buildTag(
                            _getStockStatusText(item.matchingPantryItem!.stockStatus),
                            _getStockStatusColor(item.matchingPantryItem!.stockStatus),
                            context,
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.arrow_right,
                            size: 16,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          const SizedBox(width: 8),
                          _buildTag(
                            'In stock',
                            CupertinoColors.activeGreen,
                            context,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quantity if available
              if (item.shoppingListItem.amount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatQuantity(item.shoppingListItem.amount!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _getStockStatusText(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return 'Out of stock';
      case StockStatus.lowStock:
        return 'Low stock';
      case StockStatus.inStock:
        return 'In stock';
    }
  }

  Color _getStockStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return CupertinoColors.destructiveRed;
      case StockStatus.lowStock:
        return CupertinoColors.systemYellow;
      case StockStatus.inStock:
        return CupertinoColors.activeGreen;
    }
  }

  String _formatQuantity(double amount) {
    if (amount == amount.floor()) {
      return amount.floor().toString();
    }
    return amount.toString();
  }
}