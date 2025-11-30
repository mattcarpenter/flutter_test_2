import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../database/models/ingredients.dart';
import '../../../../models/ingredient_pantry_match.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../settings/providers/app_settings_provider.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../services/ingredient_parser_service.dart';
import '../../../../widgets/ingredient_stock_chip.dart';
import 'ingredient_matches_bottom_sheet.dart';

class RecipeIngredientsView extends ConsumerStatefulWidget {
  final List<Ingredient> ingredients;
  final String? recipeId;

  const RecipeIngredientsView({
    Key? key,
    required this.ingredients,
    this.recipeId,
  }) : super(key: key);

  @override
  ConsumerState<RecipeIngredientsView> createState() => _RecipeIngredientsViewState();
}

class _RecipeIngredientsViewState extends ConsumerState<RecipeIngredientsView>
    with SingleTickerProviderStateMixin {
  // Keep previous match data to prevent flashing
  RecipeIngredientMatches? _previousMatches;

  // Parser for ingredient text formatting
  final _parser = IngredientParserService();

  // Accordion animation controller
  late AnimationController _accordionController;
  late Animation<double> _accordionAnimation;

  @override
  void initState() {
    super.initState();
    _accordionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _accordionAnimation = CurvedAnimation(
      parent: _accordionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _accordionController.dispose();
    super.dispose();
  }

  void _toggleAccordion() {
    if (_accordionController.isCompleted) {
      _accordionController.reverse();
    } else {
      _accordionController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only fetch matches if recipeId is provided
    final matchesAsync = widget.recipeId != null
      ? ref.watch(recipeIngredientMatchesProvider(widget.recipeId!))
      : null;

    // Get current matches, but keep previous data during loading to prevent flashing
    RecipeIngredientMatches? currentMatches;
    if (matchesAsync != null) {
      matchesAsync.whenData((matches) {
        _previousMatches = matches; // Store successful data
        currentMatches = matches;
      });

      // Use previous data if we're in loading state and have previous data
      if (matchesAsync.isLoading && _previousMatches != null) {
        currentMatches = _previousMatches;
      } else if (!matchesAsync.isLoading) {
        currentMatches = matchesAsync.valueOrNull;
      }
    }

    // Get font scale from settings - use AppTypography.body as the base for consistency
    final fontScale = ref.watch(recipeFontScaleProvider);
    final baseStyle = AppTypography.body;
    final scaledFontSize = (baseStyle.fontSize ?? 15.0) * fontScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with "Scale or Convert" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ingredients',
              style: AppTypography.h3Serif.copyWith(
                color: AppColors.of(context).headingSecondary,
              ),
            ),
            TextButton(
              onPressed: _toggleAccordion,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: AnimatedBuilder(
                animation: _accordionController,
                builder: (context, child) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Scale or Convert'),
                    const SizedBox(width: 4),
                    Icon(
                      _accordionController.value > 0.5
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Animated accordion panel - expands vertically and fades in/out
        SizeTransition(
          sizeFactor: _accordionAnimation,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: _accordionAnimation,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: AppSpacing.md),
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.of(context).surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                height: 100,
                child: Center(
                  child: Text('Scale or Convert options coming soon...'),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: AppSpacing.md),

        if (widget.ingredients.isEmpty)
          Text(
            'No ingredients listed.',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
            ),
          ),

        // Ingredients list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = widget.ingredients[index];

            // Section header
            if (ingredient.type == 'section') {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : AppSpacing.xl, // More spacing on top
                  bottom: AppSpacing.sm, // Less spacing on bottom
                ),
                child: Text(
                  ingredient.name.toUpperCase(),
                  style: AppTypography.sectionLabel,
                ),
              );
            }

            // Regular ingredient with match indicator (if available)
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 0 : 8.0,
                bottom: 8.0,
              ),
              child: GestureDetector(
                onTap: ingredient.recipeId != null
                    ? () => _navigateToLinkedRecipe(context, ingredient.recipeId!)
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Simple bullet point
                    Text(
                      '•',
                      style: AppTypography.body.copyWith(
                        fontSize: scaledFontSize,
                        color: AppColors.of(context).contentSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ingredient name
                    Expanded(
                      child: _buildParsedIngredientText(
                        ingredient.name,
                        fontSize: scaledFontSize,
                        isLinkedRecipe: ingredient.recipeId != null,
                      ),
                    ),

                    // Stock status chip (right-aligned)
                    if (currentMatches != null) ...[
                      () {
                        // Find the matching IngredientPantryMatch for this ingredient
                        final match = currentMatches!.matches.firstWhere(
                          (m) => m.ingredient.id == ingredient.id,
                          // If no match found, create a default one with no pantry match
                          orElse: () => IngredientPantryMatch(ingredient: ingredient),
                        );

                        return GestureDetector(
                          onTap: () => _showMatchesBottomSheet(context, ref, currentMatches!),
                          child: IngredientStockChip(match: match),
                        );
                      }(),
                    ],

                  // Note (if available)
                  if (ingredient.note != null && ingredient.note!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '(${ingredient.note})',
                        style: AppTypography.caption.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.of(context).textTertiary,
                        ),
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds a RichText widget with bold quantities parsed from ingredient text
  Widget _buildParsedIngredientText(String text, {required double fontSize, bool isLinkedRecipe = false}) {
    final colors = AppColors.of(context);
    // Use AppTypography.body as base style for consistency with notes/description
    final baseStyle = AppTypography.body.copyWith(
      fontSize: fontSize,
      color: colors.contentPrimary,
    );

    try {
      final parseResult = _parser.parse(text);

      if (parseResult.quantities.isEmpty) {
        // No quantities found, return plain text
        return Text(text, style: baseStyle);
      }

      final children = <InlineSpan>[];
      int currentIndex = 0;

      // Build TextSpan with bold quantities, normal ingredient names
      for (final quantity in parseResult.quantities) {
        // Text before quantity (ingredient name)
        if (quantity.start > currentIndex) {
          children.add(TextSpan(
            text: text.substring(currentIndex, quantity.start),
            style: baseStyle,
          ));
        }

        // Quantity with bold formatting
        children.add(TextSpan(
          text: text.substring(quantity.start, quantity.end),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));

        currentIndex = quantity.end;
      }

      // Remaining text after last quantity
      if (currentIndex < text.length) {
        children.add(TextSpan(
          text: text.substring(currentIndex),
          style: baseStyle,
        ));
      }

      // Add external link icon inline for linked recipes
      if (isLinkedRecipe) {
        children.add(const TextSpan(text: ' ')); // Small space
        children.add(WidgetSpan(
          child: Icon(
            Icons.open_in_new,
            size: 14,
            color: colors.contentSecondary,
          ),
          alignment: PlaceholderAlignment.middle,
        ));
      }

      // Create RichText with underline decoration for linked recipes
      Widget richText = RichText(
        text: TextSpan(
          children: children,
          style: isLinkedRecipe ? TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: colors.contentPrimary,
          ) : null,
        ),
      );

      return richText;
    } catch (e) {
      // Fallback to plain text if parsing fails - use RichText for consistency
      final fallbackChildren = <InlineSpan>[
        TextSpan(text: text, style: baseStyle),
      ];

      // Add external link icon inline for linked recipes
      if (isLinkedRecipe) {
        fallbackChildren.add(const TextSpan(text: ' ')); // Small space
        fallbackChildren.add(WidgetSpan(
          child: Icon(
            Icons.open_in_new,
            size: 14,
            color: colors.contentSecondary,
          ),
          alignment: PlaceholderAlignment.middle,
        ));
      }

      return RichText(
        text: TextSpan(
          children: fallbackChildren,
          style: isLinkedRecipe ? TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: colors.contentPrimary,
          ) : null,
        ),
      );
    }
  }

  /// Navigates to the linked recipe
  void _navigateToLinkedRecipe(BuildContext context, String recipeId) {
    context.push('/recipe/$recipeId', extra: {
      'previousPageTitle': 'Recipe'
    });
  }

  /// Shows the bottom sheet with ingredient match details
  void _showMatchesBottomSheet(BuildContext context, WidgetRef ref, RecipeIngredientMatches matches) {
    // Refresh the recipe ingredient match data before showing the sheet
    // This ensures we have the latest data including newly added ingredients
    ref.invalidate(recipeIngredientMatchesProvider(matches.recipeId));

    // Show the bottom sheet after refreshing the data
    Future.microtask(() {
      // Wait for the provider to refresh its data before showing the sheet
      ref.read(recipeIngredientMatchesProvider(matches.recipeId).future).then((refreshedMatches) {
        showIngredientMatchesBottomSheet(
          context,
          matches: refreshedMatches,
        );
      }).catchError((error) {
        // If there's an error refreshing, still show the sheet with the original data
        showIngredientMatchesBottomSheet(
          context,
          matches: matches,
        );
      });
    });
  }
}
