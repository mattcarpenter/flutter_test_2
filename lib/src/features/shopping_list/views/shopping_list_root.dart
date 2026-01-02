import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../database/database.dart';
import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_button.dart';
import '../widgets/shopping_list_items_list.dart';
import '../widgets/shopping_list_selection_fab.dart';
import 'add_shopping_list_item_modal.dart';
import 'shopping_list_selection_modal.dart';

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
          title: context.l10n.shoppingListPageTitle,
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
                  showShoppingListSelectionModal(context, ref);
                },
                ref: ref,
                onAddItem: () {
                  showAddShoppingListItemModal(context, currentListId);
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
                          Text(
                            context.l10n.shoppingListEmptyState,
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoButton(
                            onPressed: () {
                              showAddShoppingListItemModal(context, currentListId);
                            },
                            child: Text(context.l10n.shoppingListAddFirstItem),
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
          leading: const HugeIcon(icon: HugeIcons.strokeRoundedShoppingCart01),
          trailing: AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: context.l10n.shoppingListManageLists,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedLeftToRightListBullet),
                onTap: () {
                  showShoppingListSelectionModal(context, ref);
                },
              ),
              AdaptiveMenuItem(
                title: context.l10n.shoppingListAddItem,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedShoppingCartAdd01),
                onTap: () {
                  showAddShoppingListItemModal(context, currentListId);
                },
              ),
              AdaptiveMenuItem(
                title: context.l10n.shoppingListClearAll,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                isDestructive: true,
                onTap: () async {
                  final items = itemsAsyncValue.valueOrNull ?? [];

                  // Don't show dialog if there are no items
                  if (items.isEmpty) {
                    await showCupertinoDialog(
                      context: context,
                      builder: (dialogContext) => CupertinoAlertDialog(
                        title: Text(context.l10n.shoppingListNoItemsTitle),
                        content: Text(context.l10n.shoppingListNoItemsMessage),
                        actions: [
                          CupertinoDialogAction(
                            child: Text(context.l10n.commonOk),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  final shouldClear = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (dialogContext) => CupertinoAlertDialog(
                      title: Text(context.l10n.shoppingListClearAll),
                      content: Text(
                        context.l10n.shoppingListClearAllConfirm(items.length),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(context.l10n.commonCancel),
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: Text(context.l10n.commonClear),
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (shouldClear == true) {
                    final itemIds = items.map((item) => item.id).toList();
                    await ref
                        .read(shoppingListItemsProvider(currentListId).notifier)
                        .deleteMultipleItems(itemIds);
                  }
                },
              ),
              AdaptiveMenuItem(
                title: context.l10n.shoppingListDeleteTitle,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
                isDestructive: true,
                onTap: () async {
                  // Check if trying to delete the default list
                  if (currentListId == null) {
                    await showCupertinoDialog(
                      context: context,
                      builder: (dialogContext) => CupertinoAlertDialog(
                        title: Text(context.l10n.shoppingListCannotDeleteTitle),
                        content: Text(context.l10n.shoppingListCannotDeleteMessage),
                        actions: [
                          CupertinoDialogAction(
                            child: Text(context.l10n.commonOk),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // Get current list name for confirmation dialog
                  final listName = listsAsyncValue.value
                      ?.where((l) => l.id == currentListId)
                      .firstOrNull
                      ?.name ?? context.l10n.shoppingListUnnamed;

                  final shouldDelete = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (dialogContext) => CupertinoAlertDialog(
                      title: Text(context.l10n.shoppingListDeleteTitle),
                      content: Text(
                        context.l10n.shoppingListDeleteConfirm(listName),
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(context.l10n.commonCancel),
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: Text(context.l10n.commonDelete),
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    // Switch to default list first
                    ref
                        .read(currentShoppingListProvider.notifier)
                        .setCurrentList(null);

                    // Then delete the list
                    await ref
                        .read(shoppingListsProvider.notifier)
                        .deleteList(currentListId);
                  }
                },
              ),
            ],
            child: const AppCircleButton(
              icon: AppCircleButtonIcon.ellipsis,
            ),
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
  final WidgetRef ref;
  final VoidCallback onAddItem;

  _ShoppingListDropdownDelegate({
    required this.currentListId,
    required this.lists,
    required this.onListSelected,
    required this.onManageLists,
    required this.ref,
    required this.onAddItem,
  });

  String _getCurrentListName(BuildContext context) {
    final defaultName = context.l10n.recipeAddToShoppingListDefault;
    if (currentListId == null) {
      return defaultName; // Default list name
    }

    final list = lists.where((l) => l.id == currentListId).firstOrNull;
    return list?.name ?? defaultName;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: minExtent,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      constraints: const BoxConstraints(maxWidth: 800),
      child: Row(
        children: [
          // List selector button (takes all available space)
          Expanded(
            child: AppButton(
              text: _getCurrentListName(context),
              trailingIcon: const Icon(Icons.keyboard_arrow_down, size: 24),
              trailingIconOffset: const Offset(8, -2),
              style: AppButtonStyle.mutedOutline,
              shape: AppButtonShape.square,
              size: AppButtonSize.medium,
              theme: AppButtonTheme.primary,
              fullWidth: true,
              contentAlignment: AppButtonContentAlignment.left,
              onPressed: onManageLists,
            ),
          ),

          const SizedBox(width: 12), // Spacing between buttons

          // Add Item button (fixed width)
          AppButton(
            text: context.l10n.shoppingListAddItem,
            leadingIcon: const Icon(Icons.add),
            style: AppButtonStyle.outline,
            shape: AppButtonShape.square,
            size: AppButtonSize.medium,
            theme: AppButtonTheme.secondary,
            onPressed: onAddItem,
          ),
        ],
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
