import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/recipes/models/recipe_filter_sort.dart';

/// Provider for shared preferences instance
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Creates a list of provider overrides with initialized shared preferences
Future<List<Override>> createSharedPreferencesOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
}

/// Base class for all filter/sort notifiers
abstract class FilterSortNotifier extends Notifier<RecipeFilterSortState> {
  /// Unique key for persisting preferences
  String get prefsKey;
  
  /// Default sort option
  SortOption get defaultSortOption;
  
  /// Default sort direction
  SortDirection get defaultSortDirection;
  
  @override
  RecipeFilterSortState build() {
    return _loadState();
  }
  
  /// Update filters
  void updateFilter(FilterType type, dynamic value) {
    print('Updating filter: $type = $value');
    if (value == null) {
      state = state.withoutFilter(type);
    } else {
      state = state.withFilter(type, value);
    }
    print('New filter state: ${state.activeFilters}');
    _saveState();
  }
  
  /// Clear all filters
  void clearFilters() {
    print('Clearing all filters');
    state = state.clearFilters();
    print('New filter state after clear: ${state.activeFilters}');
    _saveState();
  }
  
  /// Update sort option
  void updateSortOption(SortOption option) {
    state = state.copyWith(activeSortOption: option);
    _saveState();
  }
  
  /// Update sort direction
  void updateSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
    _saveState();
  }
  
  /// Update folder ID
  void updateFolderId(String? folderId) {
    state = state.copyWith(folderId: folderId);
    _saveState();
  }
  
  /// Update search query
  void updateSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    // Don't save search query to preferences
  }
  
  /// Load state from preferences
  RecipeFilterSortState _loadState() {
    final prefs = ref.read(sharedPreferencesProvider);
    
    // If SharedPreferences is not available, return default state
    if (prefs == null) {
      return RecipeFilterSortState(
        activeFilters: {},
        activeSortOption: defaultSortOption,
        sortDirection: defaultSortDirection,
      );
    }
    
    // Load sort option
    final sortOptionStr = prefs.getString('${prefsKey}_sortOption');
    SortOption sortOption = defaultSortOption;
    if (sortOptionStr != null) {
      sortOption = SortOption.values.firstWhere(
        (opt) => opt.name == sortOptionStr,
        orElse: () => defaultSortOption,
      );
    }
    
    // Load sort direction
    final sortDirectionStr = prefs.getString('${prefsKey}_sortDirection');
    SortDirection sortDirection = defaultSortDirection;
    if (sortDirectionStr != null) {
      sortDirection = SortDirection.values.firstWhere(
        (dir) => dir.name == sortDirectionStr,
        orElse: () => defaultSortDirection,
      );
    }
    
    // Filters are more complex - store as separate keys
    final Map<FilterType, dynamic> filters = {};
    
    // Load cook time filter
    final cookTimeStr = prefs.getString('${prefsKey}_filter_cookTime');
    if (cookTimeStr != null) {
      final cookTimeFilter = CookTimeFilter.values.firstWhere(
        (filter) => filter.name == cookTimeStr,
        orElse: () => CookTimeFilter.under30Min,
      );
      filters[FilterType.cookTime] = cookTimeFilter;
    }
    
    // Load rating filter
    final ratingStr = prefs.getString('${prefsKey}_filter_rating');
    if (ratingStr != null) {
      final ratingFilter = RatingFilter.values.firstWhere(
        (filter) => filter.name == ratingStr,
        orElse: () => RatingFilter.fourStars,
      );
      filters[FilterType.rating] = ratingFilter;
    }
    
    // Load pantry match filter
    final pantryMatchStr = prefs.getString('${prefsKey}_filter_pantryMatch');
    if (pantryMatchStr != null) {
      final pantryMatchFilter = PantryMatchFilter.values.firstWhere(
        (filter) => filter.name == pantryMatchStr,
        orElse: () => PantryMatchFilter.goodMatch,
      );
      filters[FilterType.pantryMatch] = pantryMatchFilter;
    }
    
    return RecipeFilterSortState(
      activeFilters: filters,
      activeSortOption: sortOption,
      sortDirection: sortDirection,
    );
  }
  
  /// Save state to preferences
  void _saveState() {
    print('Saving filter state: ${state.activeFilters}');
    
    final prefs = ref.read(sharedPreferencesProvider);
    
    // If SharedPreferences is not available, don't try to save
    if (prefs == null) {
      print('SharedPreferences is null, cannot save state');
      return;
    }
    
    // Save sort option
    prefs.setString('${prefsKey}_sortOption', state.activeSortOption.name);
    
    // Save sort direction
    prefs.setString('${prefsKey}_sortDirection', state.sortDirection.name);
    
    // Save filters
    for (final filterEntry in state.activeFilters.entries) {
      final filterType = filterEntry.key;
      final filterValue = filterEntry.value;
      
      switch (filterType) {
        case FilterType.cookTime:
          final cookTimeFilter = filterValue as CookTimeFilter;
          prefs.setString('${prefsKey}_filter_cookTime', cookTimeFilter.name);
          break;
        
        case FilterType.rating:
          final ratingFilter = filterValue as RatingFilter;
          prefs.setString('${prefsKey}_filter_rating', ratingFilter.name);
          break;
          
        case FilterType.pantryMatch:
          final pantryMatchFilter = filterValue as PantryMatchFilter;
          prefs.setString('${prefsKey}_filter_pantryMatch', pantryMatchFilter.name);
          break;
      }
    }
    
    // Clear removed filters
    if (!state.activeFilters.containsKey(FilterType.cookTime)) {
      prefs.remove('${prefsKey}_filter_cookTime');
    }
    if (!state.activeFilters.containsKey(FilterType.rating)) {
      prefs.remove('${prefsKey}_filter_rating');
    }
    if (!state.activeFilters.containsKey(FilterType.pantryMatch)) {
      prefs.remove('${prefsKey}_filter_pantryMatch');
    }
  }
}

