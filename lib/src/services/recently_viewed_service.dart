import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing recently viewed recipes in local storage.
/// Maintains a list of up to 100 recently viewed recipe IDs.
class RecentlyViewedRecipesService {
  static const String _prefKey = 'recently_viewed_recipes';
  static const int _maxRecipes = 100;

  /// Loads the list of recently viewed recipe IDs from SharedPreferences.
  /// Returns empty list if no data exists or on error.
  Future<List<String>> getRecentlyViewedRecipeIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefKey) ?? [];
    } catch (e) {
      // Return empty list on any error
      return [];
    }
  }

  /// Adds a recipe ID to the top of the recently viewed list.
  /// - Removes existing occurrence if present
  /// - Adds to beginning of list  
  /// - Limits to maximum 100 items
  /// - Persists to SharedPreferences
  Future<void> addRecentlyViewed(String recipeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_prefKey) ?? [];
      
      // Remove existing occurrence
      current.remove(recipeId);
      
      // Add to beginning
      current.insert(0, recipeId);
      
      // Limit to max size
      if (current.length > _maxRecipes) {
        current.removeRange(_maxRecipes, current.length);
      }
      
      // Save back to preferences
      await prefs.setStringList(_prefKey, current);
    } catch (e) {
      // Silently fail - non-critical feature
    }
  }

  /// Removes a recipe ID from the recently viewed list.
  /// Used when recipes are deleted to keep data clean.
  Future<void> removeRecentlyViewed(String recipeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_prefKey) ?? [];
      
      if (current.remove(recipeId)) {
        await prefs.setStringList(_prefKey, current);
      }
    } catch (e) {
      // Silently fail - non-critical feature
    }
  }

  /// Clears all recently viewed recipes.
  Future<void> clearRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (e) {
      // Silently fail - non-critical feature
    }
  }
}