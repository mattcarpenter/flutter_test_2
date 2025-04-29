import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../database/database.dart';
import '../views/add_pantry_item_modal.dart';

class PantryItemList extends StatelessWidget {
  final List<PantryItemEntry> pantryItems;

  const PantryItemList({
    Key? key,
    required this.pantryItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedItems = List.of(pantryItems)
      ..sort((a, b) => a.name.compareTo(b.name));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = sortedItems[index];
          return _buildPantryItemTile(context, item);
        },
        childCount: sortedItems.length,
      ),
    );
  }

  Widget _buildPantryItemTile(BuildContext context, PantryItemEntry item) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color!;
    final dividerColor = isDarkMode 
        ? Colors.grey.shade800 
        : Colors.grey.shade300;

    // Format quantity and unit information if available
    String? quantityText;
    if (item.quantity != null && item.unit != null) {
      quantityText = '${item.quantity} ${item.unit}';
    } else if (item.quantity != null) {
      quantityText = '${item.quantity}';
    } else if (item.unit != null) {
      quantityText = '${item.unit}';
    }

    return Column(
      children: [
        CupertinoListTile(
          title: Text(
            item.name,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: quantityText != null 
              ? Text(
                  quantityText,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // In stock indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.inStock ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              // Price information if available
              if (item.price != null)
                Text(
                  '\$${item.price!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                color: textColor.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
          onTap: () {
            // Edit this pantry item
            showPantryItemEditorModal(
              context,
              pantryItem: item,
              isEditing: true,
            );
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: dividerColor,
        ),
      ],
    );
  }
}