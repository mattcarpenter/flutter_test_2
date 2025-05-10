import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/models/ingredients.dart';
import '../../../../models/ingredient_pantry_match.dart';
import '../../../../providers/recipe_provider.dart';
import 'ingredient_match_circle.dart';
import 'ingredient_matches_bottom_sheet.dart';

class RecipeIngredientsView extends ConsumerWidget {
  final List<Ingredient> ingredients;
  final String? recipeId;

  const RecipeIngredientsView({
    Key? key, 
    required this.ingredients, 
    this.recipeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only fetch matches if recipeId is provided
    final matchesAsync = recipeId != null 
      ? ref.watch(recipeIngredientMatchesProvider(recipeId!))
      : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_basket, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            // Display match ratio if available
            if (matchesAsync != null) ...[
              const SizedBox(width: 8),
              matchesAsync.when(
                data: (matches) => Text(
                  '(${matches.matches.where((m) => m.hasMatch).length}/${matches.matches.length})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),

        if (ingredients.isEmpty)
          const Text('No ingredients listed.'),

        // Ingredients list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = ingredients[index];

            // Section header
            if (ingredient.type == 'section') {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match indicator or bullet point
                  if (matchesAsync != null) ...[
                    matchesAsync.when(
                      data: (matches) {
                        // Find the matching IngredientPantryMatch for this ingredient
                        final match = matches.matches.firstWhere(
                          (m) => m.ingredient.id == ingredient.id,
                          // If no match found, create a default one with no pantry match
                          orElse: () => IngredientPantryMatch(ingredient: ingredient),
                        );
                        
                        return IngredientMatchCircle(
                          match: match, 
                          onTap: () => _showMatchesBottomSheet(context, ref, matches),
                          size: 10.0,
                        );
                      },
                      loading: () => const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      error: (_, __) => const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.0,
                        ),
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

                  // Amount
                  if (ingredient.primaryAmount1Value != null &&
                      ingredient.primaryAmount1Value!.isNotEmpty) ...[
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${ingredient.primaryAmount1Value} ${ingredient.primaryAmount1Unit ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  // Ingredient name
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

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
  
  /// Shows the bottom sheet with ingredient match details
  void _showMatchesBottomSheet(BuildContext context, WidgetRef ref, RecipeIngredientMatches matches) {
    showIngredientMatchesBottomSheet(
      context,
      matches: matches,
    );
  }
}
