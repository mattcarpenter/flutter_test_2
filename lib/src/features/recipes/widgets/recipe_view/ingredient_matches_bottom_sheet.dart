import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' show recipeIngredientMatchesProvider, recipeByIdStreamProvider;
import 'package:recipe_app/src/repositories/recipe_repository.dart' show recipeRepositoryProvider;
import 'package:recipe_app/src/theme/colors.dart';
import 'package:recipe_app/src/theme/spacing.dart';
import 'package:recipe_app/src/theme/typography.dart';
import 'package:recipe_app/src/widgets/app_button.dart';
import 'package:recipe_app/src/widgets/app_circle_button.dart';
import 'package:recipe_app/src/widgets/ingredient_stock_chip.dart';
import 'package:recipe_app/src/widgets/utils/grouped_list_styling.dart';
import 'package:recipe_app/src/widgets/wolt/button/wolt_modal_sheet_back_button.dart';
import 'package:recipe_app/src/services/ingredient_parser_service.dart';
import 'pantry_item_selector_bottom_sheet.dart';

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

  // Page navigation state
  final pageIndexNotifier = ValueNotifier<int>(0);

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageIndexNotifier: pageIndexNotifier,
    pageListBuilder: (modalContext) {
      return [
        // Page 1: Ingredient list
        WoltModalSheetPage(
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: Text('Pantry Matches (${matches.matches.where((m) => m.hasMatch).length}/${matches.matches.length})'),
          trailingNavBarWidget: Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              onPressed: () {
                Navigator.of(modalContext).pop();
              },
            ),
          ),
          child: IngredientMatchesListPage(
            matches: matches,
            pageIndexNotifier: pageIndexNotifier,
          ),
        ),
        // Page 2: Individual ingredient detail
        WoltModalSheetPage(
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: WoltModalSheetBackButton(
            onBackPressed: () {
              pageIndexNotifier.value = 0;
            },
          ),
          child: IngredientDetailPage(
            matches: matches,
          ),
        ),
      ];
    },
    onModalDismissedWithBarrierTap: () {
      Navigator.of(context).pop();
    },
  );
}

