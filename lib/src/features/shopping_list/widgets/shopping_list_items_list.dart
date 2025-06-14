import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../providers/shopping_list_provider.dart';
import 'shopping_list_item_tile.dart';

class ShoppingListItemsList extends ConsumerWidget {
  final List<ShoppingListItemEntry> items;

  const ShoppingListItemsList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group items by category
    final Map<String?, List<ShoppingListItemEntry>> categorizedItems = {};
    
    for (final item in items) {
      final category = item.category ?? 'Other';
      categorizedItems.putIfAbsent(category, () => []).add(item);
    }

    // Sort categories alphabetically, but put "Other" last
    final sortedCategories = categorizedItems.keys.toList()
      ..sort((a, b) {
        if (a == 'Other') return 1;
        if (b == 'Other') return -1;
        return (a ?? '').compareTo(b ?? '');
      });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          int currentIndex = 0;
          
          for (final category in sortedCategories) {
            final categoryItems = categorizedItems[category]!;
            
            // Category header
            if (currentIndex == index) {
              return _CategoryHeader(
                category: category ?? 'Other',
                itemCount: categoryItems.length,
              );
            }
            currentIndex++;
            
            // Category items
            for (final item in categoryItems) {
              if (currentIndex == index) {
                return ShoppingListItemTile(
                  item: item,
                  onBoughtToggle: (bought) async {
                    final currentListId = ref.read(currentShoppingListProvider);
                    await ref.read(shoppingListItemsProvider(currentListId).notifier)
                        .markBought(item.id, bought: bought);
                  },
                  onDelete: () async {
                    final currentListId = ref.read(currentShoppingListProvider);
                    await ref.read(shoppingListItemsProvider(currentListId).notifier)
                        .deleteItem(item.id);
                  },
                );
              }
              currentIndex++;
            }
          }
          
          return null;
        },
        childCount: _calculateChildCount(categorizedItems),
      ),
    );
  }

  int _calculateChildCount(Map<String?, List<ShoppingListItemEntry>> categorizedItems) {
    int count = 0;
    for (final entry in categorizedItems.entries) {
      count += 1; // For category header
      count += entry.value.length; // For items
    }
    return count;
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  final int itemCount;

  const _CategoryHeader({
    required this.category,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($itemCount)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}