/// Notifier for recipe folder browsing filter/sort state
class RecipeFolderFilterSortNotifier extends FilterSortNotifier {
  @override
  String get prefsKey => 'recipeFolderBrowse';
  
  @override
  SortOption get defaultSortOption => SortOption.alphabetical;
  
  @override
  SortDirection get defaultSortDirection => SortDirection.ascending;
}

/// Notifier for recipe search filter/sort state
class RecipeSearchFilterSortNotifier extends FilterSortNotifier {
  @override
  String get prefsKey => 'recipeSearch';
  
  @override
  SortOption get defaultSortOption => SortOption.alphabetical;
  
  @override
  SortDirection get defaultSortDirection => SortDirection.ascending;
}

/// Notifier for pantry recipe matching filter/sort state
class PantryRecipeFilterSortNotifier extends FilterSortNotifier {
  @override
  String get prefsKey => 'pantryRecipeMatch';
  
  @override
  SortOption get defaultSortOption => SortOption.pantryMatch;
  
  @override
  SortDirection get defaultSortDirection => SortDirection.descending;
}

/// Provider for recipe folder browsing filter/sort state
final recipeFolderFilterSortProvider = NotifierProvider<RecipeFolderFilterSortNotifier, RecipeFilterSortState>(
  RecipeFolderFilterSortNotifier.new,
);

/// Provider for recipe search filter/sort state
final recipeSearchFilterSortProvider = NotifierProvider<RecipeSearchFilterSortNotifier, RecipeFilterSortState>(
  RecipeSearchFilterSortNotifier.new,
);

/// Provider for pantry recipe matching filter/sort state
final pantryRecipeFilterSortProvider = NotifierProvider<PantryRecipeFilterSortNotifier, RecipeFilterSortState>(
  PantryRecipeFilterSortNotifier.new,
);