/// Result from searching ingredient terms
/// Contains the term along with recipe count and recipe details for display
class IngredientTermSearchResult {
  final String term;
  final int recipeCount;           // Number of recipes containing this term
  final List<String> recipeIds;    // IDs of recipes (for future use)
  final List<String> recipeTitles; // Titles of recipes (for future display)

  const IngredientTermSearchResult({
    required this.term,
    required this.recipeCount,
    required this.recipeIds,
    required this.recipeTitles,
  });

  /// Get a preview of recipe titles (first N recipes)
  String getRecipePreview({int maxRecipes = 3}) {
    if (recipeTitles.isEmpty) return '';
    if (recipeTitles.length <= maxRecipes) {
      return recipeTitles.join(', ');
    }
    final preview = recipeTitles.take(maxRecipes).join(', ');
    final remaining = recipeTitles.length - maxRecipes;
    return '$preview +$remaining more';
  }
}
