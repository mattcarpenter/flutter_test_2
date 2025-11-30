import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/database/models/pantry_items.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' show recipeIngredientMatchesProvider, recipeByIdStreamProvider;
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/shopping_list_provider.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart' show recipeRepositoryProvider;
import 'package:recipe_app/src/theme/colors.dart';
import 'package:recipe_app/src/theme/spacing.dart';
import 'package:recipe_app/src/theme/typography.dart';
import 'package:recipe_app/src/widgets/app_button.dart';
import 'package:recipe_app/src/widgets/app_circle_button.dart';
import 'package:recipe_app/src/widgets/app_radio_button.dart';
import 'package:recipe_app/src/widgets/app_text_field_simple.dart';
import 'package:recipe_app/src/widgets/ingredient_stock_chip.dart';
import 'package:recipe_app/src/widgets/stock_chip.dart';
import 'package:recipe_app/src/widgets/utils/grouped_list_styling.dart';
import 'package:recipe_app/src/widgets/adaptive_pull_down/adaptive_pull_down.dart';
import 'package:recipe_app/src/widgets/adaptive_pull_down/adaptive_menu_item.dart';
import 'package:recipe_app/src/services/ingredient_parser_service.dart';
import 'package:recipe_app/src/services/logging/app_logger.dart';
import 'package:recipe_app/src/features/shopping_list/widgets/shopping_lists_content.dart';
import 'package:recipe_app/src/features/shopping_list/widgets/create_list_content.dart';

// Controller for Add to Shopping List page (no GlobalKey needed)
final _addToShoppingListController = _AddToShoppingListController();

/// Builds the Add to Shopping List page with controller and sticky action bar
SliverWoltModalSheetPage _buildAddToShoppingListPage({
  required BuildContext modalContext,
  required RecipeIngredientMatches matches,
  required ValueNotifier<int> pageIndexNotifier,
}) {
  return SliverWoltModalSheetPage(
    navBarHeight: 55,
    backgroundColor: AppColors.of(modalContext).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    hasSabGradient: true,
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
    stickyActionBar: ListenableBuilder(
      listenable: _addToShoppingListController,
      builder: (context, _) {
        final controller = _addToShoppingListController;
        final checkedCount = controller.checkedCount;
        final isLoading = controller.isLoading;
        final isEnabled = controller.isButtonEnabled;

        return Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: AppButtonVariants.primaryFilled(
              text: isLoading
                  ? 'Adding...'
                  : checkedCount > 0
                      ? 'Add $checkedCount Item${checkedCount == 1 ? '' : 's'}'
                      : 'Add Items',
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              fullWidth: true,
              onPressed: isEnabled
                  ? () {
                      // Call the controller's addToShoppingList directly
                      controller.addToShoppingList(Navigator.of(modalContext));
                    }
                  : null,
            ),
          ),
        );
      },
    ),
    mainContentSliversBuilder: (context) => [
      SliverToBoxAdapter(
        child: AddToShoppingListPage(
          matches: matches,
          pageIndexNotifier: pageIndexNotifier,
          controller: _addToShoppingListController,
        ),
      ),
    ],
  );
}

/// Shows a bottom sheet displaying ingredient-pantry match details
/// with ability to edit the ingredient terms for better matching
void showIngredientMatchesBottomSheet(
  BuildContext context, {
  required RecipeIngredientMatches matches,
}) {
  // Ensure all ingredients have been properly initialized in the matches object
  if (matches.matches.isEmpty && matches.recipeId.isNotEmpty) {
    debugPrint("Warning: No matches found for recipe ${matches.recipeId}");
  }

  // Reset the controller state for fresh modal
  _addToShoppingListController.reset();

  // Page navigation state
  final pageIndexNotifier = ValueNotifier<int>(0);

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageIndexNotifier: pageIndexNotifier,
    pageListBuilder: (modalContext) {
      return [
        // Page 0: Ingredient list with navigational button
        SliverWoltModalSheetPage(
          navBarHeight: 55,
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: false,
          trailingNavBarWidget: Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              size: 32,
              onPressed: () {
                Navigator.of(modalContext).pop();
              },
            ),
          ),
          mainContentSliversBuilder: (context) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Recipe Ingredients',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.of(modalContext).textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    IngredientMatchesListPage(
                      matches: matches,
                      pageIndexNotifier: pageIndexNotifier,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Page 1: Add to Shopping List
        _buildAddToShoppingListPage(
          modalContext: modalContext,
          matches: matches,
          pageIndexNotifier: pageIndexNotifier,
        ),
        // Page 2: Manage Lists
        WoltModalSheetPage(
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
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Manage Lists',
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
                    pageIndexNotifier.value = 3;
                  },
                ),
              ],
            ),
          ),
        ),
        // Page 3: Create New List
        WoltModalSheetPage(
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
                pageIndexNotifier.value = 2;
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
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create New List',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.of(modalContext).textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                CreateListContent(
                  onCreated: () {
                    pageIndexNotifier.value = 2;
                  },
                ),
              ],
            ),
          ),
        ),
        // Page 4: Individual ingredient detail (was Page 1)
        WoltModalSheetPage(
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: IngredientDetailPage(
              matches: matches,
              pageIndexNotifier: pageIndexNotifier,
            ),
          ),
        ),
        // Page 5: Add custom term (was Page 2)
        WoltModalSheetPage(
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
                pageIndexNotifier.value = 4;
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
          child: AddCustomTermPage(
            matches: matches,
            pageIndexNotifier: pageIndexNotifier,
          ),
        ),
        // Page 6: Select from pantry (was Page 3)
        SliverWoltModalSheetPage(
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
                pageIndexNotifier.value = 4;
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
          mainContentSliversBuilder: (context) => [
            SliverToBoxAdapter(
              child: SelectFromPantryPage(
                matches: matches,
                pageIndexNotifier: pageIndexNotifier,
              ),
            ),
          ],
        ),
      ];
    },
  );
}

