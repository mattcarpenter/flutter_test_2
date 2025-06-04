import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart'; // For StockStatus enum
import '../../../providers/pantry_provider.dart';
import '../views/add_pantry_item_modal.dart';
import '../views/update_pantry_item_modal.dart';
import 'stock_status_segmented_control.dart';

class PantryItemList extends ConsumerWidget {
  final List<PantryItemEntry> pantryItems;
  final bool showCategoryHeaders;

  const PantryItemList({
    super.key,
    required this.pantryItems,
    this.showCategoryHeaders = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> children = [];

    if (showCategoryHeaders) {
      // Group items by category and show headers
      final Map<String, List<PantryItemEntry>> groupedItems = {};
      
      for (final item in pantryItems) {
        final category = item.category ?? 'Other';
        if (!groupedItems.containsKey(category)) {
          groupedItems[category] = [];
        }
        groupedItems[category]!.add(item);
      }

      // Sort categories (put "Other" last)
      final sortedCategories = groupedItems.keys.toList()
        ..sort((a, b) {
          if (a == 'Other' && b != 'Other') return 1;
          if (b == 'Other' && a != 'Other') return -1;
          return a.compareTo(b);
        });

      // Sort items within each category
      for (final category in sortedCategories) {
        groupedItems[category]!.sort((a, b) => a.name.compareTo(b.name));
      }

      // Build list with category headers
      for (final category in sortedCategories) {
        final items = groupedItems[category]!;
        
        // Add category header
        children.add(_buildCategoryHeader(context, category));
        
        // Add items in this category
        for (final item in items) {
          children.add(_buildPantryItemTile(context, ref, item));
        }
      }
    } else {
      // Flat list without category headers - items are already sorted by the caller
      for (final item in pantryItems) {
        children.add(_buildPantryItemTile(context, ref, item));
      }
    }

    // Add the "Add Item" button at the end
    children.add(_buildAddItemButton(context));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String category) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color!;
    final backgroundColor = isDarkMode
        ? Colors.grey.shade900
        : Colors.grey.shade100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: backgroundColor,
      child: Text(
        category,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPantryItemTile(BuildContext context, WidgetRef ref, PantryItemEntry item) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color!;
    final dividerColor = isDarkMode
        ? Colors.grey.shade800
        : Colors.grey.shade300;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Edit this pantry item
            showUpdatePantryItemModal(
              context,
              pantryItem: item,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Pantry item name with truncation
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                // Stock status segmented controller
                StockStatusSegmentedControl(
                  value: item.stockStatus,
                  onChanged: (StockStatus value) {
                    ref.read(pantryNotifierProvider.notifier).updateItem(
                      id: item.id,
                      stockStatus: value,
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Edit icon
                Icon(
                  CupertinoIcons.pencil,
                  color: textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: dividerColor,
        ),
      ],
    );
  }

  Widget _buildAddItemButton(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color!;
    final borderColor = isDarkMode
        ? Colors.grey.shade600
        : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () {
            showAddPantryItemModal(context);
          },
          icon: Icon(
            CupertinoIcons.add,
            color: textColor,
            size: 18,
          ),
          label: Text(
            'Add Item',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide(color: borderColor, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }

}
