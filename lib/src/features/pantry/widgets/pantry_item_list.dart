import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/pantry_selection_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../views/add_pantry_item_modal.dart';
import '../views/update_pantry_item_modal.dart';
import 'stock_status_dropdown.dart';

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
    if (showCategoryHeaders) {
      // Group items by category
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

      // Calculate total child count
      int childCount = 0;
      for (final entry in groupedItems.entries) {
        childCount += 1; // Category header
        childCount += entry.value.length; // Items
      }
      // Add spacing elements between categories
      childCount += sortedCategories.length - 1;
      // Add "Add Item" button at the end
      childCount += 1;

      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              int currentIndex = 0;

              for (int categoryIndex = 0; categoryIndex < sortedCategories.length; categoryIndex++) {
                final category = sortedCategories[categoryIndex];
                final categoryItems = groupedItems[category]!;

                // Category header
                if (currentIndex == index) {
                  return _buildCategoryHeader(context, category, categoryItems.length);
                }
                currentIndex++;

                // Category items
                for (int itemIndex = 0; itemIndex < categoryItems.length; itemIndex++) {
                  final item = categoryItems[itemIndex];
                  if (currentIndex == index) {
                    final isFirst = itemIndex == 0;
                    final isLast = itemIndex == categoryItems.length - 1;

                    return _buildPantryItemTile(
                      context,
                      ref,
                      item,
                      isFirst: isFirst,
                      isLast: isLast,
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

              // Add Item button at the end
              if (currentIndex == index) {
                return Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: _buildAddItemButton(context),
                );
              }

              return null;
            },
            childCount: childCount,
          ),
        ),
      );
    } else {
      // Flat list without category headers
      final sortedItems = List<PantryItemEntry>.from(pantryItems)
        ..sort((a, b) => a.name.compareTo(b.name));

      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < sortedItems.length) {
                final item = sortedItems[index];
                final isFirst = index == 0;
                final isLast = index == sortedItems.length - 1;

                return _buildPantryItemTile(
                  context,
                  ref,
                  item,
                  isFirst: isFirst,
                  isLast: isLast,
                );
              } else if (index == sortedItems.length) {
                return Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: _buildAddItemButton(context),
                );
              }
              return null;
            },
            childCount: sortedItems.length + 1,
          ),
        ),
      );
    }
  }

  Widget _buildCategoryHeader(BuildContext context, String category, int itemCount) {
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

  Widget _buildPantryItemTile(
    BuildContext context,
    WidgetRef ref,
    PantryItemEntry item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final isSelected = ref.watch(pantrySelectionProvider.select((selection) => selection.contains(item.id)));

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

    return GestureDetector(
      onTap: () {
        // Edit this pantry item
        showUpdatePantryItemModal(
          context,
          pantryItem: item,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.of(context).primary.withValues(alpha: 0.1)
              : AppColors.of(context).input,
          border: border,
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Checkbox for selection - using AppRadioButton
              AppRadioButton(
                selected: isSelected,
                onTap: () {
                  ref.read(pantrySelectionProvider.notifier).toggleSelection(item.id);
                },
              ),

              SizedBox(width: AppSpacing.md),

              // Pantry item name with truncation
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              SizedBox(width: AppSpacing.md),

              // Stock status dropdown
              StockStatusDropdown(
                value: item.stockStatus,
                onChanged: (StockStatus value) {
                  ref.read(pantryNotifierProvider.notifier).updateItem(
                    id: item.id,
                    stockStatus: value,
                  );
                },
              ),

              SizedBox(width: AppSpacing.sm),

              // Edit icon
              Icon(
                CupertinoIcons.pencil,
                color: AppColors.of(context).textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemButton(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color ??
        (isDarkMode ? Colors.white : Colors.black);
    final borderColor = isDarkMode
        ? Colors.grey.shade600
        : Colors.grey.shade400;

    return Center(
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
    );
  }
}
