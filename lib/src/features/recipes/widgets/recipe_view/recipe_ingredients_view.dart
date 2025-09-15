import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../database/models/ingredients.dart';
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
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8.0, bottom: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ingredient.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            // Regular ingredient with match indicator (if available)
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 0 : 4.0,
                bottom: 4.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Match indicator or bullet point - use cached data to prevent flashing
                  if (currentMatches != null) ...[
                    () {
                      // Find the matching IngredientPantryMatch for this ingredient
                      final match = currentMatches!.matches.firstWhere(
                        (m) => m.ingredient.id == ingredient.id,
                        // If no match found, create a default one with no pantry match
                        orElse: () => IngredientPantryMatch(ingredient: ingredient),
                      );
                      
                      return IngredientMatchCircle(
                        match: match, 
                        onTap: () => _showMatchesBottomSheet(context, ref, currentMatches!),
                        size: 10.0,
                      );
                    }(),
                  ] else if (matchesAsync != null && matchesAsync.isLoading) ...[
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.0,
                      ),
                    ),
                  ] else if (matchesAsync != null && matchesAsync.hasError) ...[
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.0,
                      ),
                    ),
                  ] else ...[
                    // Default bullet point when no matches
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.0,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),

                  // Ingredient name
                  Expanded(
                    child: _buildParsedIngredientText(ingredient.name),
                  ),

                  // "See Recipe" chip for linked ingredients
                  if (ingredient.recipeId != null) ...[
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('See Recipe'),
                      avatar: const Icon(Icons.launch, size: 16),
                      onPressed: () => _navigateToLinkedRecipe(context, ingredient.recipeId!),
                      visualDensity: VisualDensity.compact,
                    ),
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
            );
          },
        ),
      ],
    );
  }

  /// Builds a RichText widget with bold quantities parsed from ingredient text
  Widget _buildParsedIngredientText(String text) {
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

      return RichText(
        text: TextSpan(children: children),
      );
    } catch (e) {
      // Fallback to plain text if parsing fails
      return Text(
        text,
        style: TextStyle(fontSize: 16, color: colors.contentPrimary),
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
