import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../localization/l10n_extension.dart';
import 'shopping_list_selection_row.dart';

/// Reusable widget that displays a list of shopping lists
/// Can be used in different contexts (selection modal, manage lists page, etc.)
class ShoppingListsContent extends ConsumerWidget {
  /// Called when user taps a list. If null, taps do nothing.
  final void Function(String? listId, String listName)? onListTap;

  /// Called when user wants to create a new list
  final VoidCallback onCreateList;

  /// Whether to show selection checkmarks
  final bool showSelection;

  /// Currently selected list ID (for checkmark). Only used if showSelection is true.
  final String? selectedListId;

  /// Whether to show the "Create New List" button
  final bool showCreateButton;

  /// Whether to allow swipe-to-delete
  final bool allowDelete;

  const ShoppingListsContent({
    super.key,
    this.onListTap,
    required this.onCreateList,
    this.showSelection = false,
    this.selectedListId,
    this.showCreateButton = true,
    this.allowDelete = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final listsAsyncValue = ref.watch(shoppingListsProvider);
    final currentListId = ref.watch(currentShoppingListProvider);

    return listsAsyncValue.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 200,
        child: Center(child: Text('Error: $error')),
      ),
      data: (lists) {
        // Create list with default "My Shopping List" at top
        final allLists = <_ListItem>[
          _ListItem(
            id: null,
            name: context.l10n.recipeAddToShoppingListDefault,
            isDefault: true,
            isSelected: showSelection && (selectedListId ?? currentListId) == null,
          ),
          ...lists.map((list) => _ListItem(
                id: list.id,
                name: list.name ?? context.l10n.shoppingListUnnamed,
                isDefault: false,
                isSelected: showSelection && (selectedListId ?? currentListId) == list.id,
              )),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create button
            if (showCreateButton)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    text: context.l10n.shoppingListCreateNew,
                    onPressed: onCreateList,
                    theme: AppButtonTheme.secondary,
                    style: AppButtonStyle.outline,
                    shape: AppButtonShape.square,
                    size: AppButtonSize.small,
                    leadingIcon: const Icon(Icons.add),
                  ),
                ),
              ),

            // List
            if (allLists.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    context.l10n.shoppingListNoLists,
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: allLists.asMap().entries.map((entry) {
                  final index = entry.key;
                  final listItem = entry.value;
                  final isFirst = index == 0;
                  final isLast = index == allLists.length - 1;

                  // Callback for deleting a list (used in both swipe-to-delete and menu)
                  Future<void> handleDelete() async {
                    final confirmed = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (dialogContext) => CupertinoAlertDialog(
                        title: Text(context.l10n.shoppingListDeleteTitle),
                        content: Text(
                            context.l10n.shoppingListDeleteConfirm(listItem.name)),
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
                    ) ?? false;

                    if (confirmed) {
                      // If deleting the currently selected list, switch to default
                      if (listItem.id == currentListId) {
                        ref
                            .read(currentShoppingListProvider.notifier)
                            .setCurrentList(null);
                      }

                      await ref
                          .read(shoppingListsProvider.notifier)
                          .deleteList(listItem.id!);
                    }
                  }

                  Widget row = ShoppingListSelectionRow(
                    listId: listItem.id,
                    label: listItem.name,
                    selected: listItem.isSelected,
                    first: isFirst,
                    last: isLast,
                    showRadio: showSelection,
                    onTap: onListTap != null
                        ? () => onListTap!(listItem.id, listItem.name)
                        : null,
                    onDelete: allowDelete && !listItem.isDefault
                        ? handleDelete
                        : null,
                  );

                  // Add dismissible for non-default lists if delete is allowed (only in selection mode)
                  if (allowDelete && !listItem.isDefault && showSelection) {
                    final borderRadius = GroupedListStyling.getBorderRadius(
                      isGrouped: true,
                      isFirstInGroup: isFirst,
                      isLastInGroup: isLast,
                    );

                    row = Dismissible(
                      key: ValueKey(listItem.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: CupertinoColors.destructiveRed,
                          borderRadius: borderRadius,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showCupertinoDialog<bool>(
                              context: context,
                              builder: (dialogContext) => CupertinoAlertDialog(
                                title: Text(context.l10n.shoppingListDeleteTitle),
                                content: Text(
                                    context.l10n.shoppingListDeleteConfirm(listItem.name)),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text(context.l10n.commonCancel),
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: Text(context.l10n.commonDelete),
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) async {
                        // If deleting the currently selected list, switch to default
                        if (listItem.id == currentListId) {
                          ref
                              .read(currentShoppingListProvider.notifier)
                              .setCurrentList(null);
                        }

                        await ref
                            .read(shoppingListsProvider.notifier)
                            .deleteList(listItem.id!);
                      },
                      child: row,
                    );
                  }

                  return row;
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}

/// Internal model for list items
class _ListItem {
  final String? id;
  final String name;
  final bool isDefault;
  final bool isSelected;

  _ListItem({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.isSelected,
  });
}
