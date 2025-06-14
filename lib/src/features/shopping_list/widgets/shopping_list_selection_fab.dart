import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../providers/shopping_list_provider.dart';
import '../views/update_pantry_modal.dart';

class ShoppingListSelectionFAB extends ConsumerWidget {
  const ShoppingListSelectionFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsyncValue = ref.watch(currentShoppingListItemsProvider);
    
    return itemsAsyncValue.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final boughtItems = items.where((item) => item.bought).toList();
        
        if (boughtItems.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return FloatingActionButton.extended(
          onPressed: () {
            // TODO: Show action sheet with options:
            // - Update Pantry
            // - Un-mark
            // - Delete
            _showBulkActionSheet(context, ref, boughtItems);
          },
          backgroundColor: CupertinoColors.activeBlue,
          foregroundColor: CupertinoColors.white,
          label: const Text('With marked…'),
          icon: const Icon(CupertinoIcons.ellipsis),
        );
      },
    );
  }

  void _showBulkActionSheet(
    BuildContext context, 
    WidgetRef ref, 
    List<ShoppingListItemEntry> boughtItems,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Actions for ${boughtItems.length} marked items'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              showUpdatePantryModal(context, boughtItems);
            },
            child: const Text('Update Pantry'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final currentListId = ref.read(currentShoppingListProvider);
              final notifier = ref.read(shoppingListItemsProvider(currentListId).notifier);
              final itemIds = boughtItems.map((item) => item.id).toList();
              await notifier.markMultipleBought(itemIds, bought: false);
            },
            child: const Text('Un-mark'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final currentListId = ref.read(currentShoppingListProvider);
              final notifier = ref.read(shoppingListItemsProvider(currentListId).notifier);
              final itemIds = boughtItems.map((item) => item.id).toList();
              await notifier.deleteMultipleItems(itemIds);
            },
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}