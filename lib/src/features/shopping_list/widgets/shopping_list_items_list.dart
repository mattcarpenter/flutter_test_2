import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
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

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            int currentIndex = 0;

            for (int categoryIndex = 0; categoryIndex < sortedCategories.length; categoryIndex++) {
              final category = sortedCategories[categoryIndex];
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
              for (int itemIndex = 0; itemIndex < categoryItems.length; itemIndex++) {
                final item = categoryItems[itemIndex];
                if (currentIndex == index) {
                  final isFirst = itemIndex == 0;
                  final isLast = itemIndex == categoryItems.length - 1;

                  return ShoppingListItemTile(
                    item: item,
                    isFirst: isFirst,
                    isLast: isLast,
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

              // Add spacing after each category group (except the last one)
              if (categoryIndex < sortedCategories.length - 1) {
                if (currentIndex == index) {
                  return SizedBox(height: AppSpacing.lg);
                }
                currentIndex++;
              }
            }

            return null;
          },
          childCount: _calculateChildCount(categorizedItems, sortedCategories.length),
        ),
      ),
    );
  }

  int _calculateChildCount(Map<String?, List<ShoppingListItemEntry>> categorizedItems, int categoryCount) {
    int count = 0;
    for (final entry in categorizedItems.entries) {
      count += 1; // For category header
      count += entry.value.length; // For items
    }
    // Add spacing elements between categories (categoryCount - 1)
    count += categoryCount - 1;
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
    return Padding(
      padding: EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            category,
            style: AppTypography.h5.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            '($itemCount)',
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}