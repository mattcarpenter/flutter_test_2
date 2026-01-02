import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/pantry_items.dart';
import '../../../localization/l10n_extension.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../services/ingredient_parser_service.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/stock_chip.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../shopping_list/widgets/shopping_lists_content.dart';
import '../../shopping_list/widgets/create_list_content.dart';
import '../providers/meal_plan_shopping_list_provider.dart';
import '../models/aggregated_ingredient.dart';

// Global controller instance (like ingredient_matches_bottom_sheet pattern)
final _addToShoppingListController = _AddToShoppingListController();

void showAddToShoppingListModal(BuildContext context, String date) {
  // Reset controller state when opening modal
  _addToShoppingListController.reset();

  final pageIndexNotifier = ValueNotifier<int>(0);

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageIndexNotifier: pageIndexNotifier,
    pageListBuilder: (modalContext) => [
      // Page 0: Add to Shopping List
      _buildAddToShoppingListPage(
        modalContext: modalContext,
        date: date,
        pageIndexNotifier: pageIndexNotifier,
      ),
      // Page 1: Manage Lists
      _buildManageListsPage(
        modalContext: modalContext,
        pageIndexNotifier: pageIndexNotifier,
      ),
      // Page 2: Create New List
      _buildCreateListPage(
        modalContext: modalContext,
        pageIndexNotifier: pageIndexNotifier,
      ),
    ],
  );
}

// ============================================================================
// Page 0: Add to Shopping List
// ============================================================================

