import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/recipes/models/recipe_filter_sort.dart';

/// Contexts for different filter/sort scenarios
enum FilterContext {
  recipeSearch,
  recipeFolder,
  pantryMatch
}

/// Provider for shared preferences instance
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Creates a list of provider overrides with initialized shared preferences
Future<List<Override>> createSharedPreferencesOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
}

/// Unified filter/sort state that includes context
class UnifiedFilterSortState extends RecipeFilterSortState {
  final FilterContext context;

  const UnifiedFilterSortState({
    super.activeFilters = const {},
    super.activeSortOption = SortOption.alphabetical,
    super.sortDirection = SortDirection.ascending,
    super.folderId,
    super.searchQuery,
    required this.context,
  });

  @override
  UnifiedFilterSortState copyWith({
    Map<FilterType, dynamic>? activeFilters,
    SortOption? activeSortOption,
    SortDirection? sortDirection,
    String? folderId,
    String? searchQuery,
    FilterContext? context,
  }) {
    return UnifiedFilterSortState(
      activeFilters: activeFilters ?? this.activeFilters,
      activeSortOption: activeSortOption ?? this.activeSortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      folderId: folderId ?? this.folderId,
      searchQuery: searchQuery ?? this.searchQuery,
      context: context ?? this.context,
    );
  }

  @override
  UnifiedFilterSortState withFilter(FilterType type, dynamic value) {
    final newFilters = Map<FilterType, dynamic>.from(activeFilters);
    newFilters[type] = value;
    return copyWith(activeFilters: newFilters);
  }

  @override
  UnifiedFilterSortState withoutFilter(FilterType type) {
    final newFilters = Map<FilterType, dynamic>.from(activeFilters);
    newFilters.remove(type);
    return copyWith(activeFilters: newFilters);
  }

  @override
  UnifiedFilterSortState clearFilters() {
    return copyWith(activeFilters: {});
  }
}

/// Unified notifier that handles all filter/sort contexts
class UnifiedFilterSortNotifier extends Notifier<UnifiedFilterSortState> {
  late FilterContext _context;

  void setContext(FilterContext context) {
    _context = context;
  }

  @override
  UnifiedFilterSortState build() {
    // Default to recipe search context
    _context = FilterContext.recipeSearch;
    return _loadState();
  }

