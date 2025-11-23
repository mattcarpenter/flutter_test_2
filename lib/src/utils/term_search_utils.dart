import '../models/ingredient_term_search_result.dart';

/// Utility class for processing ingredient term search results
class TermSearchUtils {
  /// Calculate Levenshtein distance between two strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }
    return v0[s2.length];
  }

  /// Sort search results by relevance to search query
  /// Uses Levenshtein distance - closest matches first
  /// Note: Repository already handles aggregation/deduplication, this just sorts
  static List<IngredientTermSearchResult> sortByRelevance(
    List<IngredientTermSearchResult> results,
    String searchQuery,
  ) {
    final queryLower = searchQuery.toLowerCase();
    final distances = <String, int>{};

    for (final result in results) {
      distances[result.term] = levenshteinDistance(queryLower, result.term.toLowerCase());
    }

    // Sort by distance (closest match first), then by recipe count (more recipes = better)
    final sorted = List<IngredientTermSearchResult>.from(results);
    sorted.sort((a, b) {
      final distA = distances[a.term]!;
      final distB = distances[b.term]!;
      if (distA != distB) return distA.compareTo(distB);
      // If same distance, prefer terms with more recipes
      if (a.recipeCount != b.recipeCount) return b.recipeCount.compareTo(a.recipeCount);
      return a.term.compareTo(b.term);
    });

    return sorted;
  }
}
