import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disclosure/disclosure.dart';
import '../../../../database/database.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/category_localizer.dart';
import 'shopping_list_item_tile.dart';

class ShoppingListItemsList extends ConsumerStatefulWidget {
  final List<ShoppingListItemEntry> items;

  const ShoppingListItemsList({
    super.key,
    required this.items,
  });

  @override
  ConsumerState<ShoppingListItemsList> createState() => _ShoppingListItemsListState();
}

class _ShoppingListItemsListState extends ConsumerState<ShoppingListItemsList> {
  // Track which categories are expanded (all expanded by default)
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Initialize all categories as expanded
    _addAllCategoriesToExpanded(widget.items);
  }

  @override
  void didUpdateWidget(ShoppingListItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand any new categories that appear
    _addAllCategoriesToExpanded(widget.items);
  }

  /// Adds all categories from the given items to _expandedCategories.
  /// New categories will automatically be expanded.
  void _addAllCategoriesToExpanded(List<ShoppingListItemEntry> items) {
    for (final item in items) {
      final category = item.category ?? 'Other';
      _expandedCategories.add(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group items by category
    final Map<String, List<ShoppingListItemEntry>> groupedItems = {};

    for (final item in widget.items) {
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

    // Build list of widgets using Disclosure for each category
    final List<Widget> categoryWidgets = [];

    for (int categoryIndex = 0; categoryIndex < sortedCategories.length; categoryIndex++) {
      final category = sortedCategories[categoryIndex];
      final categoryItems = groupedItems[category]!;
      final isExpanded = _expandedCategories.contains(category);

      // Add spacing before category (except first)
      if (categoryIndex > 0) {
        categoryWidgets.add(SizedBox(height: AppSpacing.md));
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
              // Wrap in GestureDetector to absorb taps and prevent
              // them from propagating up to toggle the Disclosure
              child: GestureDetector(
                onTap: () {}, // Absorb tap to prevent disclosure toggle
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int itemIndex = 0; itemIndex < categoryItems.length; itemIndex++)
                      ShoppingListItemTile(
                        item: categoryItems[itemIndex],
                        isFirst: itemIndex == 0,
                        isLast: itemIndex == categoryItems.length - 1,
                        onBoughtToggle: (bought) async {
                          final currentListId = ref.read(currentShoppingListProvider);
                          await ref.read(shoppingListItemsProvider(currentListId).notifier)
                              .markBought(categoryItems[itemIndex].id, bought: bought);
                        },
                        onDelete: () async {
                          final currentListId = ref.read(currentShoppingListProvider);
                          await ref.read(shoppingListItemsProvider(currentListId).notifier)
                              .deleteItem(categoryItems[itemIndex].id);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildListDelegate(categoryWidgets),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String category, int itemCount) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            CategoryLocalizer.localize(context, category).toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
              letterSpacing: -0.08,
            ),
          ),
          const Spacer(),
          // Animated chevron icon
          DisclosureIcon(
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}