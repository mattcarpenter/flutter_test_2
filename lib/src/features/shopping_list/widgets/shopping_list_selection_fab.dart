import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../localization/l10n_extension.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
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
            _showBulkActionSheet(context, ref, boughtItems);
          },
          backgroundColor: AppColors.of(context).primary,
          foregroundColor: CupertinoColors.white,
          label: Text(context.l10n.shoppingListBulkLabel),
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
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(context.l10n.shoppingListBulkTitle(boughtItems.length)),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              showUpdatePantryModal(context, boughtItems);
            },
            child: Text(context.l10n.shoppingListBulkUpdatePantry),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final currentListId = ref.read(currentShoppingListProvider);
              final notifier = ref.read(shoppingListItemsProvider(currentListId).notifier);
              final itemIds = boughtItems.map((item) => item.id).toList();
              await notifier.markMultipleBought(itemIds, bought: false);
            },
            child: Text(context.l10n.shoppingListBulkUnmark),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(sheetContext);
              final currentListId = ref.read(currentShoppingListProvider);
              final notifier = ref.read(shoppingListItemsProvider(currentListId).notifier);
              final itemIds = boughtItems.map((item) => item.id).toList();
              await notifier.deleteMultipleItems(itemIds);
            },
            isDestructiveAction: true,
            child: Text(context.l10n.commonDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(sheetContext);
          },
          child: Text(context.l10n.commonCancel),
        ),
      ),
    );
  }
}