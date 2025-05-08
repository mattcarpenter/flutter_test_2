import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/models/recipe_pantry_match.dart';

/// Types of filters that can be applied to recipes
enum FilterType {
  cookTime,
  rating,
  pantryMatch,
}

/// Filter options for cook time
enum CookTimeFilter {
  under30Min('Under 30 minutes', 30),
  between30And60Min('30-60 minutes', 60),
  between1And2Hours('1-2 hours', 120),
  over2Hours('Over 2 hours', 120);

  const CookTimeFilter(this.label, this.minutes);
  final String label;
  final int minutes;
}

/// Filter options for recipe rating
enum RatingFilter {
  oneStar('1+ Stars', 1),
  twoStars('2+ Stars', 2),
  threeStars('3+ Stars', 3),
  fourStars('4+ Stars', 4),
  fiveStars('5 Stars', 5);

  const RatingFilter(this.label, this.value);
  final String label;
  final int value;
}

/// Filter options for pantry match percentage
enum PantryMatchFilter {
  anyMatch('Any match (>0%)', 0),
  goodMatch('Good match (>50%)', 50),
  greatMatch('Great match (>75%)', 75),
  perfectMatch('Perfect match (100%)', 100);

  const PantryMatchFilter(this.label, this.percentage);
  final String label;
  final int percentage;
}

/// Sorting options for recipes
enum SortOption {
  pantryMatch('Pantry Match %'),
  alphabetical('Alphabetical'),
  rating('Rating'),
  time('Time (Fastest First)'),
  recentlyAdded('Recently Added'),
  recentlyUpdated('Recently Updated');

  const SortOption(this.label);
  final String label;
}

/// Direction for sorting (ascending or descending)
enum SortDirection {
  ascending,
  descending,
}

/// State class for filter and sort configuration
class RecipeFilterSortState {
  /// Active filters by type
  final Map<FilterType, dynamic> activeFilters;
  
  /// Current sort option
  final SortOption activeSortOption;
  
  /// Current sort direction
  final SortDirection sortDirection;
  
  /// Current folder ID (if filtering by folder)
  final String? folderId;
  
  /// Current search query (if filtering by search)
  final String? searchQuery;
  
  /// Whether filters are currently applied
  bool get hasFilters => activeFilters.isNotEmpty;
  
  /// Number of active filters
  int get filterCount => activeFilters.length;

  const RecipeFilterSortState({
    this.activeFilters = const {},
    this.activeSortOption = SortOption.alphabetical,
    this.sortDirection = SortDirection.ascending,
    this.folderId,
    this.searchQuery,
  });

