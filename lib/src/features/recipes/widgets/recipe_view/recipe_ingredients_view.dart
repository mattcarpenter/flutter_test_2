import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../database/models/ingredients.dart';
import '../../../../../database/models/pantry_items.dart';
import '../../../../models/ingredient_pantry_match.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../services/ingredient_parser_service.dart';
import 'ingredient_match_circle.dart';
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

class _RecipeIngredientsViewState extends ConsumerState<RecipeIngredientsView> {
  // Keep previous match data to prevent flashing
  RecipeIngredientMatches? _previousMatches;

  // Parser for ingredient text formatting
  final _parser = IngredientParserService();

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: AppTypography.h2Serif.copyWith(
            color: AppColors.of(context).headingSecondary,
          ),
        ),

        SizedBox(height: AppSpacing.md),

        if (widget.ingredients.isEmpty)
          const Text('No ingredients listed.'),

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
                  ingredient.name,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
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
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.0,
                        color: AppColors.of(context).contentSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ingredient name
                    Expanded(
                      child: _buildParsedIngredientText(
                        ingredient.name,
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

                        final chip = _buildStockChip(match);
                        if (chip != null) {
                          return GestureDetector(
                            onTap: () => _showMatchesBottomSheet(context, ref, currentMatches!),
                            child: chip,
                          );
                        }
                        return const SizedBox.shrink();
                      }(),
                    ],

                  // Note (if available)
                  if (ingredient.note != null && ingredient.note!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '(${ingredient.note})',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                          fontSize: 14,
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

  /// Builds a stock status chip based on ingredient match
  Widget? _buildStockChip(IngredientPantryMatch match) {
    if (!match.hasMatch) {
      return null; // No chip for no match
    }

    Color backgroundColor;
    String label;

    if (match.hasPantryMatch) {
      // Direct pantry match - use stock status colors
      switch (match.pantryItem!.stockStatus) {
        case StockStatus.outOfStock:
          backgroundColor = AppColorSwatches.error[100]!; // Light red
          label = 'Out';
          break;
        case StockStatus.lowStock:
          backgroundColor = AppColorSwatches.warning[100]!; // Light yellow
          label = 'Low';
          break;
        case StockStatus.inStock:
          backgroundColor = AppColorSwatches.success[100]!; // Light green
          label = 'In Stock';
          break;
        default:
          return null;
      }
    } else if (match.hasRecipeMatch) {
      // Recipe-based match
      backgroundColor = AppColorSwatches.success[100]!; // Light green
      label = 'Recipe';
    } else {
      return null;
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
          color: AppColors.of(context).textPrimary,
        ),
      ),
    );
  }

  /// Builds a RichText widget with bold quantities parsed from ingredient text
  Widget _buildParsedIngredientText(String text, {bool isLinkedRecipe = false}) {
    final colors = AppColors.of(context);

    try {
      final parseResult = _parser.parse(text);

      if (parseResult.quantities.isEmpty) {
        // No quantities found, return plain text
        return Text(
          text,
          style: TextStyle(fontSize: 16, color: colors.contentPrimary),
        );
      }

      final children = <TextSpan>[];
      int currentIndex = 0;

      // Build TextSpan with bold quantities, normal ingredient names
      for (final quantity in parseResult.quantities) {
        // Text before quantity (ingredient name)
        if (quantity.start > currentIndex) {
          children.add(TextSpan(
            text: text.substring(currentIndex, quantity.start),
            style: TextStyle(fontSize: 16, color: colors.contentPrimary),
          ));
        }

        // Quantity with bold formatting
        children.add(TextSpan(
          text: text.substring(quantity.start, quantity.end),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.contentPrimary),
        ));

        currentIndex = quantity.end;
      }

      // Remaining text after last quantity
      if (currentIndex < text.length) {
        children.add(TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(fontSize: 16, color: colors.contentPrimary),
        ));
      }

      // Wrap in GestureDetector if it's a linked recipe
      Widget richText = RichText(
        text: TextSpan(children: children),
      );

      if (isLinkedRecipe) {
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.contentPrimary,
                      width: 1.0,
                      style: BorderStyle.none, // This creates a dotted effect in some contexts
                    ),
                  ),
                ),
                child: richText,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: colors.contentSecondary,
            ),
          ],
        );
      }

      return richText;
    } catch (e) {
      // Fallback to plain text if parsing fails
      Widget plainText = Text(
        text,
        style: TextStyle(fontSize: 16, color: colors.contentPrimary),
      );

      if (isLinkedRecipe) {
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.contentPrimary,
                      width: 1.0,
                    ),
                  ),
                ),
                child: plainText,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: colors.contentSecondary,
            ),
          ],
        );
      }

      return plainText;
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
    print("Opening ingredient matches bottom sheet for recipe ${matches.recipeId}");
    print("Current matches: ${matches.matches.length}");
    print("Matched ingredients: ${matches.matches.where((m) => m.hasMatch).length}");
    
    // Refresh the recipe ingredient match data before showing the sheet
    // This ensures we have the latest data including newly added ingredients
    ref.invalidate(recipeIngredientMatchesProvider(matches.recipeId));
    
    // Show the bottom sheet after refreshing the data
    Future.microtask(() {
      // Wait for the provider to refresh its data before showing the sheet
      ref.read(recipeIngredientMatchesProvider(matches.recipeId).future).then((refreshedMatches) {
        print("Refreshed matches: ${refreshedMatches.matches.length}");
        print("Refreshed matched ingredients: ${refreshedMatches.matches.where((m) => m.hasMatch).length}");
        
        showIngredientMatchesBottomSheet(
          context,
          matches: refreshedMatches,
        );
      }).catchError((error) {
        print("Error refreshing matches: $error");
        // If there's an error refreshing, still show the sheet with the original data
        showIngredientMatchesBottomSheet(
          context,
          matches: matches,
        );
      });
    });
  }
}
