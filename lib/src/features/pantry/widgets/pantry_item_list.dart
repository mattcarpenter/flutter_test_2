import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disclosure/disclosure.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/pantry_selection_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/stock_chip.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../views/add_pantry_item_modal.dart';
import '../views/update_pantry_item_modal.dart';

class PantryItemList extends ConsumerStatefulWidget {
  final List<PantryItemEntry> pantryItems;
  final bool showCategoryHeaders;

  const PantryItemList({
    super.key,
    required this.pantryItems,
    this.showCategoryHeaders = true,
  });

  @override
  ConsumerState<PantryItemList> createState() => _PantryItemListState();
}

class _PantryItemListState extends ConsumerState<PantryItemList> {
  // Track which categories are expanded (all expanded by default)
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Initialize all categories as expanded
    for (final item in widget.pantryItems) {
      final category = item.category ?? 'Other';
      _expandedCategories.add(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showCategoryHeaders) {
      // Group items by category
      final Map<String, List<PantryItemEntry>> groupedItems = {};

      for (final item in widget.pantryItems) {
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

      // Build list of widgets using Disclosure for each category
      final List<Widget> categoryWidgets = [];

      for (int categoryIndex = 0; categoryIndex < sortedCategories.length; categoryIndex++) {
        final category = sortedCategories[categoryIndex];
        final categoryItems = groupedItems[category]!;
        final isExpanded = _expandedCategories.contains(category);

        // Add spacing before category (except first)
        if (categoryIndex > 0) {
          categoryWidgets.add(SizedBox(height: AppSpacing.lg));
        }

        // Add Disclosure widget for category
        categoryWidgets.add(
          Material(
            type: MaterialType.transparency,
            child: Disclosure(
              closed: !isExpanded,
              onOpen: () {
                setState(() {
                  _expandedCategories.add(category);
                });
              },
              onClose: () {
                setState(() {
                  _expandedCategories.remove(category);
                });
              },
              header: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: DisclosureButton(
                  child: _buildCategoryHeader(context, category, categoryItems.length),
                ),
              ),
              child: DisclosureView(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int itemIndex = 0; itemIndex < categoryItems.length; itemIndex++)
                      _buildPantryItemTile(
                        context,
                        ref,
                        categoryItems[itemIndex],
                        isFirst: itemIndex == 0,
                        isLast: itemIndex == categoryItems.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Add "Add Item" button at the end
      categoryWidgets.add(
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: _buildAddItemButton(context),
        ),
      );

      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList(
          delegate: SliverChildListDelegate(categoryWidgets),
        ),
      );
    } else {
      // Flat list without category headers
      final sortedItems = List<PantryItemEntry>.from(widget.pantryItems)
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
          const Spacer(),
          // Animated chevron icon
          DisclosureIcon(
            color: AppColors.of(context).textSecondary,
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

    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.1)
            : colors.groupedListBackground,
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

            // Column 1: Pantry item name (grows to fill space)
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            SizedBox(width: AppSpacing.md),

            // Column 2: Stock status chip (only show for Low/Out of Stock)
            if (item.stockStatus != StockStatus.inStock)
              SizedBox(
                width: 85, // Wide enough for "Out of Stock"
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: StockChip(status: item.stockStatus),
                  ),
                ),
              )
            else
              SizedBox(width: AppSpacing.md), // Gap when no chip

            // Column 3: Overflow menu button (shrinks to content)
            AdaptivePullDownButton(
              items: [
                AdaptiveMenuItem(
                  title: 'Set to Out of Stock',
                  icon: Icon(
                    item.stockStatus == StockStatus.outOfStock
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: const Color(0xFFEF5350), // Red
                  ),
                  onTap: () {
                    ref.read(pantryNotifierProvider.notifier).updateItem(
                      id: item.id,
                      stockStatus: StockStatus.outOfStock,
                    );
                  },
                ),
                AdaptiveMenuItem(
                  title: 'Set to Low Stock',
                  icon: Icon(
                    item.stockStatus == StockStatus.lowStock
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: const Color(0xFFFFA726), // Orange
                  ),
                  onTap: () {
                    ref.read(pantryNotifierProvider.notifier).updateItem(
                      id: item.id,
                      stockStatus: StockStatus.lowStock,
                    );
                  },
                ),
                AdaptiveMenuItem(
                  title: 'Set to In Stock',
                  icon: Icon(
                    item.stockStatus == StockStatus.inStock
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: const Color(0xFF66BB6A), // Green
                  ),
                  onTap: () {
                    ref.read(pantryNotifierProvider.notifier).updateItem(
                      id: item.id,
                      stockStatus: StockStatus.inStock,
                    );
                  },
                ),
                AdaptiveMenuItem.divider(),
                AdaptiveMenuItem(
                  title: 'Edit',
                  icon: const Icon(CupertinoIcons.pencil),
                  onTap: () {
                    showUpdatePantryItemModal(
                      context,
                      pantryItem: item,
                    );
                  },
                ),
                AdaptiveMenuItem.divider(),
                AdaptiveMenuItem(
                  title: 'Delete',
                  icon: const Icon(CupertinoIcons.trash),
                  isDestructive: true,
                  onTap: () {
                    _showDeleteConfirmation(context, ref, item);
                  },
                ),
              ],
              child: Icon(
                Icons.more_horiz,
                color: colors.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, PantryItemEntry item) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(pantryNotifierProvider.notifier).deleteItem(item.id);
              } catch (e) {
                if (context.mounted) {
                  showCupertinoDialog<void>(
                    context: context,
                    builder: (BuildContext context) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: Text('Failed to delete item: $e'),
                      actions: <CupertinoDialogAction>[
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          showAddPantryItemModal(context);
        },
        icon: Icon(
          CupertinoIcons.add,
          color: colors.textSecondary,
          size: 18,
        ),
        label: Text(
          'Add Item',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