SliverWoltModalSheetPage _buildAddToShoppingListPage({
  required BuildContext modalContext,
  required String date,
  required ValueNotifier<int> pageIndexNotifier,
}) {
  return SliverWoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(modalContext).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    hasSabGradient: true,
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () => Navigator.of(modalContext).pop(),
      ),
    ),
    stickyActionBar: Consumer(
      builder: (consumerContext, ref, child) {
        return Container(
          color: AppColors.of(modalContext).background,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: ListenableBuilder(
              listenable: _addToShoppingListController,
              builder: (buttonContext, child) {
                return AppButtonVariants.primaryFilled(
                  text: _addToShoppingListController.isLoading
                      ? buttonContext.l10n.recipeAddToShoppingListAdding
                      : buttonContext.l10n.recipeAddToShoppingListButton,
                  size: AppButtonSize.large,
                  shape: AppButtonShape.square,
                  fullWidth: true,
                  onPressed: _addToShoppingListController.isButtonEnabled
                      ? () async {
                          await _addToShoppingListController.addToShoppingList(
                            Navigator.of(consumerContext),
                            ref,
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
          return _AddToShoppingListContent(
            date: date,
            pageIndexNotifier: pageIndexNotifier,
            controller: _addToShoppingListController,
          );
        },
      ),
    ],
  );
}

// ============================================================================
// Page 1: Manage Lists
// ============================================================================

WoltModalSheetPage _buildManageListsPage({
  required BuildContext modalContext,
  required ValueNotifier<int> pageIndexNotifier,
}) {
  return WoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(modalContext).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    leadingNavBarWidget: Padding(
      padding: EdgeInsets.only(left: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.back,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () {
          pageIndexNotifier.value = 0;
        },
      ),
    ),
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () => Navigator.of(modalContext).pop(),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            modalContext.l10n.shoppingListManageLists,
            style: AppTypography.h4.copyWith(
              color: AppColors.of(modalContext).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          ShoppingListsContent(
            showSelection: false,
            showCreateButton: true,
            allowDelete: true,
            onCreateList: () {
              pageIndexNotifier.value = 2;
            },
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// Page 2: Create New List
// ============================================================================

WoltModalSheetPage _buildCreateListPage({
  required BuildContext modalContext,
  required ValueNotifier<int> pageIndexNotifier,
}) {
  return WoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(modalContext).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    leadingNavBarWidget: Padding(
      padding: EdgeInsets.only(left: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.back,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () {
          pageIndexNotifier.value = 1;
        },
      ),
    ),
    trailingNavBarWidget: Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: AppCircleButton(
        icon: AppCircleButtonIcon.close,
        variant: AppCircleButtonVariant.neutral,
        size: 32,
        onPressed: () => Navigator.of(modalContext).pop(),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            modalContext.l10n.shoppingListCreateNew,
            style: AppTypography.h4.copyWith(
              color: AppColors.of(modalContext).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          CreateListContent(
            onCreated: () {
              pageIndexNotifier.value = 1;
            },
          ),
        ],
      ),
    ),
  );
}

// ============================================================================
// Controller
// ============================================================================

class _AddToShoppingListController extends ChangeNotifier {
  // Track checked state per ingredient
  final Map<String, bool> checkedState = {};

  // Track selected list per ingredient (list ID, null = default)
  final Map<String, String?> selectedListIds = {};

  // Addable ingredients (not already in a list)
  List<AggregatedIngredient> addableIngredients = [];

  // Parser for ingredient names
  final _parser = IngredientParserService();

  bool isLoading = false;
  bool initialized = false;

  void reset() {
    checkedState.clear();
    selectedListIds.clear();
    addableIngredients = [];
    isLoading = false;
    initialized = false;
  }

  void updateCheckedState(String id, bool value) {
    checkedState[id] = value;
    notifyListeners();
  }

  void updateSelectedList(String id, String? listId) {
    selectedListIds[id] = listId;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  int get checkedCount => checkedState.entries
      .where((e) => e.value && addableIngredients.any((i) => i.id == e.key))
      .length;

  bool get isButtonEnabled => checkedCount > 0 && !isLoading;

  String _getCleanName(String name) {
    final parseResult = _parser.parse(name);
    return parseResult.cleanName.isNotEmpty ? parseResult.cleanName : name;
  }

  Future<void> addToShoppingList(NavigatorState navigator, WidgetRef ref) async {
    setLoading(true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // Group items by list
      final itemsByList = <String?, List<String>>{};

      for (final ingredient in addableIngredients) {
        final id = ingredient.id;
        if (checkedState[id] == true) {
          final listId = selectedListIds[id];
          itemsByList.putIfAbsent(listId, () => []);
          itemsByList[listId]!.add(_getCleanName(ingredient.name));
        }
      }

      // Add items to each list
      for (final entry in itemsByList.entries) {
        final listId = entry.key;
        final items = entry.value;

        final itemsNotifier = ref.read(shoppingListItemsProvider(listId).notifier);

        for (final itemName in items) {
          await itemsNotifier.addItem(
            name: itemName,
            userId: userId,
          );
        }
      }

      // Close the modal
      navigator.pop();
    } catch (e) {
      AppLogger.error('Error adding meal plan items to shopping list', e);
      setLoading(false);
    }
  }
}

// ============================================================================
// Content Widget
// ============================================================================

class _AddToShoppingListContent extends ConsumerStatefulWidget {
  final String date;
  final ValueNotifier<int> pageIndexNotifier;
  final _AddToShoppingListController controller;

  const _AddToShoppingListContent({
    required this.date,
    required this.pageIndexNotifier,
    required this.controller,
  });

  @override
  ConsumerState<_AddToShoppingListContent> createState() =>
      _AddToShoppingListContentState();
}

class _AddToShoppingListContentState
    extends ConsumerState<_AddToShoppingListContent> {
  final _parser = IngredientParserService();

  _AddToShoppingListController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Watch shopping lists and current selection
    final listsAsync = ref.watch(shoppingListsProvider);
    final currentListId = ref.watch(currentShoppingListProvider);

    // Watch the aggregated ingredients
    final ingredientsAsync = ref.watch(aggregatedIngredientsProvider(widget.date));

    return listsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(child: Text('Error: $error')),
      ),
      data: (lists) {
        return ingredientsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (ingredients) {
            // Initialize state on first build
            if (!controller.initialized) {
              _initializeState(ingredients, currentListId);
              controller.initialized = true;
            }

            // Separate ingredients into addable vs already in list
            final addableIngredients = <AggregatedIngredient>[];
            final alreadyInListIngredients = <AggregatedIngredient>[];

            for (final ingredient in ingredients) {
              if (ingredient.existsInShoppingList) {
                alreadyInListIngredients.add(ingredient);
              } else {
                addableIngredients.add(ingredient);
              }
            }

            // Sort addable by stock status
            addableIngredients.sort((a, b) =>
                _getSortPriority(a).compareTo(_getSortPriority(b)));

            // Update controller's addable ingredients for button state
            controller.addableIngredients = addableIngredients;

            // Build widget list
            final List<Widget> widgets = [];

            // Title row with Manage Lists button
            widgets.add(
              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.recipeAddToShoppingList,
                      style: AppTypography.h4.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    AppButton(
                      text: context.l10n.shoppingListManageLists,
                      onPressed: () {
                        widget.pageIndexNotifier.value = 1;
                      },
                      trailingIcon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14),
                      compactTrailingIcon: true,
                      theme: AppButtonTheme.secondary,
                      style: AppButtonStyle.outline,
                      shape: AppButtonShape.square,
                      size: AppButtonSize.small,
                    ),
                  ],
                ),
              ),
            );

            widgets.add(SizedBox(height: AppSpacing.sm));

            // Empty state
            if (addableIngredients.isEmpty && alreadyInListIngredients.isEmpty) {
              widgets.add(
                Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedShoppingCart01,
                          size: 64,
                          color: colors.textTertiary,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          context.l10n.recipeAddToShoppingListNoIngredients,
                          style: AppTypography.body.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.mealPlanAllIngredientsInPantry,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Addable ingredients list
            if (addableIngredients.isNotEmpty) {
              for (int index = 0; index < addableIngredients.length; index++) {
                final ingredient = addableIngredients[index];
                final isFirst = index == 0;
                final isLast = index == addableIngredients.length - 1 &&
                    alreadyInListIngredients.isEmpty;

                widgets.add(
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildIngredientRow(
                      context,
                      ingredient,
                      lists,
                      currentListId,
                      isFirst: isFirst,
                      isLast: isLast,
                    ),
                  ),
                );
              }
            }

            // Already in list section
            if (alreadyInListIngredients.isNotEmpty) {
              for (int index = 0;
                  index < alreadyInListIngredients.length;
                  index++) {
                final ingredient = alreadyInListIngredients[index];
                final isFirst = index == 0 && addableIngredients.isEmpty;
                final isLast = index == alreadyInListIngredients.length - 1;

                widgets.add(
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildAlreadyInListRow(
                      context,
                      ingredient,
                      isFirst: isFirst,
                      isLast: isLast,
                    ),
                  ),
                );
              }
            }

            // Bottom padding for sticky action bar
            widgets.add(const SizedBox(height: 130));

            return SliverList(
              delegate: SliverChildListDelegate(widgets),
            );
          },
        );
      },
    );
  }

  void _initializeState(
    List<AggregatedIngredient> ingredients,
    String? defaultListId,
  ) {
    for (final ingredient in ingredients) {
      final id = ingredient.id;

      // Skip items already in a list
      if (ingredient.existsInShoppingList) continue;

      // Pre-check out of stock and low stock items
      if (!controller.checkedState.containsKey(id)) {
        final pantryItem = ingredient.matchingPantryItem;
        final isOutOrLow = pantryItem == null ||
            pantryItem.stockStatus == StockStatus.outOfStock ||
            pantryItem.stockStatus == StockStatus.lowStock;
        controller.checkedState[id] = isOutOrLow;
      }

      // Default list selection
      if (!controller.selectedListIds.containsKey(id)) {
        controller.selectedListIds[id] = defaultListId;
      }
    }
  }

  int _getSortPriority(AggregatedIngredient ingredient) {
    final pantryItem = ingredient.matchingPantryItem;
    if (pantryItem != null) {
      final status = pantryItem.stockStatus;
      if (status == StockStatus.outOfStock) return 1;
      if (status == StockStatus.lowStock) return 2;
      if (status == StockStatus.inStock) return 3;
    }
    return 0; // No match at top (most likely to need)
  }

  String _getCleanName(String name) {
    final parseResult = _parser.parse(name);
    return parseResult.cleanName.isNotEmpty ? parseResult.cleanName : name;
  }

  Widget _buildStockChip(AggregatedIngredient ingredient) {
    final pantryItem = ingredient.matchingPantryItem;
    if (pantryItem == null) {
      return StockChip(showNotInPantry: true);
    }
    return StockChip(status: pantryItem.stockStatus);
  }

  Widget _buildIngredientRow(
    BuildContext context,
    AggregatedIngredient ingredient,
    List<ShoppingListEntry> lists,
    String? defaultListId, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);
    final displayName = _getCleanName(ingredient.name);
    final isChecked = controller.checkedState[ingredient.id] ?? false;
    final selectedListId =
        controller.selectedListIds[ingredient.id] ?? defaultListId;

    // Get list name for display
    String listName = context.l10n.recipeAddToShoppingListDefault;
    if (selectedListId != null) {
      final list = lists.where((l) => l.id == selectedListId).firstOrNull;
      listName = list?.name ?? context.l10n.recipeAddToShoppingListDefault;
    }

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
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                controller.updateCheckedState(ingredient.id, !isChecked);
              },
              child: AppRadioButton(
                selected: isChecked,
                onTap: () {
                  controller.updateCheckedState(ingredient.id, !isChecked);
                },
              ),
            ),

            SizedBox(width: AppSpacing.md),

            // Ingredient info (name + stock chip below)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  _buildStockChip(ingredient),
                ],
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // List dropdown (styled like duration picker chips)
            AdaptivePullDownButton(
              items: [
                AdaptiveMenuItem(
                  title: context.l10n.recipeAddToShoppingListDefault,
                  icon: selectedListId == null
                      ? Icon(CupertinoIcons.checkmark)
                      : HugeIcon(icon: HugeIcons.strokeRoundedLeftToRightListBullet),
                  onTap: () {
                    controller.updateSelectedList(ingredient.id, null);
                    if (!isChecked) {
                      controller.updateCheckedState(ingredient.id, true);
                    }
                  },
                ),
                ...lists.map((list) => AdaptiveMenuItem(
                      title: list.name ?? context.l10n.shoppingListUnnamed,
                      icon: selectedListId == list.id
                          ? Icon(CupertinoIcons.checkmark)
                          : HugeIcon(icon: HugeIcons.strokeRoundedLeftToRightListBullet),
                      onTap: () {
                        controller.updateSelectedList(ingredient.id, list.id);
                        if (!isChecked) {
                          controller.updateCheckedState(ingredient.id, true);
                        }
                      },
                    )),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        listName,
                        style: TextStyle(
                          color: colors.chipText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: colors.chipText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyInListRow(
    BuildContext context,
    AggregatedIngredient ingredient, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);
    final displayName = _getCleanName(ingredient.name);

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
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Spacer instead of checkbox (for alignment)
            SizedBox(width: 24 + AppSpacing.md),

            // Ingredient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textTertiary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.mealPlanAlreadyOnShoppingList,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
