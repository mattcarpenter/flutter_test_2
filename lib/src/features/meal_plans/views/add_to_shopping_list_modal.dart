import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../providers/meal_plan_shopping_list_provider.dart';
import '../models/aggregated_ingredient.dart';

void showAddToShoppingListModal(BuildContext context, String date) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      AddToShoppingListModalPage.build(
        context: modalContext,
        date: date,
      ),
    ],
  );
}

// Controller for managing checked state
class _AddToShoppingListController extends ChangeNotifier {
  Map<String, bool> checkedState = {};
  bool isLoading = false;

  void updateCheckedState(String id, bool value) {
    checkedState[id] = value;
    notifyListeners();
  }

  void initializeCheckedState(List<AggregatedIngredient> ingredients) {
    bool stateChanged = false;
    for (final ingredient in ingredients) {
      if (!checkedState.containsKey(ingredient.id)) {
        checkedState[ingredient.id] = ingredient.isChecked;
        stateChanged = true;
      }
    }
    if (stateChanged) {
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  bool get hasCheckedItems => checkedState.values.any((checked) => checked);
  bool get isButtonEnabled => hasCheckedItems && !isLoading;
}

class AddToShoppingListModalPage {
  AddToShoppingListModalPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext context,
    required String date,
  }) {
    final controller = _AddToShoppingListController();

    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      hasSabGradient: true,
      topBarTitle: const ModalSheetTitle('Add to Shopping List'),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      stickyActionBar: Consumer(
        builder: (consumerContext, ref, child) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).background,
              border: Border(
                top: BorderSide(
                  color: AppColors.of(context).border,
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: controller,
                builder: (buttonContext, child) {
                  final aggregatedIngredientsAsync = ref.watch(aggregatedIngredientsProvider(date));
                  final ingredients = aggregatedIngredientsAsync.valueOrNull ?? [];

                  return AppButtonVariants.primaryFilled(
                    text: controller.isLoading ? 'Adding...' : 'Add to Shopping List',
                    size: AppButtonSize.large,
                    shape: AppButtonShape.square,
                    fullWidth: true,
                    onPressed: controller.isButtonEnabled
                        ? () async {
                            await _addToShoppingList(
                              context: consumerContext,
                              ref: ref,
                              controller: controller,
                              ingredients: ingredients,
                            );
                          }
                        : null,
                  );
                },
              ),
            ),
          );
        },
      ),
      mainContentSliversBuilder: (builderContext) => [
        Consumer(
          builder: (consumerContext, ref, child) {
            final aggregatedIngredientsAsync = ref.watch(aggregatedIngredientsProvider(date));

            return _AddToShoppingListContentSlivers(
              aggregatedIngredientsAsync: aggregatedIngredientsAsync,
              controller: controller,
              date: date,
            );
          },
        ),
      ],
    );
  }

  static Widget _buildShoppingListSelector(BuildContext context, WidgetRef ref) {
    final currentListId = ref.watch(currentShoppingListProvider);
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final shoppingLists = shoppingListsAsync.valueOrNull ?? [];

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Row(
        children: [
          Text(
            'Add to:',
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showListPicker(context, ref, shoppingLists),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      _getListName(currentListId, shoppingLists),
                      style: TextStyle(
                        color: CupertinoColors.activeBlue.resolveFrom(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.cart,
            size: 64,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No ingredients to add',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All ingredients are either in your pantry with sufficient stock or already on a shopping list.',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static void _showListPicker(BuildContext context, WidgetRef ref, List<ShoppingListEntry> shoppingLists) {
    final currentListId = ref.read(currentShoppingListProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Shopping List'),
        actions: [
          // Default list option
          CupertinoActionSheetAction(
            onPressed: () {
              ref.read(currentShoppingListProvider.notifier).setCurrentList(null);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentListId == null) ...[
                  const Icon(CupertinoIcons.checkmark_alt, size: 20),
                  const SizedBox(width: 8),
                ],
                const Text('My Shopping List'),
              ],
            ),
          ),
          // Other lists
          ...shoppingLists.map((list) => CupertinoActionSheetAction(
            onPressed: () {
              ref.read(currentShoppingListProvider.notifier).setCurrentList(list.id);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentListId == list.id) ...[
                  const Icon(CupertinoIcons.checkmark_alt, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(list.name ?? 'Unnamed List'),
              ],
            ),
          )),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static String _getListName(String? listId, List<ShoppingListEntry> shoppingLists) {
    if (listId == null) return 'My Shopping List';
    try {
      final list = shoppingLists.firstWhere((l) => l.id == listId);
      return list.name ?? 'My Shopping List';
    } catch (e) {
      return 'My Shopping List';
    }
  }

  static Future<void> _addToShoppingList({
    required BuildContext context,
    required WidgetRef ref,
    required _AddToShoppingListController controller,
    required List<AggregatedIngredient> ingredients,
  }) async {
    controller.setLoading(true);

    try {
      final shoppingListRepository = ref.read(shoppingListRepositoryProvider);
      final currentListId = ref.read(currentShoppingListProvider);

      // Add checked ingredients to shopping list
      for (final ingredient in ingredients) {
        if (controller.checkedState[ingredient.id] ?? false) {
          await shoppingListRepository.addItem(
            shoppingListId: currentListId,
            name: ingredient.name,
            terms: ingredient.terms,
            category: ingredient.matchingPantryItem?.category,
            userId: null,
            householdId: null,
          );
        }
      }

      // Close modal
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
      controller.setLoading(false);
    }
  }
}

// Content slivers widget - matches pattern from update_pantry_modal.dart
class _AddToShoppingListContentSlivers extends ConsumerWidget {
  final AsyncValue<List<AggregatedIngredient>> aggregatedIngredientsAsync;
  final _AddToShoppingListController controller;
  final String date;

  const _AddToShoppingListContentSlivers({
    required this.aggregatedIngredientsAsync,
    required this.controller,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return aggregatedIngredientsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(
          child: Text(
            'Error loading ingredients: $error',
            style: TextStyle(
              color: CupertinoColors.destructiveRed.resolveFrom(context),
            ),
          ),
        ),
      ),
      data: (aggregatedIngredients) {
        // Initialize checked state for ingredients (notifies listeners if state changed)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.initializeCheckedState(aggregatedIngredients);
        });

        if (aggregatedIngredients.isEmpty) {
          return SliverFillRemaining(
            child: AddToShoppingListModalPage._buildEmptyState(context),
          );
        }

        // Wrap in ListenableBuilder so content rebuilds when controller state changes
        return ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            // Build widgets for the list
            final List<Widget> widgets = [];

            // Shopping list selector
            widgets.add(AddToShoppingListModalPage._buildShoppingListSelector(context, ref));
            widgets.add(SizedBox(height: AppSpacing.lg));

            // Ingredient list items
            for (int index = 0; index < aggregatedIngredients.length; index++) {
              final ingredient = aggregatedIngredients[index];
              final isChecked = controller.checkedState[ingredient.id] ?? ingredient.isChecked;
              final isFirst = index == 0;
              final isLast = index == aggregatedIngredients.length - 1;

              widgets.add(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _IngredientTile(
                    ingredient: ingredient,
                    isChecked: isChecked,
                    isFirst: isFirst,
                    isLast: isLast,
                    onChanged: (value) {
                      controller.updateCheckedState(ingredient.id, value);
                    },
                  ),
                ),
              );
            }

            // Bottom padding for sticky action bar
            widgets.add(SizedBox(height: 130));

            return SliverList(
              delegate: SliverChildListDelegate(widgets),
            );
          },
        );
      },
    );
  }
}

