import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/pantry/models/pantry_filter_sort.dart';
import '../../../database/models/pantry_items.dart';

/// Notifier for pantry filter/sort state with persistence
class PantryFilterSortNotifier extends Notifier<PantryFilterSortState> {
  @override
  PantryFilterSortState build() {
    return _loadState();
  }

  /// Load state from preferences
  PantryFilterSortState _loadState() {
    final prefs = ref.read(sharedPreferencesProvider);

    // If SharedPreferences is not available, return default state
    if (prefs == null) {
      return const PantryFilterSortState();
    }

    // Load sort option
    final sortOptionStr = prefs.getString('pantry_sortOption');
    PantrySortOption sortOption = PantrySortOption.category;
    if (sortOptionStr != null) {
      sortOption = PantrySortOption.values.firstWhere(
        (opt) => opt.name == sortOptionStr,
        orElse: () => PantrySortOption.category,
      );
    }

    // Load sort direction
    final sortDirectionStr = prefs.getString('pantry_sortDirection');
    SortDirection sortDirection = SortDirection.ascending;
    if (sortDirectionStr != null) {
      sortDirection = SortDirection.values.firstWhere(
        (dir) => dir.name == sortDirectionStr,
        orElse: () => SortDirection.ascending,
      );
    }

    // Load filters
    final Map<PantryFilterType, dynamic> filters = {};

    // Load category filter (list of selected categories)
    final categoryFiltersStr = prefs.getStringList('pantry_filter_category');
    if (categoryFiltersStr != null && categoryFiltersStr.isNotEmpty) {
      filters[PantryFilterType.category] = categoryFiltersStr;
    }

    // Load stock status filter (list of selected stock statuses)
    final stockStatusFiltersStr = prefs.getStringList('pantry_filter_stockStatus');
    if (stockStatusFiltersStr != null && stockStatusFiltersStr.isNotEmpty) {
      final stockStatuses = stockStatusFiltersStr.map((str) {
        return StockStatus.values.firstWhere(
          (status) => status.name == str,
          orElse: () => StockStatus.inStock,
        );
      }).toList();
      filters[PantryFilterType.stockStatus] = stockStatuses;
    }

    // Load hide staples filter
    final hideStaples = prefs.getBool('pantry_filter_hideStaples');
    if (hideStaples == true) {
      filters[PantryFilterType.hideStaples] = true;
    }

    return PantryFilterSortState(
      activeFilters: filters,
      activeSortOption: sortOption,
      sortDirection: sortDirection,
    );
  }

  /// Update filters
  void updateFilter(PantryFilterType type, dynamic value) {
    if (value == null || 
        (value is List && value.isEmpty) ||
        (value is bool && !value)) {
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
  void updateSortOption(PantrySortOption option) {
    state = state.copyWith(activeSortOption: option);
    _saveState();
  }

  /// Update sort direction
  void updateSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
    _saveState();
  }

  /// Save state to preferences
  void _saveState() {
    final prefs = ref.read(sharedPreferencesProvider);

    // If SharedPreferences is not available, don't try to save
    if (prefs == null) {
      return;
    }

    // Save sort option
    prefs.setString('pantry_sortOption', state.activeSortOption.name);

    // Save sort direction
    prefs.setString('pantry_sortDirection', state.sortDirection.name);

    // Save filters
    for (final filterEntry in state.activeFilters.entries) {
      final filterType = filterEntry.key;
      final filterValue = filterEntry.value;

      switch (filterType) {
        case PantryFilterType.category:
          final categoryFilters = filterValue as List<String>;
          prefs.setStringList('pantry_filter_category', categoryFilters);
          break;

        case PantryFilterType.stockStatus:
          final stockStatusFilters = filterValue as List<StockStatus>;
          final stockStatusNames = stockStatusFilters.map((status) => status.name).toList();
          prefs.setStringList('pantry_filter_stockStatus', stockStatusNames);
          break;

        case PantryFilterType.hideStaples:
          final hideStaples = filterValue as bool;
          prefs.setBool('pantry_filter_hideStaples', hideStaples);
          break;
      }
    }

    // Clear removed filters
    if (!state.activeFilters.containsKey(PantryFilterType.category)) {
      prefs.remove('pantry_filter_category');
    }
    if (!state.activeFilters.containsKey(PantryFilterType.stockStatus)) {
      prefs.remove('pantry_filter_stockStatus');
    }
    if (!state.activeFilters.containsKey(PantryFilterType.hideStaples)) {
      prefs.remove('pantry_filter_hideStaples');
    }
  }
}

/// Provider for pantry filter/sort state
final pantryFilterSortProvider = NotifierProvider<PantryFilterSortNotifier, PantryFilterSortState>(
  () => PantryFilterSortNotifier(),
);

/// Convenience accessor with shorter name
final pantryFilterSort = Provider<PantryFilterSortState>(
  (ref) => ref.watch(pantryFilterSortProvider),
);

/// Re-export shared preferences provider from recipe provider
/// Provider for shared preferences instance (reuse from recipe provider)
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);