// ============================================================================
// Page 1: Ingredient List
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
      loading: () => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(child: Text('Error: $error')),
      ),
      data: (currentMatches) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary text
              Text(
                'Pantry matches: ${currentMatches.matches.where((m) => m.hasMatch).length} of ${currentMatches.matches.length} ingredients',
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Ingredient list
              Expanded(
                child: ListView.separated(
                  itemCount: currentMatches.matches.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColorSwatches.neutral[350]!,
                  ),
                  itemBuilder: (context, index) {
                    final match = currentMatches.matches[index];
                    return _buildIngredientRow(context, match);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientRow(BuildContext context, IngredientPantryMatch match) {
    final colors = AppColors.of(context);
    final ingredient = match.ingredient;

    // Parse ingredient name to get clean name without quantities/units
    final parseResult = _parser.parse(ingredient.name);
    final displayName = parseResult.cleanName.isNotEmpty
        ? parseResult.cleanName
        : ingredient.name;

    return InkWell(
      onTap: () {
        // Store selected ingredient in a global accessible way
        IngredientDetailPage.selectedMatch = match;
        pageIndexNotifier.value = 1;
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
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
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: IngredientStockChip(match: match),
              ),
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
    );
  }
}

// ============================================================================
// Page 2: Ingredient Detail
// ============================================================================

class IngredientDetailPage extends ConsumerStatefulWidget {
  final RecipeIngredientMatches matches;

  // Static variable to share selected match between pages
  static IngredientPantryMatch? selectedMatch;

  const IngredientDetailPage({
    super.key,
    required this.matches,
  });

  @override
  ConsumerState<IngredientDetailPage> createState() => _IngredientDetailPageState();
}

class _IngredientDetailPageState extends ConsumerState<IngredientDetailPage> {
  // Map to store working copies of ingredient terms
  final Map<String, List<IngredientTerm>> _ingredientTermsMap = {};

  // Parser for ingredient text formatting
  final _parser = IngredientParserService();

  @override
  void initState() {
    super.initState();
    // Initialize working copy of terms for the selected ingredient
    if (IngredientDetailPage.selectedMatch != null) {
      final ingredient = IngredientDetailPage.selectedMatch!.ingredient;
      _ingredientTermsMap[ingredient.id] = List<IngredientTerm>.from(ingredient.terms ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final match = IngredientDetailPage.selectedMatch;

    if (match == null) {
      return const Center(child: Text('No ingredient selected'));
    }

    final ingredient = match.ingredient;
    final terms = _ingredientTermsMap[ingredient.id] ?? [];
    final hasLinkedRecipe = ingredient.recipeId != null;

    // Parse ingredient name to get clean name without quantities/units
    final parseResult = _parser.parse(ingredient.name);
    final displayName = parseResult.cleanName.isNotEmpty
        ? parseResult.cleanName
        : ingredient.name;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
      ),
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

        SizedBox(height: AppSpacing.sm),

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

    return Padding(
      key: key,
      padding: EdgeInsets.zero,
      child: ContextMenuWidget(
        menuProvider: (_) {
          return Menu(
            children: [
              MenuAction(
                title: 'Delete',
                image: MenuImage.icon(Icons.delete),
                callback: () async {
                  // Get the current terms
                  final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

                  // Remove the term
                  terms.removeWhere((t) => t.value == term.value && t.source == term.source);

                  // Update the maps
                  setState(() {
                    _ingredientTermsMap[ingredientId] = terms;
                  });

                  // Save changes immediately
                  await _saveIngredientChanges(ingredientId);
                },
              ),
            ],
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: colors.input,
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
                                onPressed: () async {
                                  Navigator.pop(context);
                                  // Get the current terms
                                  final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

                                  // Remove the term
                                  terms.removeWhere((t) => t.value == term.value && t.source == term.source);

                                  // Update the maps
                                  setState(() {
                                    _ingredientTermsMap[ingredientId] = terms;
                                  });

                                  // Save changes immediately
                                  await _saveIngredientChanges(ingredientId);
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
                      onSelected: (value) async {
                        if (value == 'delete') {
                          // Get the current terms
                          final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

                          // Remove the term
                          terms.removeWhere((t) => t.value == term.value && t.source == term.source);

                          // Update the maps
                          setState(() {
                            _ingredientTermsMap[ingredientId] = terms;
                          });

                          // Save changes immediately
                          await _saveIngredientChanges(ingredientId);
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
    );
  }

  void _addNewTerm(String ingredientId) {
    // Find the original ingredient
    final ingredient = widget.matches.matches
        .firstWhere((match) => match.ingredient.id == ingredientId)
        .ingredient;

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
                _showAddTermDialog(ingredientId, ingredient);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Select from Pantry'),
              onPressed: () {
                Navigator.pop(context);
                showPantryItemSelectorBottomSheet(
                  context: context,
                  recipeId: widget.matches.recipeId,
                  onItemSelected: (itemName) async {
                    await _addTermFromPantryItem(ingredientId, ingredient, itemName);
                  },
                );
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
            onTap: () => _showAddTermDialog(ingredientId, ingredient),
          ),
          PopupMenuItem(
            child: const ListTile(
              leading: Icon(Icons.kitchen),
              title: Text('Select from Pantry'),
              subtitle: Text('Use an existing pantry item name'),
            ),
            onTap: () => showPantryItemSelectorBottomSheet(
              context: context,
              recipeId: widget.matches.recipeId,
              onItemSelected: (itemName) async {
                await _addTermFromPantryItem(ingredientId, ingredient, itemName);
              },
            ),
          ),
        ],
      );
    }
  }

  // Show the platform-specific dialog
  void _showAddTermDialog(String ingredientId, Ingredient ingredient) {
    final controller = TextEditingController();

    // Handle saving the term
    Future<void> saveTerm() async {
      final value = controller.text.trim();
      final navigator = Navigator.of(context);

      if (value.isNotEmpty) {
        // Get existing terms from our working copy
        final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

        // Add new term with the next sort value
        terms.add(IngredientTerm(
          value: value,
          source: 'user', // Marked as user-added
          sort: terms.length, // Next position
        ));

        // Update the maps
        setState(() {
          _ingredientTermsMap[ingredientId] = terms;
        });

        // Save changes immediately
        await _saveIngredientChanges(ingredientId);
      }
      navigator.pop();
    }

    if (Platform.isIOS) {
      // Show Cupertino dialog on iOS
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Add Matching Term'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Enter a matching term',
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => saveTerm(),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async => await saveTerm(),
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } else {
      // Show Material dialog on Android and other platforms
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Matching Term'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Term',
              hintText: 'Enter a matching term (e.g., pantry item name)',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => saveTerm(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async => await saveTerm(),
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }
  }

  // Add a term from a selected pantry item
  Future<void> _addTermFromPantryItem(String ingredientId, Ingredient ingredient, String itemName) async {
    // Get existing terms from our working copy
    final terms = List<IngredientTerm>.from(_ingredientTermsMap[ingredientId] ?? []);

    // Add new term with the next sort value
    terms.add(IngredientTerm(
      value: itemName,
      source: 'pantry', // Marked as coming from pantry item
      sort: terms.length, // Next position
    ));

    // Update the maps
    setState(() {
      _ingredientTermsMap[ingredientId] = terms;
    });

    // Save changes immediately
    await _saveIngredientChanges(ingredientId);
  }

  // Save changes for a specific ingredient immediately
  Future<void> _saveIngredientChanges(String ingredientId) async {
    final repository = ref.read(recipeRepositoryProvider);

    // Get the original recipe to modify
    final recipeId = widget.matches.recipeId;
    final recipeAsync = await repository.getRecipeById(recipeId);

    if (recipeAsync == null) {
      return;
    }

    // Get the updated terms for this ingredient
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
}