  RecipeFilterSortState copyWith({
    Map<FilterType, dynamic>? activeFilters,
    SortOption? activeSortOption,
    SortDirection? sortDirection,
    String? folderId,
    String? searchQuery,
  }) {
    return RecipeFilterSortState(
      activeFilters: activeFilters ?? this.activeFilters,
      activeSortOption: activeSortOption ?? this.activeSortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      folderId: folderId ?? this.folderId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
  
  /// Adds or updates a filter
  RecipeFilterSortState withFilter(FilterType type, dynamic value) {
    final newFilters = Map<FilterType, dynamic>.from(activeFilters);
    newFilters[type] = value;
    return copyWith(activeFilters: newFilters);
  }
  
  /// Removes a filter
  RecipeFilterSortState withoutFilter(FilterType type) {
    final newFilters = Map<FilterType, dynamic>.from(activeFilters);
    newFilters.remove(type);
    return copyWith(activeFilters: newFilters);
  }
  
  /// Clears all filters
  RecipeFilterSortState clearFilters() {
    return copyWith(activeFilters: {});
  }
}

/// Extension methods for applying filters and sorting to recipe lists
extension RecipeFiltering on List<RecipeEntry> {
  /// Apply filters to a recipe list
  List<RecipeEntry> applyFilters(Map<FilterType, dynamic> filters) {
    if (filters.isEmpty) return this;
    
    print('Filtering ${length} recipes with filters: $filters');
    
    return where((recipe) {
      // Check each filter type
      for (final filterEntry in filters.entries) {
        final filterType = filterEntry.key;
        final filterValue = filterEntry.value;
        
        switch (filterType) {
          case FilterType.cookTime:
            final cookTimeFilter = filterValue as CookTimeFilter;
            final totalTime = recipe.totalTime ?? 
                             (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);
            
            // Skip if we don't have time information
            if (totalTime == 0) continue;
            
            bool matches = false;
            switch (cookTimeFilter) {
              case CookTimeFilter.under30Min:
                matches = totalTime <= 30;
                break;
              case CookTimeFilter.between30And60Min:
                matches = totalTime > 30 && totalTime <= 60;
                break;
              case CookTimeFilter.between1And2Hours:
                matches = totalTime > 60 && totalTime <= 120;
                break;
              case CookTimeFilter.over2Hours:
                matches = totalTime > 120;
                break;
            }
            
            if (!matches) {
              return false;
            }
            
          case FilterType.rating:
            final ratingFilter = filterValue as RatingFilter;
            // Skip if recipe has no rating
            if (recipe.rating == null) continue;
            if (recipe.rating! < ratingFilter.value) return false;
            
          case FilterType.pantryMatch:
            // This filter needs to be applied separately with pantry match data
            // We'll skip it in this function and handle it in RecipesFolderPage
            print('Skipping pantry match filter in RecipeFiltering extension');
            continue;
        }
      }
      
      return true;
    }).toList();
  }
}

/// Extension methods for applying filters and sorting to recipe pantry matches
extension RecipePantryMatchFiltering on List<RecipePantryMatch> {
  /// Apply filters to a recipe pantry match list
  List<RecipePantryMatch> applyFilters(Map<FilterType, dynamic> filters) {
    if (filters.isEmpty) return this;
    
    return where((match) {
      // First apply regular recipe filters
      final recipe = match.recipe;
      
      // Check each filter type
      for (final filterEntry in filters.entries) {
        final filterType = filterEntry.key;
        final filterValue = filterEntry.value;
        
        switch (filterType) {
          case FilterType.cookTime:
            final cookTimeFilter = filterValue as CookTimeFilter;
            final totalTime = recipe.totalTime ?? 
                             (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);
            
            // Skip if we don't have time information
            if (totalTime == 0) continue;
            
            bool matches = false;
            switch (cookTimeFilter) {
              case CookTimeFilter.under30Min:
                matches = totalTime <= 30;
                break;
              case CookTimeFilter.between30And60Min:
                matches = totalTime > 30 && totalTime <= 60;
                break;
              case CookTimeFilter.between1And2Hours:
                matches = totalTime > 60 && totalTime <= 120;
                break;
              case CookTimeFilter.over2Hours:
                matches = totalTime > 120;
                break;
            }
            
            if (!matches) {
              return false;
            }
            
          case FilterType.rating:
            final ratingFilter = filterValue as RatingFilter;
            // Skip if recipe has no rating
            if (recipe.rating == null) continue;
            if (recipe.rating! < ratingFilter.value) return false;
            
          case FilterType.pantryMatch:
            final pantryMatchFilter = filterValue as PantryMatchFilter;
            final matchPercentage = match.matchPercentage;
            
            bool matches = false;
            switch (pantryMatchFilter) {
              case PantryMatchFilter.anyMatch:
                matches = matchPercentage > 0;
                break;
              case PantryMatchFilter.goodMatch:
                matches = matchPercentage > 50;
                break;
              case PantryMatchFilter.greatMatch:
                matches = matchPercentage > 75;
                break;
              case PantryMatchFilter.perfectMatch:
                matches = matchPercentage == 100;
                break;
            }
            
            if (!matches) {
              return false;
            }
        }
      }
      
      return true;
    }).toList();
  }
}

/// Extension methods for sorting recipe lists
extension RecipeSorting on List<RecipeEntry> {
  /// Sort recipes based on the specified option and direction
  List<RecipeEntry> applySorting(SortOption option, SortDirection direction) {
    final sortedList = List<RecipeEntry>.from(this);
    
    switch (option) {
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
        // This sort option needs to be handled by RecipePantryMatchSorting extension
        break;
    }
    
    // Apply direction (sortedList is already in the correct order for defaults)
    if ((option == SortOption.alphabetical && direction == SortDirection.descending) ||
        ((option == SortOption.time) && direction == SortDirection.descending) ||
        ((option != SortOption.alphabetical && option != SortOption.time) && 
         direction == SortDirection.ascending)) {
      return sortedList.reversed.toList();
    }
    
    return sortedList;
  }
}

/// Extension methods for sorting recipe pantry matches
extension RecipePantryMatchSorting on List<RecipePantryMatch> {
  /// Sort recipe pantry matches based on the specified option and direction
  List<RecipePantryMatch> applySorting(SortOption option, SortDirection direction) {
    final sortedList = List<RecipePantryMatch>.from(this);
    
    switch (option) {
      case SortOption.pantryMatch:
        sortedList.sort((a, b) {
          // Sort by match ratio (descending) then alphabetically for equal ratios
          final ratioComparison = b.matchRatio.compareTo(a.matchRatio);
          if (ratioComparison != 0) return ratioComparison;
          return a.recipe.title.compareTo(b.recipe.title);
        });
        
      case SortOption.alphabetical:
        sortedList.sort((a, b) => a.recipe.title.compareTo(b.recipe.title));
        
      case SortOption.rating:
        sortedList.sort((a, b) {
          // Handle null ratings (null values go last)
          if (a.recipe.rating == null && b.recipe.rating == null) return 0;
          if (a.recipe.rating == null) return 1;
          if (b.recipe.rating == null) return -1;
          
          // Sort by rating (descending) then by title (ascending) for equal ratings
          final ratingComparison = b.recipe.rating!.compareTo(a.recipe.rating!);
          if (ratingComparison != 0) return ratingComparison;
          return a.recipe.title.compareTo(b.recipe.title);
        });
        
      case SortOption.time:
        sortedList.sort((a, b) {
          // Calculate total time, defaulting to prep + cook if total not available
          final aTime = a.recipe.totalTime ?? 
                       ((a.recipe.prepTime ?? 0) + (a.recipe.cookTime ?? 0));
          final bTime = b.recipe.totalTime ?? 
                       ((b.recipe.prepTime ?? 0) + (b.recipe.cookTime ?? 0));
          
          // Handle null/zero times (they go last)
          if (aTime == 0 && bTime == 0) return a.recipe.title.compareTo(b.recipe.title);
          if (aTime == 0) return 1;
          if (bTime == 0) return -1;
          
          // Sort by time (ascending) then alphabetically for equal times
          final timeComparison = aTime.compareTo(bTime);
          if (timeComparison != 0) return timeComparison;
          return a.recipe.title.compareTo(b.recipe.title);
        });
        
      case SortOption.recentlyAdded:
        sortedList.sort((a, b) {
          // Handle null created dates (null values go last)
          if (a.recipe.createdAt == null && b.recipe.createdAt == null) return 0;
          if (a.recipe.createdAt == null) return 1;
          if (b.recipe.createdAt == null) return -1;
          
          // Sort by created date (descending)
          return b.recipe.createdAt!.compareTo(a.recipe.createdAt!);
        });
        
      case SortOption.recentlyUpdated:
        sortedList.sort((a, b) {
          // Handle null updated dates (null values go last)
          if (a.recipe.updatedAt == null && b.recipe.updatedAt == null) return 0;
          if (a.recipe.updatedAt == null) return 1;
          if (b.recipe.updatedAt == null) return -1;
          
          // Sort by updated date (descending)
          return b.recipe.updatedAt!.compareTo(a.recipe.updatedAt!);
        });
    }
    
    // Apply direction (sortedList is already in the correct order for defaults)
    if ((option == SortOption.alphabetical && direction == SortDirection.descending) ||
        ((option == SortOption.time) && direction == SortDirection.descending) ||
        ((option != SortOption.alphabetical && option != SortOption.time) && 
         direction == SortDirection.ascending)) {
      return sortedList.reversed.toList();
    }
    
    return sortedList;
  }
}