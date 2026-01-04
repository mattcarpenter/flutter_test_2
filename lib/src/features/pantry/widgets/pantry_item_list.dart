import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disclosure/disclosure.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../localization/l10n_extension.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/pantry_selection_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/stock_chip.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../utils/category_localizer.dart';
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
    _addAllCategoriesToExpanded(widget.pantryItems);
  }

  @override
  void didUpdateWidget(PantryItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand any new categories that appear (e.g., after categorization)
    _addAllCategoriesToExpanded(widget.pantryItems);
  }

  /// Adds all categories from the given items to _expandedCategories.
  /// New categories will automatically be expanded.
  void _addAllCategoriesToExpanded(List<PantryItemEntry> items) {
    for (final item in items) {
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
              header: _buildCategoryHeader(context, category, categoryItems.length),
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
            CategoryLocalizer.localize(context, category),
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
          // Only the chevron is tappable to toggle the accordion
          DisclosureButton.basic(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: DisclosureIcon(
                color: AppColors.of(context).textSecondary,
              ),
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

    final colors = AppColors.of(context);

    // Wrap in GestureDetector to absorb taps and prevent them from
    // propagating to parent widgets (like the Disclosure accordion)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Tapping the row toggles selection
        ref.read(pantrySelectionProvider.notifier).toggleSelection(item.id);
      },
      child: Container(
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
                    title: context.l10n.pantrySetOutOfStock,
                    icon: item.stockStatus == StockStatus.outOfStock
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: const Color(0xFFEF5350), // Red
                          )
                        : Icon(
                            CupertinoIcons.circle,
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
                    title: context.l10n.pantrySetLowStock,
                    icon: item.stockStatus == StockStatus.lowStock
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: const Color(0xFFFFA726), // Orange
                          )
                        : Icon(
                            CupertinoIcons.circle,
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
                    title: context.l10n.pantrySetInStock,
                    icon: item.stockStatus == StockStatus.inStock
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: const Color(0xFF66BB6A), // Green
                          )
                        : Icon(
                            CupertinoIcons.circle,
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
                    title: context.l10n.pantryEdit,
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01),
                    onTap: () {
                      showUpdatePantryItemModal(
                        context,
                        pantryItem: item,
                      );
                    },
                  ),
                  AdaptiveMenuItem.divider(),
                  AdaptiveMenuItem(
                    title: context.l10n.commonDelete,
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
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
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, PantryItemEntry item) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.pantryDeleteItemTitle),
        content: Text(
          context.l10n.pantryDeleteItemMessage(item.name),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: Text(context.l10n.commonCancel),
            onPressed: () {
              Navigator.pop(dialogContext);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(pantryNotifierProvider.notifier).deleteItem(item.id);
              } catch (e) {
                if (context.mounted) {
                  showCupertinoDialog<void>(
                    context: context,
                    builder: (errorDialogContext) => CupertinoAlertDialog(
                      title: Text(context.l10n.commonError),
                      content: Text(context.l10n.pantryDeleteFailed(e.toString())),
                      actions: <CupertinoDialogAction>[
                        CupertinoDialogAction(
                          child: Text(context.l10n.commonOk),
                          onPressed: () {
                            Navigator.pop(errorDialogContext);
                          },
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: Text(context.l10n.commonDelete),
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
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: colors.textSecondary,
          size: 18,
        ),
        label: Text(
          context.l10n.pantryAddItem,
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
