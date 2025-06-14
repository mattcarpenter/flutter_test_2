import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../widgets/shopping_list_dropdown.dart';
import '../widgets/shopping_list_items_list.dart';
import '../widgets/shopping_list_selection_fab.dart';
import 'add_shopping_list_item_modal.dart';
import 'manage_shopping_lists_modal.dart';

class ShoppingListTab extends ConsumerWidget {
  const ShoppingListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current shopping list items
    final itemsAsyncValue = ref.watch(currentShoppingListItemsProvider);
    final currentListId = ref.watch(currentShoppingListProvider);
    final listsAsyncValue = ref.watch(shoppingListsProvider);

    return Stack(
      children: [
        AdaptiveSliverPage(
          title: 'Shopping List',
          searchEnabled: false, // No search as per requirements
          slivers: [
            // Shopping list dropdown header
            SliverPersistentHeader(
              pinned: false,
              floating: true,
              delegate: _ShoppingListDropdownDelegate(
                currentListId: currentListId,
                lists: listsAsyncValue.value ?? [],
                onListSelected: (listId) {
                  ref.read(currentShoppingListProvider.notifier).setCurrentList(listId);
                },
                onManageLists: () {
                  showManageShoppingListsModal(context);
                },
              ),
            ),

            // Shopping list items
            itemsAsyncValue.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $error')),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No items in this shopping list yet.'),
                          const SizedBox(height: 8),
                          CupertinoButton(
                            onPressed: () {
                              showAddShoppingListItemModal(context, currentListId);
                            },
                            child: const Text('Add your first item'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ShoppingListItemsList(items: items);
              },
            ),
          ],
          trailing: AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'Manage Lists',
                icon: const Icon(CupertinoIcons.list_bullet),
                onTap: () {
                  showManageShoppingListsModal(context);
                },
              ),
              AdaptiveMenuItem(
                title: 'Add Item',
                icon: const Icon(CupertinoIcons.cart_badge_plus),
                onTap: () {
                  showAddShoppingListItemModal(context, currentListId);
                },
              ),
            ],
            child: const Icon(CupertinoIcons.add_circled),
          ),
        ),
        // Floating Action Button for bulk actions
        const Positioned(
          bottom: 24,
          right: 24,
          child: ShoppingListSelectionFAB(),
        ),
      ],
    );
  }
}

/// Delegate for the shopping list dropdown header
class _ShoppingListDropdownDelegate extends SliverPersistentHeaderDelegate {
  final String? currentListId;
  final List<ShoppingListEntry> lists;
  final Function(String?) onListSelected;
  final VoidCallback onManageLists;

  _ShoppingListDropdownDelegate({
    required this.currentListId,
    required this.lists,
    required this.onListSelected,
    required this.onManageLists,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 1.0 : 0.0,
      color: Colors.white.withValues(alpha: 0.95),
      child: Container(
        height: minExtent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ShoppingListDropdown(
          currentListId: currentListId,
          lists: lists,
          onListSelected: onListSelected,
          onManageLists: onManageLists,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _ShoppingListDropdownDelegate oldDelegate) {
    return oldDelegate.currentListId != currentListId ||
           oldDelegate.lists.length != lists.length;
  }

  @override
  TickerProvider? get vsync => null;
}
