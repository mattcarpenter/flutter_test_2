import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/shopping_list_selection_row.dart';

void showShoppingListSelectionModal(BuildContext context, WidgetRef ref) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (bottomSheetContext) => [
      ShoppingListSelectionPage.build(bottomSheetContext, ref),
      CreateShoppingListPage.build(bottomSheetContext, ref),
    ],
  );
}

/// Page 0: Select shopping list
class ShoppingListSelectionPage {
  ShoppingListSelectionPage._();

  static WoltModalSheetPage build(BuildContext context, WidgetRef ref) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      pageTitle: ModalSheetTitle(
        'Select Shopping List',
        trailing: AppButton(
          text: 'Create New List',
          onPressed: () {
            WoltModalSheet.of(context).showNext();
          },
          theme: AppButtonTheme.secondary,
          style: AppButtonStyle.outline,
          shape: AppButtonShape.square,
          size: AppButtonSize.small,
          leadingIcon: const Icon(Icons.add),
        ),
      ),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: ShoppingListSelectionPageContent(ref: ref),
      ),
    );
  }
}

class ShoppingListSelectionPageContent extends ConsumerWidget {
  final WidgetRef ref;

  const ShoppingListSelectionPageContent({
    super.key,
    required this.ref,
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
            name: 'My Shopping List',
            isDefault: true,
            isSelected: currentListId == null,
          ),
          ...lists.map((list) => _ListItem(
                id: list.id,
                name: list.name ?? 'Unnamed List',
                isDefault: false,
                isSelected: currentListId == list.id,
              )),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // List
            if (allLists.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'No shopping lists yet',
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

                    Widget row = ShoppingListSelectionRow(
                      listId: listItem.id,
                      label: listItem.name,
                      selected: listItem.isSelected,
                      first: isFirst,
                      last: isLast,
                      onTap: () {
                        // Update current list
                        ref
                            .read(currentShoppingListProvider.notifier)
                            .setCurrentList(listItem.id);
                        // Close modal immediately
                        Navigator.of(context).pop();
                      },
                    );

                    // Add dismissible for non-default lists
                    if (!listItem.isDefault) {
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
                          child: const Icon(
                            CupertinoIcons.trash,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showCupertinoDialog<bool>(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text('Delete List'),
                                  content: Text(
                                      'Are you sure you want to delete "${listItem.name}"? All items in this list will also be deleted.'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('Cancel'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text('Delete'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
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

/// Page 1: Create new shopping list
class CreateShoppingListPage {
  CreateShoppingListPage._();

  static WoltModalSheetPage build(BuildContext context, WidgetRef ref) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      pageTitle: ModalSheetTitle('Create New List'),
      leadingNavBarWidget: Padding(
        padding: EdgeInsets.only(left: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.back,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () {
            WoltModalSheet.of(context).showPrevious();
          },
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: CreateShoppingListPageContent(ref: ref),
      ),
    );
  }
}

class CreateShoppingListPageContent extends StatefulWidget {
  final WidgetRef ref;

  const CreateShoppingListPageContent({
    super.key,
    required this.ref,
  });

  @override
  State<CreateShoppingListPageContent> createState() =>
      _CreateShoppingListPageContentState();
}

class _CreateShoppingListPageContentState
    extends State<CreateShoppingListPageContent> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createListAndReturn() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await widget.ref.read(shoppingListsProvider.notifier).createList(
            name: name,
            userId: userId,
          );

      if (mounted) {
        // Clear form
        _nameController.clear();
        // Go back to selection page
        WoltModalSheet.of(context).showPrevious();
      }
    } catch (e) {
      debugPrint('Error creating shopping list: $e');
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // List name input label
        Text(
          'List Name',
          style: AppTypography.label.copyWith(
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // List name input field
        AppTextFieldSimple(
          controller: _nameController,
          placeholder: 'Enter list name',
          onChanged: (_) {
            setState(() {}); // Rebuild to update button state
          },
          autofocus: true,
          enabled: !_isCreating,
        ),
        SizedBox(height: AppSpacing.xl),

        // Create button
        AppButton(
          text: 'Create',
          onPressed: _nameController.text.trim().isEmpty || _isCreating
              ? null
              : _createListAndReturn,
          theme: AppButtonTheme.primary,
          style: AppButtonStyle.fill,
          shape: AppButtonShape.square,
          size: AppButtonSize.large,
          fullWidth: true,
          loading: _isCreating,
        ),
        SizedBox(height: AppSpacing.sm),
      ],
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
