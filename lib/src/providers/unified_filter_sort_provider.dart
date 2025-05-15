import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/recipes/models/recipe_filter_sort.dart';

/// Contexts for different filter/sort scenarios
enum FilterContext {
  recipeSearch,
  recipeFolder,
  pantryMatch
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
    return _getDefaultState();
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
  
  /// Save state to preferences (stubbed)
  void _saveState() {
    // No-op for now - persistence will be implemented later if needed
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