  /// Load state from preferences
  UnifiedFilterSortState _loadState() {
    final prefs = ref.read(sharedPreferencesProvider);

    // If SharedPreferences is not available, return default state
    if (prefs == null) {
      return _getDefaultState();
    }

    // Generate a unique key based on context
    final String prefsKey = _getPrefsKey();

    // Load sort option
    final sortOptionStr = prefs.getString('${prefsKey}_sortOption');
    SortOption sortOption = _getDefaultSortOption();
    if (sortOptionStr != null) {
      sortOption = SortOption.values.firstWhere(
        (opt) => opt.name == sortOptionStr,
        orElse: () => _getDefaultSortOption(),
      );
    }

    // Load sort direction
    final sortDirectionStr = prefs.getString('${prefsKey}_sortDirection');
    SortDirection sortDirection = _getDefaultSortDirection();
    if (sortDirectionStr != null) {
      sortDirection = SortDirection.values.firstWhere(
        (dir) => dir.name == sortDirectionStr,
        orElse: () => _getDefaultSortDirection(),
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
    
    // Load tags filter
    final tagsStr = prefs.getStringList('${prefsKey}_filter_tags');
    final tagsModeStr = prefs.getString('${prefsKey}_filter_tags_mode');
    if (tagsStr != null && tagsStr.isNotEmpty) {
      final mode = tagsModeStr != null 
        ? TagFilterMode.values.firstWhere(
            (m) => m.name == tagsModeStr,
            orElse: () => TagFilterMode.or,
          )
        : TagFilterMode.or;
      filters[FilterType.tags] = TagFilter(
        selectedTagIds: tagsStr,
        mode: mode,
      );
    }

    return UnifiedFilterSortState(
      activeFilters: filters,
      activeSortOption: sortOption,
      sortDirection: sortDirection,
      context: _context,
    );
  }

  // Get default state based on context
  UnifiedFilterSortState _getDefaultState() {
    return UnifiedFilterSortState(
      activeFilters: {},
      activeSortOption: _getDefaultSortOption(),
      sortDirection: _getDefaultSortDirection(),
      context: _context,
    );
  }

  // Get prefs key based on context
  String _getPrefsKey() {
    switch (_context) {
      case FilterContext.recipeSearch:
        return 'recipeSearch';
      case FilterContext.recipeFolder:
        return 'recipeFolder';
      case FilterContext.pantryMatch:
        return 'pantryMatch';
    }
  }

  // Get context-specific defaults for sort option
  SortOption _getDefaultSortOption() {
    switch (_context) {
      case FilterContext.recipeSearch:
      case FilterContext.recipeFolder:
        return SortOption.alphabetical;
      case FilterContext.pantryMatch:
        return SortOption.pantryMatch;
    }
  }

  // Get context-specific defaults for sort direction
  SortDirection _getDefaultSortDirection() {
    switch (_context) {
      case FilterContext.recipeSearch:
      case FilterContext.recipeFolder:
        return SortDirection.ascending;
      case FilterContext.pantryMatch:
        return SortDirection.descending;
    }
  }

  /// Update filters
  void updateFilter(FilterType type, dynamic value) {
    if (value == null) {
      state = state.withoutFilter(type);
    } else {
      state = state.withFilter(type, value);
    }
    _saveState();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.clearFilters();
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

  /// Save state to preferences
  void _saveState() {
    final prefs = ref.read(sharedPreferencesProvider);

    // If SharedPreferences is not available, don't try to save
    if (prefs == null) {
      return;
    }

    // Generate a unique key based on context
    final String prefsKey = _getPrefsKey();

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
          
        case FilterType.tags:
          final tagFilter = filterValue as TagFilter;
          prefs.setStringList('${prefsKey}_filter_tags', tagFilter.selectedTagIds);
          prefs.setString('${prefsKey}_filter_tags_mode', tagFilter.mode.name);
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
    if (!state.activeFilters.containsKey(FilterType.tags)) {
      prefs.remove('${prefsKey}_filter_tags');
      prefs.remove('${prefsKey}_filter_tags_mode');
    }
  }
}

// Create separate providers for each context
final recipeFolderFilterSortProvider = NotifierProvider<UnifiedFilterSortNotifier, UnifiedFilterSortState>(
  () {
    final notifier = UnifiedFilterSortNotifier();
    notifier.setContext(FilterContext.recipeFolder);
    return notifier;
  },
);

final recipeSearchFilterSortProvider = NotifierProvider<UnifiedFilterSortNotifier, UnifiedFilterSortState>(
  () {
    final notifier = UnifiedFilterSortNotifier();
    notifier.setContext(FilterContext.recipeSearch);
    return notifier;
  },
);

final pantryRecipeFilterSortProvider = NotifierProvider<UnifiedFilterSortNotifier, UnifiedFilterSortState>(
  () {
    final notifier = UnifiedFilterSortNotifier();
    notifier.setContext(FilterContext.pantryMatch);
    return notifier;
  },
);

// Convenience accessors with shorter names
final recipeFolderFilterSort = Provider<UnifiedFilterSortState>(
  (ref) => ref.watch(recipeFolderFilterSortProvider)
);

final recipeSearchFilterSort = Provider<UnifiedFilterSortState>(
  (ref) => ref.watch(recipeSearchFilterSortProvider)
);

final pantryRecipeFilterSort = Provider<UnifiedFilterSortState>(
  (ref) => ref.watch(pantryRecipeFilterSortProvider)
);
