import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/src/providers/shopping_list_provider.dart';
import 'package:recipe_app/src/services/ingredient_parser_service.dart';
import 'package:recipe_app/src/theme/colors.dart';
import 'package:recipe_app/src/theme/spacing.dart';
import 'package:recipe_app/src/theme/typography.dart';
import 'package:recipe_app/src/widgets/app_button.dart';
import 'package:recipe_app/src/widgets/app_circle_button.dart';
import 'package:recipe_app/src/widgets/app_radio_button.dart';
import 'package:recipe_app/src/widgets/stock_chip.dart';
import 'package:recipe_app/src/widgets/utils/grouped_list_styling.dart';
import 'package:recipe_app/src/widgets/wolt/text/modal_sheet_title.dart';
import 'package:recipe_app/src/features/shopping_list/views/shopping_list_selection_modal.dart';
import 'package:recipe_app/src/features/meal_plans/models/aggregated_ingredient.dart';
import '../../../../localization/l10n_extension.dart';

void showAddRecipeIngredientsToShoppingListModal(
  BuildContext context,
  List<AggregatedIngredient> ingredients,
) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      _AddRecipeIngredientsToShoppingListModalPage.build(
        context: modalContext,
        ingredients: ingredients,
      ),
    ],
  );
}

// Controller for managing checked state
class _AddRecipeIngredientsController extends ChangeNotifier {
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

class _AddRecipeIngredientsToShoppingListModalPage {
  _AddRecipeIngredientsToShoppingListModalPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext context,
    required List<AggregatedIngredient> ingredients,
  }) {
    final controller = _AddRecipeIngredientsController();

    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      hasSabGradient: true,
      topBarTitle: ModalSheetTitle(context.l10n.recipeAddToShoppingList),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
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
                  return AppButtonVariants.primaryFilled(
                    text: controller.isLoading ? context.l10n.recipeAddToShoppingListAdding : context.l10n.recipeAddToShoppingListButton,
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
            // Initialize checked state for ingredients
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.initializeCheckedState(ingredients);
            });

            if (ingredients.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(context),
              );
            }

            // Wrap in ListenableBuilder so content rebuilds when controller state changes
            return ListenableBuilder(
              listenable: controller,
              builder: (context, child) {
                // Build widgets for the list
                final List<Widget> widgets = [];

                // Shopping list selector
                widgets.add(_buildShoppingListSelector(context, ref));
                widgets.add(SizedBox(height: AppSpacing.lg));

                // Ingredient list items
                for (int index = 0; index < ingredients.length; index++) {
                  final ingredient = ingredients[index];
                  final isChecked = controller.checkedState[ingredient.id] ?? ingredient.isChecked;
                  final isFirst = index == 0;
                  final isLast = index == ingredients.length - 1;

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
        ),
      ],
    );
  }

  static Widget _buildShoppingListSelector(BuildContext context, WidgetRef ref) {
    final currentListId = ref.watch(currentShoppingListProvider);
    final shoppingListsAsync = ref.watch(shoppingListsProvider);
    final shoppingLists = shoppingListsAsync.valueOrNull ?? [];

    // Get current list name
    String listName = context.l10n.recipeAddToShoppingListDefault;
    if (currentListId != null) {
      final list = shoppingLists.where((l) => l.id == currentListId).firstOrNull;
      listName = list?.name ?? context.l10n.recipeAddToShoppingListDefault;
    }

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
            child: AppButton(
              text: listName,
              trailingIcon: const Icon(Icons.keyboard_arrow_down, size: 24),
              trailingIconOffset: const Offset(8, -2),
              style: AppButtonStyle.mutedOutline,
              shape: AppButtonShape.square,
              size: AppButtonSize.medium,
              theme: AppButtonTheme.primary,
              fullWidth: true,
              contentAlignment: AppButtonContentAlignment.left,
              onPressed: () => showShoppingListSelectionModal(context, ref),
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
          HugeIcon(
            icon: HugeIcons.strokeRoundedShoppingCart01,
            size: 64,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.recipeAddToShoppingListNoIngredients,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All ingredients are either in your pantry with sufficient stock.',
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

  static Future<void> _addToShoppingList({
    required BuildContext context,
    required WidgetRef ref,
    required _AddRecipeIngredientsController controller,
    required List<AggregatedIngredient> ingredients,
  }) async {
    controller.setLoading(true);

    try {
      final shoppingListRepository = ref.read(shoppingListRepositoryProvider);
      final currentListId = ref.read(currentShoppingListProvider);
      final parser = IngredientParserService();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // Add checked ingredients to shopping list
      for (final ingredient in ingredients) {
        if (controller.checkedState[ingredient.id] ?? false) {
          // Prefer displayName if available, fall back to parsed cleanName
          String itemName;
          if (ingredient.displayName != null && ingredient.displayName!.isNotEmpty) {
            itemName = ingredient.displayName!;
          } else {
            // Parse ingredient name to strip quantities and units
            final parseResult = parser.parse(ingredient.name);
            itemName = parseResult.cleanName.isNotEmpty
                ? parseResult.cleanName
                : ingredient.name;
          }

          await shoppingListRepository.addItem(
            shoppingListId: currentListId,
            name: itemName,
            userId: userId,
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

// Ingredient tile widget with grouped list styling
class _IngredientTile extends StatelessWidget {
  final AggregatedIngredient ingredient;
  final bool isChecked;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  static final _parser = IngredientParserService();

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

    // Prefer displayName if available, fall back to parsed cleanName
    String displayText;
    if (ingredient.displayName != null && ingredient.displayName!.isNotEmpty) {
      displayText = ingredient.displayName!;
    } else {
      // Parse ingredient name to strip quantities and units
      final parseResult = _parser.parse(ingredient.name);
      displayText = parseResult.cleanName.isNotEmpty
          ? parseResult.cleanName
          : ingredient.name;
    }

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
        color: colors.groupedListBackground,
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
                child: Text(
                  displayText,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              SizedBox(width: AppSpacing.md),

              // Stock status chip (80px width, right-aligned)
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StockChip(status: ingredient.matchingPantryItem?.stockStatus),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