// Ingredient tile widget with grouped list styling
class _IngredientTile extends StatelessWidget {
  final AggregatedIngredient ingredient;
  final bool isChecked;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _IngredientTile({
    required this.ingredient,
    required this.isChecked,
    required this.isFirst,
    required this.isLast,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Get grouped styling
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

    return Container(
      decoration: BoxDecoration(
        color: colors.input,
        border: border,
        borderRadius: borderRadius,
      ),
      child: GestureDetector(
        onTap: () => onChanged(!isChecked),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circle checkbox (24px)
              AppRadioButton(
                selected: isChecked,
                onTap: () => onChanged(!isChecked),
              ),

              SizedBox(width: AppSpacing.md),

              // Ingredient info (Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From ${ingredient.sourcesDisplay}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: AppSpacing.md),

              // Stock status chip (80px width, right-aligned)
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _StockStatusChip(pantryItem: ingredient.matchingPantryItem),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stock status chip widget
class _StockStatusChip extends StatelessWidget {
  final PantryItemEntry? pantryItem;

  const _StockStatusChip({this.pantryItem});

  @override
  Widget build(BuildContext context) {
    if (pantryItem == null) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(context);
    Color backgroundColor;
    Color textColor;
    String label;

    switch (pantryItem!.stockStatus) {
      case StockStatus.outOfStock:
        backgroundColor = colors.errorBackground;
        textColor = colors.error;
        label = 'Out';
      case StockStatus.lowStock:
        backgroundColor = colors.warningBackground;
        textColor = colors.warning;
        label = 'Low';
      case StockStatus.inStock:
        backgroundColor = colors.successBackground;
        textColor = colors.success;
        label = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}