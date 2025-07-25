import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../models/pantry_update_models.dart';
import '../services/pantry_update_service.dart';
import '../widgets/pantry_update_item_tile.dart';

// State management for checked items
final _updatePantryCheckedItemsProvider = StateProvider<Map<String, bool>>((ref) => {});
final _updatePantryResultProvider = StateProvider<PantryUpdateResult?>((ref) => null);

void showUpdatePantryModal(
  BuildContext context,
  List<ShoppingListItemEntry> boughtItems,
) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      UpdatePantryModalPage.build(
        context: bottomSheetContext,
        boughtItems: boughtItems,
      ),
    ],
  );
}

class UpdatePantryModalPage {
  UpdatePantryModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required List<ShoppingListItemEntry> boughtItems,
  }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Update Pantry'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: UpdatePantryContent(boughtItems: boughtItems),
      ),
      stickyActionBar: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: UpdatePantryButton(boughtItems: boughtItems),
        ),
      ),
    );
  }
}

class UpdatePantryContent extends ConsumerStatefulWidget {
  final List<ShoppingListItemEntry> boughtItems;

  const UpdatePantryContent({
    super.key,
    required this.boughtItems,
  });

  @override
  ConsumerState<UpdatePantryContent> createState() => _UpdatePantryContentState();
}

class _UpdatePantryContentState extends ConsumerState<UpdatePantryContent> {
  @override
  void initState() {
    super.initState();
    // Reset providers when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(_updatePantryCheckedItemsProvider);
      ref.invalidate(_updatePantryResultProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantryItemsAsync = ref.watch(pantryItemsProvider);
    final checkedItems = ref.watch(_updatePantryCheckedItemsProvider);

    return pantryItemsAsync.when(
      loading: () => const Center(
        child: CupertinoActivityIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error loading pantry: $error'),
      ),
      data: (pantryItems) {
        // Analyze updates
        final updateResult = PantryUpdateService.analyzeUpdates(
          shoppingListItems: widget.boughtItems,
          pantryItems: pantryItems,
        );
        
        // Store result in provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(_updatePantryResultProvider.notifier).state = updateResult;
        });

        if (!updateResult.hasChanges) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.activeGreen,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Nothing to update',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'All items are already in your pantry\nand marked as in stock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          );
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items to add section
                if (updateResult.itemsToAdd.isNotEmpty) ...[
                _buildSectionHeader(
                  'Items to add',
                  updateResult.itemsToAdd.length,
                  CupertinoColors.activeGreen,
                ),
                const SizedBox(height: 8),
                ...updateResult.itemsToAdd.map((item) {
                  final itemId = 'add_${item.shoppingListItem.id}';
                  return PantryUpdateItemTile(
                    item: item,
                    isChecked: checkedItems[itemId] ?? true,
                    onCheckedChanged: (value) {
                      final newCheckedItems = {...checkedItems};
                      newCheckedItems[itemId] = value;
                      ref.read(_updatePantryCheckedItemsProvider.notifier).state = newCheckedItems;
                    },
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Items to update section
              if (updateResult.itemsToUpdate.isNotEmpty) ...[
                _buildSectionHeader(
                  'Items to update',
                  updateResult.itemsToUpdate.length,
                  CupertinoColors.activeBlue,
                ),
                const SizedBox(height: 8),
                ...updateResult.itemsToUpdate.map((item) {
                  final itemId = 'update_${item.shoppingListItem.id}';
                  return PantryUpdateItemTile(
                    item: item,
                    isChecked: checkedItems[itemId] ?? true,
                    onCheckedChanged: (value) {
                      final newCheckedItems = {...checkedItems};
                      newCheckedItems[itemId] = value;
                      ref.read(_updatePantryCheckedItemsProvider.notifier).state = newCheckedItems;
                    },
                  );
                }),
              ],
              // Add bottom padding to ensure content isn't hidden behind sticky action bar
              const SizedBox(height: 80),
            ],
          ),
        ));
      },
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class UpdatePantryButton extends ConsumerWidget {
  final List<ShoppingListItemEntry> boughtItems;

  const UpdatePantryButton({
    super.key,
    required this.boughtItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedItems = ref.watch(_updatePantryCheckedItemsProvider);
    final updateResult = ref.watch(_updatePantryResultProvider);
    
    if (updateResult == null) {
      return const SizedBox.shrink();
    }

    // Count checked items
    int checkedCount = 0;
    for (final item in updateResult.itemsToAdd) {
      final itemId = 'add_${item.shoppingListItem.id}';
      if (checkedItems[itemId] ?? true) checkedCount++;
    }
    for (final item in updateResult.itemsToUpdate) {
      final itemId = 'update_${item.shoppingListItem.id}';
      if (checkedItems[itemId] ?? true) checkedCount++;
    }

    final isEnabled = checkedCount > 0;

    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: isEnabled
            ? () async {
                await _performUpdate(context, ref, updateResult, checkedItems);
              }
            : null,
        child: Text(
          checkedCount > 0
              ? 'Update Pantry ($checkedCount)'
              : 'Update Pantry',
        ),
      ),
    );
  }

  Future<void> _performUpdate(
    BuildContext context,
    WidgetRef ref,
    PantryUpdateResult updateResult,
    Map<String, bool> checkedItems,
  ) async {
    final pantryNotifier = ref.read(pantryItemsProvider.notifier);
    final currentListId = ref.read(currentShoppingListProvider);
    final shoppingListNotifier = ref.read(shoppingListItemsProvider(currentListId).notifier);

    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(
          radius: 16,
        ),
      ),
    );

    try {
      // Process items to add
      for (final item in updateResult.itemsToAdd) {
        final itemId = 'add_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          await pantryNotifier.addItem(
            name: item.shoppingListItem.name,
            stockStatus: StockStatus.inStock,
            category: item.shoppingListItem.category,
            userId: item.shoppingListItem.userId,
            householdId: item.shoppingListItem.householdId,
          );
        }
      }

      // Process items to update
      for (final item in updateResult.itemsToUpdate) {
        final itemId = 'update_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          await pantryNotifier.updateItem(
            id: item.matchingPantryItem!.id,
            stockStatus: StockStatus.inStock,
          );
        }
      }

      // Delete the shopping list items that were processed
      final processedItemIds = <String>[];
      for (final item in updateResult.itemsToAdd) {
        final itemId = 'add_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          processedItemIds.add(item.shoppingListItem.id);
        }
      }
      for (final item in updateResult.itemsToUpdate) {
        final itemId = 'update_${item.shoppingListItem.id}';
        if (checkedItems[itemId] ?? true) {
          processedItemIds.add(item.shoppingListItem.id);
        }
      }

      // Delete all processed items from shopping list
      if (processedItemIds.isNotEmpty) {
        await shoppingListNotifier.deleteMultipleItems(processedItemIds);
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Close the modal
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error updating pantry: $e');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to update pantry: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }
}