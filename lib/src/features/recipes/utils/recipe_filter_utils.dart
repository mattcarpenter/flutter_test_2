import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/features/recipes/models/recipe_filter_sort.dart';
import 'package:recipe_app/src/models/recipe_pantry_match.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';

/// Utility class for filtering and sorting recipes
class RecipeFilterUtils {
  /// Apply folder filtering to recipes
  static List<RecipeEntry> applyFolderFilter(
    List<RecipeEntry> recipes, 
    String? folderId,
    String? uncategorizedFolderId,
  ) {
    if (folderId == null) {
      return recipes;
    }
    
    if (folderId == uncategorizedFolderId) {
      // Show recipes with no folder assignments
      return recipes.where((recipe) {
        return recipe.folderIds == null || recipe.folderIds!.isEmpty;
      }).toList();
    } else {
      // Show recipes in the specified folder
      return recipes.where((recipe) => 
        recipe.folderIds?.contains(folderId) ?? false
      ).toList();
    }
  }
  
  /// Apply all filters in filterState to a list of recipes
  static List<RecipeEntry> applyFilters({
    required List<RecipeEntry> recipes,
    required RecipeFilterSortState filterState,
    required AsyncValue<PantryRecipeMatchState> pantryMatchesAsyncValue,
  }) {
    if (!filterState.hasFilters) {
      return recipes;
    }
    
    List<RecipeEntry> filteredRecipes = recipes;
    
    // Handle pantry match filter separately if present
    final hasPantryMatchFilter = filterState.activeFilters.containsKey(FilterType.pantryMatch);
    
    if (hasPantryMatchFilter) {
      final pantryFilter = filterState.activeFilters[FilterType.pantryMatch] as PantryMatchFilter;
      
      // For "Any match" option, we'll treat it as no filter
      if (pantryFilter == PantryMatchFilter.anyMatch) {
        // No filtering needed - keep all recipes
      }
      // Check if we have loaded the pantry match data (even if it's empty)
      else if (pantryMatchesAsyncValue.value != null) {
        // Create a map of recipe IDs to their match percentage
        final Map<String, int> recipeMatchPercentages = {};
        
        for (final match in pantryMatchesAsyncValue.value!.matches) {
          recipeMatchPercentages[match.recipe.id] = match.matchPercentage;
        }
        
        // Filter recipes based on pantry match percentage
        filteredRecipes = filteredRecipes.where((recipe) {
          // If recipe isn't in the match data, its match percentage is 0
          final matchPercentage = recipeMatchPercentages[recipe.id] ?? 0;
          
          // Apply the appropriate filter
          switch (pantryFilter) {
            case PantryMatchFilter.anyMatch:
              // This case is handled above - should never reach here
              return true;
            case PantryMatchFilter.goodMatch:
              return matchPercentage >= 50;
            case PantryMatchFilter.greatMatch:
              return matchPercentage >= 75;
            case PantryMatchFilter.perfectMatch:
              return matchPercentage == 100;
          }
        }).toList();
      }
      
      // Remove pantry filter before applying other filters
      final otherFilters = Map<FilterType, dynamic>.from(filterState.activeFilters);
      otherFilters.remove(FilterType.pantryMatch);
      
      // Apply other filters
      if (otherFilters.isNotEmpty) {
        filteredRecipes = filteredRecipes.applyFilters(otherFilters);
      }
    } else {
      // No pantry filter, just apply regular filters
      filteredRecipes = filteredRecipes.applyFilters(filterState.activeFilters);
    }
    
    return filteredRecipes;
  }
  
  /// Apply sorting to recipes
  static List<RecipeEntry> applySorting({
    required List<RecipeEntry> recipes,
    required RecipeFilterSortState filterState,
  }) {
    return recipes.applySorting(
      filterState.activeSortOption,
      filterState.sortDirection,
    );
  }
  
  /// Check if pantry match data is needed and still loading
  static bool isPantryMatchLoading({
    required RecipeFilterSortState filterState,
    required AsyncValue<PantryRecipeMatchState> pantryMatchesAsyncValue,
  }) {
    return filterState.activeFilters.containsKey(FilterType.pantryMatch) &&
           pantryMatchesAsyncValue.isLoading;
  }
  
  /// Ensure pantry match data is loaded if needed for filtering
  static void loadPantryMatchesIfNeeded({
    required RecipeFilterSortState filterState,
    required AsyncValue<PantryRecipeMatchState> pantryMatchesAsyncValue,
    required WidgetRef ref,
  }) {
    if (filterState.activeFilters.containsKey(FilterType.pantryMatch)) {
      // Always reload data when filter is active to ensure we have latest matches
      ref.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();
    }
  }
}