// ============================================================================
// Page 0: Ingredient List
// ============================================================================

class IngredientMatchesListPage extends ConsumerWidget {
  final RecipeIngredientMatches matches;
  final ValueNotifier<int> pageIndexNotifier;

  // Parser for ingredient text formatting
  final _parser = IngredientParserService();

  IngredientMatchesListPage({
    super.key,
    required this.matches,
    required this.pageIndexNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live matches provider to get real-time updates
    final matchesAsync = ref.watch(recipeIngredientMatchesProvider(matches.recipeId));

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (currentMatches) {
        // Sort matches by stock status
        final sortedMatches = List<IngredientPantryMatch>.from(currentMatches.matches)
          ..sort((a, b) => _getSortPriority(a).compareTo(_getSortPriority(b)));

        // Calculate metrics
        final total = currentMatches.matches.length;

        // In Stock: Items with direct pantry match (in/low stock) OR makeable via sub-recipe
        final available = currentMatches.matches.where((m) {
          if (m.hasPantryMatch) {
            // Direct pantry match - check if in stock or low stock
            return m.pantryItem!.stockStatus == StockStatus.inStock ||
                   m.pantryItem!.stockStatus == StockStatus.lowStock;
          } else if (m.hasRecipeMatch) {
            // Can be made via sub-recipe (shown as "in stock" by the chip)
            return true;
          }
          return false;
        }).length;

        // Out of Stock: Items with direct pantry match but marked as out of stock
        final outOfStock = currentMatches.matches.where((m) =>
          m.hasPantryMatch && m.pantryItem!.stockStatus == StockStatus.outOfStock
        ).length;

        // Not in Pantry: Items with NO match at all (no pantry match AND no recipe match)
        final notInPantry = currentMatches.matches.where((m) => !m.hasMatch).length;

        // Build status lines
        final statusLines = _buildStatusLines(
          total: total,
          available: available,
          outOfStock: outOfStock,
          notInPantry: notInPantry,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status message and Add to Shopping List button on same row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status lines
                if (statusLines.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: statusLines.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Only show bullet point if there are multiple lines
                            if (statusLines.length > 1)
                              Text(
                                '• ',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.of(context).textSecondary,
                                ),
                              ),
                            Expanded(
                              child: _buildLineWithBoldNumbers(context, line),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  )
                else
                  const Spacer(),

                // Add to Shopping List button
                AppButton(
                  text: 'Add to Shopping List',
                  onPressed: () {
                    pageIndexNotifier.value = 1;
                  },
                  theme: AppButtonTheme.secondary,
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.small,
                  trailingIcon: const Icon(Icons.chevron_right, size: 18),
                  compactTrailingIcon: true,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),

            // Ingredient list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: sortedMatches.length,
              itemBuilder: (context, index) {
                final match = sortedMatches[index];
                return _buildIngredientRow(
                  context,
                  match,
                  index,
                  sortedMatches.length,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildIngredientRow(
    BuildContext context,
    IngredientPantryMatch match,
    int index,
    int totalCount,
  ) {
    final colors = AppColors.of(context);
    final ingredient = match.ingredient;

    // Parse ingredient name to get clean name without quantities/units
    final parseResult = _parser.parse(ingredient.name);
    final displayName = parseResult.cleanName.isNotEmpty
        ? parseResult.cleanName
        : ingredient.name;

    // Calculate position in group
    final isFirst = index == 0;
    final isLast = index == totalCount - 1;

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
      child: InkWell(
        onTap: () {
          // Store selected ingredient ID for ingredient detail page
          IngredientDetailPage.selectedIngredientId = match.ingredient.id;
          pageIndexNotifier.value = 4;
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ingredient name (parsed to remove quantities/units)
              Expanded(
                child: Text(
                  displayName,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              SizedBox(width: AppSpacing.md),

              // Stock status chip
              Align(
                alignment: Alignment.centerRight,
                child: _buildStockChip(match),
              ),

              SizedBox(width: AppSpacing.md),

              // Right chevron
              Icon(
                Icons.chevron_right,
                color: colors.contentSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockChip(IngredientPantryMatch match) {
    // If no match, show "Not in Pantry" chip
    if (!match.hasMatch) {
      return StockChip(showNotInPantry: true);
    }

    // Otherwise, use the standard IngredientStockChip
    return IngredientStockChip(match: match);
  }

  int _getSortPriority(IngredientPantryMatch match) {
    // Priority order: in stock (1) -> low stock (2) -> out of stock (3) -> not in pantry (4)
    if (match.hasPantryMatch) {
      final status = match.pantryItem!.stockStatus;
      if (status == StockStatus.inStock) {
        return 1;
      } else if (status == StockStatus.lowStock) {
        return 2;
      } else if (status == StockStatus.outOfStock) {
        return 3;
      }
    } else if (match.hasRecipeMatch) {
      // Items makeable via sub-recipe are treated as "in stock"
      return 1;
    }
    // No match at all
    return 4;
  }

  List<String> _buildStatusLines({
    required int total,
    required int available,
    required int outOfStock,
    required int notInPantry,
  }) {
    // If all available, show positive message
    if (available == total) {
      return ['All $total ingredient${total == 1 ? '' : 's'} available'];
    }

    // Start with availability fraction
    final lines = <String>['$available of $total items available'];

    // Add problems
    if (outOfStock > 0) {
      lines.add('$outOfStock out of stock');
    }
    if (notInPantry > 0) {
      lines.add('$notInPantry not in pantry');
    }

    return lines;
  }

  Widget _buildLineWithBoldNumbers(BuildContext context, String line) {
    final colors = AppColors.of(context);
    final baseStyle = AppTypography.body.copyWith(
      color: colors.textSecondary,
    );
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w600,
    );

    // Split the line by numbers and rebuild with bold numbers
    final regex = RegExp(r'(\d+)');
    final matches = regex.allMatches(line);

    if (matches.isEmpty) {
      return Text(line, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before the number
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      // Add the number with bold style
      spans.add(TextSpan(
        text: match.group(0),
        style: boldStyle,
      ));
      lastEnd = match.end;
    }

    // Add remaining text after the last number
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }
}

// ============================================================================
// Page 1: Add to Shopping List
// ============================================================================

/// Controller for managing Add to Shopping List page state
class _AddToShoppingListController extends ChangeNotifier {
  // Track checked state per ingredient
  final Map<String, bool> checkedState = {};

  // Track selected list per ingredient (list ID, null = default)
  final Map<String, String?> selectedListIds = {};

  // Addable ingredients (not already in a list)
  List<IngredientPantryMatch> addableIngredients = [];

  // Reference to WidgetRef for adding items (set by the page widget)
  WidgetRef? _ref;

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
    _ref = null;
  }

  void setRef(WidgetRef ref) {
    _ref = ref;
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
      .where((e) => e.value && addableIngredients.any((m) => m.ingredient.id == e.key))
      .length;

  bool get isButtonEnabled => checkedCount > 0 && !isLoading;

  String _getCleanName(String name) {
    final parseResult = _parser.parse(name);
    return parseResult.cleanName.isNotEmpty ? parseResult.cleanName : name;
  }

  Future<void> addToShoppingList(NavigatorState navigator) async {
    if (_ref == null) return;
    final ref = _ref!;

    setLoading(true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // Group items by list
      final itemsByList = <String?, List<String>>{};

      for (final match in addableIngredients) {
        final id = match.ingredient.id;
        if (checkedState[id] == true) {
          final listId = selectedListIds[id];
          itemsByList.putIfAbsent(listId, () => []);
          itemsByList[listId]!.add(_getCleanName(match.ingredient.name));
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
      AppLogger.error('Error adding items to shopping list', e);
      setLoading(false);
    }
  }
}

class AddToShoppingListPage extends ConsumerStatefulWidget {
  final RecipeIngredientMatches matches;
  final ValueNotifier<int> pageIndexNotifier;
  final _AddToShoppingListController controller;

  const AddToShoppingListPage({
    super.key,
    required this.matches,
    required this.pageIndexNotifier,
    required this.controller,
  });

  @override
  ConsumerState<AddToShoppingListPage> createState() => _AddToShoppingListPageState();
}

class _AddToShoppingListPageState extends ConsumerState<AddToShoppingListPage> {
  // Parser for ingredient text formatting
  final _parser = IngredientParserService();

  _AddToShoppingListController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Listen to controller changes to rebuild UI
    controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set the ref on the controller so it can add items
    controller.setRef(ref);
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

    // Watch the live matches to get fresh data
    final matchesAsync = ref.watch(recipeIngredientMatchesProvider(widget.matches.recipeId));

    // Watch the duplicate detection map
    final itemToListMap = ref.watch(itemToListNameMapProvider);

    return listsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (lists) {
        return matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (currentMatches) {
            // Initialize state on first build
            if (!controller.initialized) {
              _initializeState(currentMatches, currentListId, itemToListMap);
              controller.initialized = true;
            }

            // Separate ingredients into those that can be added vs already in list
            final addableIngredients = <IngredientPantryMatch>[];
            final alreadyInListIngredients = <(IngredientPantryMatch, String)>[]; // (match, listName)

            for (final match in currentMatches.matches) {
              final ingredientName = _getCleanName(match.ingredient.name);
              final existingListName = itemToListMap[ingredientName.toLowerCase().trim()];

              if (existingListName != null) {
                alreadyInListIngredients.add((match, existingListName));
              } else {
                addableIngredients.add(match);
              }
            }

            // Sort addable ingredients by stock status
            addableIngredients.sort((a, b) => _getSortPriority(a).compareTo(_getSortPriority(b)));

            // Update controller's addable ingredients for button state
            controller.addableIngredients = addableIngredients;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row with Manage Lists button
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Add to Shopping List',
                        style: AppTypography.h4.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      AppButton(
                        text: 'Manage Lists',
                        onPressed: () {
                          widget.pageIndexNotifier.value = 2;
                        },
                        trailingIcon: const Icon(CupertinoIcons.chevron_right, size: 14),
                        compactTrailingIcon: true,
                        theme: AppButtonTheme.secondary,
                        style: AppButtonStyle.outline,
                        shape: AppButtonShape.square,
                        size: AppButtonSize.small,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.sm),

                // Addable ingredients list
                if (addableIngredients.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: addableIngredients.length,
                      itemBuilder: (context, index) {
                        final match = addableIngredients[index];
                        final isFirst = index == 0;
                        final isLast = index == addableIngredients.length - 1 && alreadyInListIngredients.isEmpty;

                        return _buildIngredientRow(
                          context,
                          match,
                          lists,
                          currentListId,
                          isFirst: isFirst,
                          isLast: isLast,
                        );
                      },
                    ),
                  ),

                // Already in list section
                if (alreadyInListIngredients.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: alreadyInListIngredients.length,
                      itemBuilder: (context, index) {
                        final (match, listName) = alreadyInListIngredients[index];
                        final isFirst = index == 0 && addableIngredients.isEmpty;
                        final isLast = index == alreadyInListIngredients.length - 1;

                        return _buildAlreadyInListRow(
                          context,
                          match,
                          listName,
                          isFirst: isFirst,
                          isLast: isLast,
                        );
                      },
                    ),
                  ),

                // Empty state
                if (addableIngredients.isEmpty && alreadyInListIngredients.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No ingredients to add',
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                // Bottom padding for sticky action bar and gradient
                const SizedBox(height: 130),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStockChip(IngredientPantryMatch match) {
    // If no match, show "Not in Pantry" chip
    if (!match.hasMatch) {
      return StockChip(showNotInPantry: true);
    }

    // Otherwise, use the standard IngredientStockChip
    return IngredientStockChip(match: match);
  }

  void _initializeState(
    RecipeIngredientMatches matches,
    String? defaultListId,
    Map<String, String> itemToListMap,
  ) {
    for (final match in matches.matches) {
      final id = match.ingredient.id;
      final ingredientName = _getCleanName(match.ingredient.name);
      final existingListName = itemToListMap[ingredientName.toLowerCase().trim()];

      // Skip items already in a list
      if (existingListName != null) continue;

      // Pre-check out of stock and low stock items
      if (!controller.checkedState.containsKey(id)) {
        final isOutOrLow = !match.hasMatch ||
            (match.hasPantryMatch &&
                (match.pantryItem!.stockStatus == StockStatus.outOfStock ||
                    match.pantryItem!.stockStatus == StockStatus.lowStock));
        controller.checkedState[id] = isOutOrLow;
      }

      // Default list selection
      if (!controller.selectedListIds.containsKey(id)) {
        controller.selectedListIds[id] = defaultListId;
      }
    }
  }

  String _getCleanName(String name) {
    final parseResult = _parser.parse(name);
    return parseResult.cleanName.isNotEmpty ? parseResult.cleanName : name;
  }

  int _getSortPriority(IngredientPantryMatch match) {
    if (match.hasPantryMatch) {
      final status = match.pantryItem!.stockStatus;
      if (status == StockStatus.outOfStock) return 1;
      if (status == StockStatus.lowStock) return 2;
      if (status == StockStatus.inStock) return 3;
    } else if (match.hasRecipeMatch) {
      return 3; // Sub-recipe items at the end with in-stock
    }
    return 0; // No match at top (most likely to need)
  }

  Widget _buildIngredientRow(
    BuildContext context,
    IngredientPantryMatch match,
    List<ShoppingListEntry> lists,
    String? defaultListId, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);
    final ingredient = match.ingredient;
    final displayName = _getCleanName(ingredient.name);
    final isChecked = controller.checkedState[ingredient.id] ?? false;
    final selectedListId = controller.selectedListIds[ingredient.id] ?? defaultListId;

    // Get list name for display
    String listName = 'My Shopping List';
    if (selectedListId != null) {
      final list = lists.where((l) => l.id == selectedListId).firstOrNull;
      listName = list?.name ?? 'My Shopping List';
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

            // Ingredient info
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
                  _buildStockChip(match),
                ],
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // List dropdown (styled like duration picker chips)
            AdaptivePullDownButton(
              items: [
                AdaptiveMenuItem(
                  title: 'My Shopping List',
                  icon: Icon(selectedListId == null ? CupertinoIcons.checkmark : CupertinoIcons.list_bullet),
                  onTap: () {
                    controller.updateSelectedList(ingredient.id, null);
                    if (!isChecked) {
                      controller.updateCheckedState(ingredient.id, true);
                    }
                  },
                ),
                ...lists.map((list) => AdaptiveMenuItem(
                      title: list.name ?? 'Unnamed',
                      icon: Icon(selectedListId == list.id ? CupertinoIcons.checkmark : CupertinoIcons.list_bullet),
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
    IngredientPantryMatch match,
    String listName, {
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);
    final ingredient = match.ingredient;
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
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'In $listName',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
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

// ============================================================================
// Page 4: Ingredient Detail
// ============================================================================

class IngredientDetailPage extends ConsumerStatefulWidget {
  final RecipeIngredientMatches matches;
  final ValueNotifier<int> pageIndexNotifier;

  // Static variable to share selected ingredient ID between pages
  static String? selectedIngredientId;

  const IngredientDetailPage({
    super.key,
    required this.matches,
    required this.pageIndexNotifier,
  });

  @override
  ConsumerState<IngredientDetailPage> createState() => _IngredientDetailPageState();
}

class _IngredientDetailPageState extends ConsumerState<IngredientDetailPage> {
  // Map to store working copies of ingredient terms
  final Map<String, List<IngredientTerm>> _ingredientTermsMap = {};

  // Track terms being deleted for fade-out animation
  final Set<String> _deletingTermKeys = {};

  // Parser for ingredient text formatting
  final _parser = IngredientParserService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = IngredientDetailPage.selectedIngredientId;

    if (selectedId == null) {
      return const Center(child: Text('No ingredient selected'));
    }

    // Watch the live matches to get fresh data
    final matchesAsync = ref.watch(recipeIngredientMatchesProvider(widget.matches.recipeId));

    return matchesAsync.when(
      loading: () {
        // On initial load, show spinner
        // On refresh (after adding term), show previous data to prevent flash
        return matchesAsync.hasValue
            ? matchesAsync.requireValue.matches.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(context, matchesAsync.requireValue, selectedId)
            : const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (currentMatches) => _buildContent(context, currentMatches, selectedId),
    );
  }

  Widget _buildContent(BuildContext context, RecipeIngredientMatches currentMatches, String selectedId) {
    final colors = AppColors.of(context);

    // Find the current match for the selected ingredient
    final match = currentMatches.matches.firstWhere(
      (m) => m.ingredient.id == selectedId,
      orElse: () => widget.matches.matches.first,
    );

    final ingredient = match.ingredient;

    // Update working copy of terms if needed
    if (!_ingredientTermsMap.containsKey(ingredient.id) ||
        _ingredientTermsMap[ingredient.id]!.length != (ingredient.terms?.length ?? 0)) {
      _ingredientTermsMap[ingredient.id] = List<IngredientTerm>.from(ingredient.terms ?? []);
    }

    final terms = _ingredientTermsMap[ingredient.id] ?? [];
    final hasLinkedRecipe = ingredient.recipeId != null;

    // Parse ingredient name to get clean name without quantities/units
    final parseResult = _parser.parse(ingredient.name);
    final displayName = parseResult.cleanName.isNotEmpty
        ? parseResult.cleanName
        : ingredient.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ingredient name heading (parsed to remove quantities/units)
        Text(
          displayName,
          style: AppTypography.h4.copyWith(
            color: colors.textPrimary,
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        // Match status text - only show if has direct pantry match
        if (match.hasPantryMatch) _buildMatchedText(context, match),

        // Linked recipe section - only show if ingredient has linked recipe AND no direct pantry match
        // (direct pantry match takes precedence, so linked recipe info becomes irrelevant)
        if (hasLinkedRecipe && !match.hasPantryMatch) ...[
          SizedBox(height: AppSpacing.lg),
          _buildLinkedRecipeSection(context, ingredient, match),
        ],

        SizedBox(height: AppSpacing.xl),

        // Terms editor section
        _buildTermsEditor(context, ingredient, terms, hasLinkedRecipe: hasLinkedRecipe),
      ],
    );
  }

  Widget _buildMatchedText(BuildContext context, IngredientPantryMatch match) {
    final colors = AppColors.of(context);

    // "Matches with pantry item {name}"
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: colors.textTertiary,
        ),
        children: [
          const TextSpan(text: 'Matches with pantry item '),
          TextSpan(
            text: match.pantryItem!.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedRecipeSection(BuildContext context, Ingredient ingredient, IngredientPantryMatch match) {
    final colors = AppColors.of(context);
    final linkedRecipeId = ingredient.recipeId!;

    // Watch the linked recipe to get its name
    final linkedRecipeAsync = ref.watch(recipeByIdStreamProvider(linkedRecipeId));

    return linkedRecipeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (linkedRecipe) {
        if (linkedRecipe == null) {
          return const SizedBox.shrink();
        }

        // Parse the linked recipe title
        final parseResult = _parser.parse(linkedRecipe.title);
        final recipeName = parseResult.cleanName.isNotEmpty
            ? parseResult.cleanName
            : linkedRecipe.title;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: match.hasRecipeMatch
                ? colors.successBackground
                : colors.warningBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                match.hasRecipeMatch ? Icons.check_circle : Icons.info,
                size: 32,
                color: match.hasRecipeMatch ? colors.success : colors.warning,
              ),
              SizedBox(height: AppSpacing.sm),
              // Combined message with recipe name
              GestureDetector(
                onTap: () => _navigateToLinkedRecipe(context, linkedRecipeId),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: match.hasRecipeMatch ? colors.success : colors.warning,
                    ),
                    children: [
                      TextSpan(
                        text: match.hasRecipeMatch
                            ? 'You have everything to make '
                            : 'Missing ingredients for ',
                      ),
                      TextSpan(
                        text: recipeName,
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                          decorationColor: match.hasRecipeMatch ? colors.success : colors.warning,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      WidgetSpan(
                        child: Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: match.hasRecipeMatch ? colors.success : colors.warning,
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToLinkedRecipe(BuildContext context, String recipeId) {
    // Use go_router to navigate
    context.push('/recipe/$recipeId', extra: {
      'previousPageTitle': 'Recipe'
    });
  }

  Widget _buildTermsEditor(BuildContext context, Ingredient ingredient, List<IngredientTerm> terms, {bool hasLinkedRecipe = false}) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Terms heading with add button
        Row(
          children: [
            Text(
              'Matching Terms',
              style: AppTypography.h5.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),

            // Add term button
            AppButton(
              text: 'Add Term',
              onPressed: () => _addNewTerm(ingredient.id),
              theme: AppButtonTheme.secondary,
              style: AppButtonStyle.outline,
              shape: AppButtonShape.square,
              size: AppButtonSize.small,
              leadingIcon: const Icon(Icons.add),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.md),

        // Explainer text for linked recipe ingredients
        if (hasLinkedRecipe) ...[
          Text(
            'This ingredient is linked to a recipe. However, if any of the terms below match items in your pantry, those will be used instead of making the recipe.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: AppSpacing.md),
        ],

        // No terms placeholder
        if (terms.isEmpty)
          Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'No additional terms for this ingredient. Add terms to improve pantry matching.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: colors.textTertiary,
              ),
            ),
          ),

        // Terms list with reordering
        if (terms.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              final List<IngredientTerm> updatedTerms = List.from(terms);
              final item = updatedTerms.removeAt(oldIndex);
              updatedTerms.insert(newIndex, item);

              // Update sort values
              for (int i = 0; i < updatedTerms.length; i++) {
                updatedTerms[i] = IngredientTerm(
                  value: updatedTerms[i].value,
                  source: updatedTerms[i].source,
                  sort: i,
                );
              }

              // Update terms list in our map
              setState(() {
                _ingredientTermsMap[ingredient.id] = updatedTerms;
              });

              // Save changes immediately
              await _saveIngredientChanges(ingredient.id);
            },
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              final isFirst = index == 0;
              final isLast = index == terms.length - 1;

              return _buildTermItem(
                key: ValueKey('${ingredient.id}_term_${term.value}_$index'),
                ingredientId: ingredient.id,
                term: term,
                isFirst: isFirst,
                isLast: isLast,
              );
            },
          ),

        SizedBox(height: AppSpacing.md),

        // Help text
        Text(
          'Tip: Add terms that match pantry item names to improve matching.',
          style: TextStyle(
            fontSize: 12,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildTermItem({
    required Key key,
    required String ingredientId,
    required IngredientTerm term,
    required bool isFirst,
    required bool isLast,
  }) {
    final colors = AppColors.of(context);
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

    // Create unique key for tracking deletion
    final termKey = '${ingredientId}_${term.value}_${term.source}';
    final isDeleting = _deletingTermKeys.contains(termKey);

    return AnimatedOpacity(
      key: key,
      opacity: isDeleting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: EdgeInsets.zero,
        child: ContextMenuWidget(
        menuProvider: (_) {
          return Menu(
            children: [
              MenuAction(
                title: 'Delete',
                image: MenuImage.icon(Icons.delete),
                callback: () => _handleTermDeletion(ingredientId, term),
              ),
            ],
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.groupedListBackground,
            border: border,
            borderRadius: borderRadius,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.value,
                      style: AppTypography.fieldInput.copyWith(
                        color: colors.contentPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Source: ${term.source}',
                      style: AppTypography.caption.copyWith(
                        color: colors.contentSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Drag handle
              ReorderableDragStartListener(
                index: _ingredientTermsMap[ingredientId]?.indexOf(term) ?? 0,
                child: Icon(
                  Icons.drag_handle,
                  color: colors.uiSecondary,
                  size: 24,
                ),
              ),

              SizedBox(width: AppSpacing.sm),

              // Menu button (horizontal 3-dot)
              // Use platform-appropriate menu system
              Platform.isIOS || Platform.isMacOS
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) => CupertinoActionSheet(
                            actions: [
                              CupertinoActionSheetAction(
                                isDestructiveAction: true,
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleTermDeletion(ingredientId, term);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.more_horiz,
                        color: colors.uiSecondary,
                        size: 24,
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: colors.uiSecondary,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                      onSelected: (value) {
                        if (value == 'delete') {
                          _handleTermDeletion(ingredientId, term);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // Handle term deletion with fade-out animation
  Future<void> _handleTermDeletion(String ingredientId, IngredientTerm term) async {
    // Create unique key for tracking deletion
    final termKey = '${ingredientId}_${term.value}_${term.source}';

    // Mark term as deleting (triggers fade out)
    setState(() {
      _deletingTermKeys.add(termKey);
    });

    // Wait for fade animation to complete
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Get the current terms and remove the deleted one
    final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);
    terms.removeWhere((t) => t.value == term.value && t.source == term.source);

    // Update working copy
    setState(() {
      _ingredientTermsMap[ingredientId] = terms;
    });

    // Save changes (this will invalidate provider and trigger rebuild)
    await _saveIngredientChanges(ingredientId);

    // Wait a bit for provider to refresh and rebuild to complete
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Now safe to remove from deletion tracking
    setState(() {
      _deletingTermKeys.remove(termKey);
    });
  }

  Future<void> _saveIngredientChanges(String ingredientId) async {
    final repository = ref.read(recipeRepositoryProvider);

    // Get the original recipe to modify
    final recipeId = widget.matches.recipeId;
    final recipeAsync = await repository.getRecipeById(recipeId);

    if (recipeAsync == null) {
      return;
    }

    // Get the updated terms for this ingredient from working copy
    final updatedTerms = _ingredientTermsMap[ingredientId] ?? [];

    // Find the original ingredient
    final originalIngredient = widget.matches.matches
        .firstWhere((match) => match.ingredient.id == ingredientId)
        .ingredient;

    // Create updated ingredient with new terms
    final updatedIngredient = originalIngredient.copyWith(terms: updatedTerms);

    // Important: Create a deep copy of the ingredients list to avoid modifying the original
    final ingredients = List<Ingredient>.from(recipeAsync.ingredients ?? []);

    // Find the matching ingredient by ID and replace it
    final index = ingredients.indexWhere((ing) => ing.id == ingredientId);
    if (index >= 0) {
      ingredients[index] = updatedIngredient;

      // Save the updated recipe ingredients
      await repository.updateIngredients(recipeId, ingredients);

      // Invalidate the matches provider to refresh the UI with new match data
      ref.invalidate(recipeIngredientMatchesProvider(recipeId));
    }
  }

  void _addNewTerm(String ingredientId) {
    // Store the selected ingredient ID for the next pages
    IngredientDetailPage.selectedIngredientId = ingredientId;

    // Show platform-specific menu with options
    if (Platform.isIOS || Platform.isMacOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Add Matching Term'),
          message: const Text('Choose an option to add a matching term'),
          actions: [
            CupertinoActionSheetAction(
              child: const Text('Enter Custom Term'),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to page 5 (Add Custom Term)
                widget.pageIndexNotifier.value = 5;
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Select from Pantry'),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to page 6 (Select from Pantry)
                widget.pageIndexNotifier.value = 6;
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      // Material Design popup menu
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);

      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy + 50, // Offset to appear below the + button
          position.dx + 1,
          position.dy + 1,
        ),
        items: [
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.edit),
              title: Text('Enter Custom Term'),
              subtitle: Text('Enter a new term for matching'),
            ),
            onTap: () {
              // Navigate to page 5 (Add Custom Term)
              widget.pageIndexNotifier.value = 5;
            },
          ),
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.kitchen),
              title: Text('Select from Pantry'),
              subtitle: Text('Use an existing pantry item name'),
            ),
            onTap: () {
              // Navigate to page 6 (Select from Pantry)
              widget.pageIndexNotifier.value = 6;
            },
          ),
        ],
      );
    }
  }
}

// ============================================================================
// Page 5: Add Custom Term
// ============================================================================

class AddCustomTermPage extends ConsumerStatefulWidget {
  final RecipeIngredientMatches matches;
  final ValueNotifier<int> pageIndexNotifier;

  const AddCustomTermPage({
    super.key,
    required this.matches,
    required this.pageIndexNotifier,
  });

  @override
  ConsumerState<AddCustomTermPage> createState() => _AddCustomTermPageState();
}

class _AddCustomTermPageState extends ConsumerState<AddCustomTermPage> {
  late final TextEditingController _termController;
  late final FocusNode _focusNode;
  bool _hasInput = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _termController = TextEditingController();
    _focusNode = FocusNode();
    _termController.addListener(_updateHasInput);

    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _termController.removeListener(_updateHasInput);
    _termController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateHasInput() {
    final hasInput = _termController.text.trim().isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() {
        _hasInput = hasInput;
      });
    }
  }

  Future<void> _addTerm() async {
    final value = _termController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ingredientId = IngredientDetailPage.selectedIngredientId;
      if (ingredientId == null) return;
      final repository = ref.read(recipeRepositoryProvider);
      final recipeId = widget.matches.recipeId;
      final recipeAsync = await repository.getRecipeById(recipeId);

      if (recipeAsync == null) return;

      // Find the current ingredient
      final currentIngredient = recipeAsync.ingredients?.firstWhere(
        (ing) => ing.id == ingredientId,
        orElse: () => recipeAsync.ingredients!.first,
      );
      if (currentIngredient == null) return;

      // Get existing terms
      final currentTerms = List<IngredientTerm>.from(currentIngredient.terms ?? []);

      // Add new term
      currentTerms.add(IngredientTerm(
        value: value,
        source: 'user',
        sort: currentTerms.length,
      ));

      // Update ingredient with new terms
      final updatedIngredient = currentIngredient.copyWith(terms: currentTerms);
      final ingredients = List<Ingredient>.from(recipeAsync.ingredients ?? []);
      final index = ingredients.indexWhere((ing) => ing.id == ingredientId);

      if (index >= 0) {
        ingredients[index] = updatedIngredient;
        await repository.updateIngredients(recipeId, ingredients);
        ref.invalidate(recipeIngredientMatchesProvider(recipeId));
      }

      // Navigate back to ingredient detail page
      widget.pageIndexNotifier.value = 4;
    } catch (e) {
      AppLogger.error('Error adding term', e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ingredientId = IngredientDetailPage.selectedIngredientId;

    // Find the ingredient from matches
    final match = widget.matches.matches.firstWhere(
      (m) => m.ingredient.id == ingredientId,
      orElse: () => widget.matches.matches.first,
    );

    // Parse ingredient name to get clean name without quantities/units
    final parser = IngredientParserService();
    final parseResult = parser.parse(match.ingredient.name);
    final displayName = parseResult.cleanName.isNotEmpty
        ? parseResult.cleanName
        : match.ingredient.name;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Term for "$displayName"',
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppTextFieldSimple(
                  controller: _termController,
                  focusNode: _focusNode,
                  placeholder: 'Enter matching term',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTerm(),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              AppButtonVariants.primaryFilled(
                text: 'Add',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                onPressed: (_isLoading || !_hasInput) ? null : _addTerm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Page 6: Select from Pantry
// ============================================================================

class SelectFromPantryPage extends ConsumerStatefulWidget {
  final RecipeIngredientMatches matches;
  final ValueNotifier<int> pageIndexNotifier;

  const SelectFromPantryPage({
    super.key,
    required this.matches,
    required this.pageIndexNotifier,
  });

  @override
  ConsumerState<SelectFromPantryPage> createState() => _SelectFromPantryPageState();
}

class _SelectFromPantryPageState extends ConsumerState<SelectFromPantryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onItemSelected(String itemName) async {
    final ingredientId = IngredientDetailPage.selectedIngredientId;
    if (ingredientId == null) return;

    try {
      final repository = ref.read(recipeRepositoryProvider);
      final recipeId = widget.matches.recipeId;
      final recipeAsync = await repository.getRecipeById(recipeId);

      if (recipeAsync == null) return;

      // Find the current ingredient
      final currentIngredient = recipeAsync.ingredients?.firstWhere(
        (ing) => ing.id == ingredientId,
        orElse: () => recipeAsync.ingredients!.first,
      );
      if (currentIngredient == null) return;

      // Get existing terms
      final currentTerms = List<IngredientTerm>.from(currentIngredient.terms ?? []);

      // Add new term from pantry item
      currentTerms.add(IngredientTerm(
        value: itemName,
        source: 'pantry',
        sort: currentTerms.length,
      ));

      // Update ingredient with new terms
      final updatedIngredient = currentIngredient.copyWith(terms: currentTerms);
      final ingredients = List<Ingredient>.from(recipeAsync.ingredients ?? []);
      final index = ingredients.indexWhere((ing) => ing.id == ingredientId);

      if (index >= 0) {
        ingredients[index] = updatedIngredient;
        await repository.updateIngredients(recipeId, ingredients);
        ref.invalidate(recipeIngredientMatchesProvider(recipeId));
      }

      // Navigate back to ingredient detail page
      widget.pageIndexNotifier.value = 4;
    } catch (e) {
      AppLogger.error('Error adding pantry item term', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantryItemsAsync = ref.watch(pantryItemsProvider);
    final colors = AppColors.of(context);
    final ingredientId = IngredientDetailPage.selectedIngredientId;

    // Find the ingredient from matches
    final match = widget.matches.matches.firstWhere(
      (m) => m.ingredient.id == ingredientId,
      orElse: () => widget.matches.matches.first,
    );

    // Parse ingredient name to get clean name without quantities/units
    final parser = IngredientParserService();
    final parseResult = parser.parse(match.ingredient.name);
    final displayName = parseResult.cleanName.isNotEmpty
        ? parseResult.cleanName
        : match.ingredient.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select Item for "$displayName"',
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),

        // Search box
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: CupertinoSearchTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            placeholder: 'Search pantry items...',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
        ),

        SizedBox(height: AppSpacing.md),

        // Scrollable content area with fixed height
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: pantryItemsAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading pantry items: $error'),
            ),
            data: (pantryItems) {
              if (pantryItems.isEmpty) {
                return _buildEmptyState(context);
              }

              // Filter items based on search
              final filteredItems = _searchQuery.isEmpty
                  ? pantryItems
                  : pantryItems.where((item) =>
                      item.name.toLowerCase().contains(_searchQuery)).toList();

              if (filteredItems.isEmpty) {
                return _buildNoResultsState(context);
              }

              // Group items by category
              final groupedItems = <String, List<PantryItemEntry>>{};
              for (final item in filteredItems) {
                final category = item.category ?? 'Uncategorized';
                groupedItems.putIfAbsent(category, () => []).add(item);
              }

              // Sort categories alphabetically
              final sortedCategories = groupedItems.keys.toList()..sort();

              return CustomScrollView(
                slivers: sortedCategories.map((category) {
                  final items = groupedItems[category]!;

                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header
                        Padding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                          child: Text(
                            category,
                            style: AppTypography.h5.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        // Items in this category
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: _buildGroupedItemsList(context, items),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedItemsList(BuildContext context, List<PantryItemEntry> items) {
    final colors = AppColors.of(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;

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
          child: InkWell(
            onTap: () => _onItemSelected(item.name),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.contentSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.cube_box,
              size: 48,
              color: colors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No pantry items found',
              style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Add items in the Pantry tab',
              style: AppTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 48,
              color: colors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No items found',
              style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different search term',
              style: AppTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
