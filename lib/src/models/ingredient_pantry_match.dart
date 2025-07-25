import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/ingredients.dart';

/// Represents a match between a recipe ingredient and a pantry item
class IngredientPantryMatch {
  /// The ingredient from the recipe
  final Ingredient ingredient;
  
  /// The pantry item that matches the ingredient (null if no match)
  final PantryItemEntry? pantryItem;
  
  /// Whether the ingredient has a makeable recipe reference
  final bool hasRecipeMatch;
  
  /// Whether a matching pantry item was found OR the ingredient can be made via sub-recipe
  bool get hasMatch => pantryItem != null || hasRecipeMatch;
  
  /// Whether this match is specifically through a direct pantry item
  bool get hasPantryMatch => pantryItem != null;

  IngredientPantryMatch({
    required this.ingredient,
    this.pantryItem,
    this.hasRecipeMatch = false,
  });
}

/// Contains all ingredient matches for a recipe
class RecipeIngredientMatches {
  /// The recipe ID
  final String recipeId;
  
  /// List of ingredient to pantry matches
  final List<IngredientPantryMatch> matches;
  
  /// The percentage of ingredients that have a matching pantry item
  double get matchRatio => 
      matches.isEmpty ? 0.0 : matches.where((m) => m.hasMatch).length / matches.length;
  
  /// Whether all ingredients have a matching pantry item
  bool get hasAllIngredients => matches.every((m) => m.hasMatch);
  
  /// The ingredients that don't have matching pantry items
  List<Ingredient> get missingIngredients => 
      matches.where((m) => !m.hasMatch).map((m) => m.ingredient).toList();

  RecipeIngredientMatches({
    required this.recipeId,
    required this.matches,
  });
}