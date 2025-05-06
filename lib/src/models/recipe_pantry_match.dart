import 'package:recipe_app/database/database.dart';

/// Represents a recipe that matches pantry items with details about the match
class RecipePantryMatch {
  /// The recipe data
  final RecipeEntry recipe;
  
  /// Number of recipe terms that matched pantry items
  final int matchedTerms;
  
  /// Total number of terms in the recipe
  final int totalTerms;
  
  /// Ratio of matched terms to total terms (0.0 to 1.0)
  final double matchRatio;
  
  /// List of pantry item IDs that matched recipe terms
  final List<String>? matchedPantryItemIds;

  RecipePantryMatch({
    required this.recipe,
    required this.matchedTerms,
    required this.totalTerms,
    required this.matchRatio,
    this.matchedPantryItemIds,
  });

  /// Whether this recipe is a perfect match (all ingredients found in pantry)
  bool get isPerfectMatch => matchedTerms == totalTerms;
  
  /// Recipe completion percentage
  int get matchPercentage => (matchRatio * 100).round();
}