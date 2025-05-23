import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/features/recipes/models/recipe_filter_sort.dart';
import 'package:recipe_app/src/models/recipe_pantry_match.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/providers/recipe_filter_sort_provider.dart';

/// Utility class for filtering and sorting recipes
class FilterUtils {
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
    required UnifiedFilterSortState filterState,
    required AsyncValue<PantryRecipeMatchState> pantryMatchesAsyncValue,
  }) {
    if (!filterState.hasFilters) {
      return recipes;
    }

    // Build a list of predicates to apply for each active filter
    final predicates = <bool Function(RecipeEntry)>[];

    // Add predicates for each filter type
    filterState.activeFilters.forEach((type, value) {
      switch (type) {
        case FilterType.cookTime:
          predicates.add(_buildCookTimeFilter(value as CookTimeFilter));
          break;
        case FilterType.rating:
          predicates.add(_buildRatingFilter(value as RatingFilter));
          break;
        case FilterType.pantryMatch:
          if (pantryMatchesAsyncValue.value != null) {
            // Create a map of recipe IDs to their match percentages for efficient lookup
            final Map<String, int> recipeMatchPercentages = {};
            for (final match in pantryMatchesAsyncValue.value!.matches) {
              recipeMatchPercentages[match.recipe.id] = match.matchPercentage;
            }

            predicates.add(_buildPantryMatchFilter(
              value as PantryMatchFilter,
              recipeMatchPercentages
            ));
          }
          break;
      }
    });

    // Apply all predicates - a recipe must pass ALL filters to be included
    return recipes.where((recipe) =>
      predicates.every((predicate) => predicate(recipe))
    ).toList();
  }

  /// Apply sorting to recipes
  static List<RecipeEntry> applySorting({
    required List<RecipeEntry> recipes,
    required UnifiedFilterSortState filterState,
  }) {
    final sortedList = List<RecipeEntry>.from(recipes);

    switch (filterState.activeSortOption) {
      case SortOption.alphabetical:
        sortedList.sort((a, b) => a.title.compareTo(b.title));

      case SortOption.rating:
        sortedList.sort((a, b) {
          // Handle null ratings (null values go last)
          if (a.rating == null && b.rating == null) return 0;
          if (a.rating == null) return 1;
          if (b.rating == null) return -1;

          // Sort by rating (descending) then by title (ascending) for equal ratings
          final ratingComparison = b.rating!.compareTo(a.rating!);
          if (ratingComparison != 0) return ratingComparison;
          return a.title.compareTo(b.title);
        });

      case SortOption.time:
        sortedList.sort((a, b) {
          // Calculate total time, defaulting to prep + cook if total not available
          final aTime = a.totalTime ?? ((a.prepTime ?? 0) + (a.cookTime ?? 0));
          final bTime = b.totalTime ?? ((b.prepTime ?? 0) + (b.cookTime ?? 0));

          // Handle null/zero times (they go last)
          if (aTime == 0 && bTime == 0) return a.title.compareTo(b.title);
          if (aTime == 0) return 1;
          if (bTime == 0) return -1;

          // Sort by time (ascending) then alphabetically for equal times
          final timeComparison = aTime.compareTo(bTime);
          if (timeComparison != 0) return timeComparison;
          return a.title.compareTo(b.title);
        });

      case SortOption.recentlyAdded:
        sortedList.sort((a, b) {
          // Handle null created dates (null values go last)
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;

          // Sort by created date (descending)
          return b.createdAt!.compareTo(a.createdAt!);
        });

      case SortOption.recentlyUpdated:
        sortedList.sort((a, b) {
          // Handle null updated dates (null values go last)
          if (a.updatedAt == null && b.updatedAt == null) return 0;
          if (a.updatedAt == null) return 1;
          if (b.updatedAt == null) return -1;

          // Sort by updated date (descending)
          return b.updatedAt!.compareTo(a.updatedAt!);
        });

      case SortOption.pantryMatch:
        // This needs special handling with pantry match data
        // and should be handled separately when we have that data
        break;
    }

    // Apply direction
    if ((filterState.activeSortOption == SortOption.alphabetical &&
         filterState.sortDirection == SortDirection.descending) ||
        ((filterState.activeSortOption == SortOption.time) &&
         filterState.sortDirection == SortDirection.descending) ||
        ((filterState.activeSortOption != SortOption.alphabetical &&
          filterState.activeSortOption != SortOption.time) &&
         filterState.sortDirection == SortDirection.ascending)) {
      return sortedList.reversed.toList();
    }

    return sortedList;
  }

  /// Apply pantry match sorting with actual match data
  static List<RecipeEntry> applyPantryMatchSorting({
    required List<RecipeEntry> recipes,
    required AsyncValue<PantryRecipeMatchState> pantryMatchesAsyncValue,
    required SortDirection sortDirection,
  }) {
    // If we don't have pantry match data, fall back to alphabetical
    if (pantryMatchesAsyncValue.value == null) {
      final sorted = List<RecipeEntry>.from(recipes)
        ..sort((a, b) => a.title.compareTo(b.title));
      return sortDirection == SortDirection.descending ?
        sorted.reversed.toList() : sorted;
    }

    // Create a map of recipe IDs to their match percentages
    final Map<String, int> recipeMatchPercentages = {};
    for (final match in pantryMatchesAsyncValue.value!.matches) {
      recipeMatchPercentages[match.recipe.id] = match.matchPercentage;
    }

    // Sort recipes by match percentage
    final sorted = List<RecipeEntry>.from(recipes)
      ..sort((a, b) {
        final aPercentage = recipeMatchPercentages[a.id] ?? 0;
        final bPercentage = recipeMatchPercentages[b.id] ?? 0;

        final percentageComparison = bPercentage.compareTo(aPercentage);
        if (percentageComparison != 0) return percentageComparison;

        // For equal percentages, sort alphabetically
        return a.title.compareTo(b.title);
      });

    // Reverse if needed
    return sortDirection == SortDirection.ascending ?
      sorted.reversed.toList() : sorted;
  }

  /// Check if pantry match data is needed and still loading
  static bool isPantryMatchLoading({
    required UnifiedFilterSortState filterState,
    required AsyncValue<PantryRecipeMatchState> pantryMatchesAsyncValue,
  }) {
    return filterState.activeFilters.containsKey(FilterType.pantryMatch) &&
           pantryMatchesAsyncValue.isLoading;
  }

  /// Function to ensure pantry match data is loaded when needed
  static void loadPantryMatchesIfNeeded({
    required UnifiedFilterSortState filterState,
    required WidgetRef ref,
  }) {
    if (filterState.activeFilters.containsKey(FilterType.pantryMatch)) {
      // Always reload data when filter is active to ensure we have latest matches
      ref.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();
    }
  }

  // Private predicate builder functions
  static bool Function(RecipeEntry) _buildCookTimeFilter(CookTimeFilter filter) {
    return (recipe) {
      final totalTime = recipe.totalTime ??
                       (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);

      // Skip if we don't have time information
      if (totalTime == 0) return true;

      switch (filter) {
        case CookTimeFilter.under30Min:
          return totalTime <= 30;
        case CookTimeFilter.between30And60Min:
          return totalTime > 30 && totalTime <= 60;
        case CookTimeFilter.between1And2Hours:
          return totalTime > 60 && totalTime <= 120;
        case CookTimeFilter.over2Hours:
          return totalTime > 120;
      }
    };
  }

  static bool Function(RecipeEntry) _buildRatingFilter(RatingFilter filter) {
    return (recipe) {
      // Skip if recipe has no rating
      if (recipe.rating == null) return true;
      return recipe.rating! >= filter.value;
    };
  }

  static bool Function(RecipeEntry) _buildPantryMatchFilter(
    PantryMatchFilter filter,
    Map<String, int> recipeMatchPercentages,
  ) {
    return (recipe) {
      // If recipe isn't in the match data, its match percentage is 0
      final matchPercentage = recipeMatchPercentages[recipe.id] ?? 0;

      switch (filter) {
        case PantryMatchFilter.anyMatch:
          return matchPercentage > 0;
        case PantryMatchFilter.goodMatch:
          return matchPercentage >= 50;
        case PantryMatchFilter.greatMatch:
          return matchPercentage >= 75;
        case PantryMatchFilter.perfectMatch:
          return matchPercentage == 100;
      }
    };
  }
}
