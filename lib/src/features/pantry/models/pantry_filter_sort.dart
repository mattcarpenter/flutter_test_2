import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';

/// Types of filters that can be applied to pantry items
enum PantryFilterType {
  category,
  stockStatus,
  showStaples,
  search,
}

/// Filter options for stock status
enum StockStatusFilter {
  outOfStock('Out of Stock', StockStatus.outOfStock),
  lowStock('Low Stock', StockStatus.lowStock),
  inStock('In Stock', StockStatus.inStock);

  const StockStatusFilter(this.label, this.stockStatus);
  final String label;
  final StockStatus stockStatus;
}

/// Sorting options for pantry items
enum PantrySortOption {
  category('Category'),
  alphabetical('Alphabetical'),
  dateAdded('Date Added'),
  dateModified('Date Modified'),
  stockStatus('Stock Status');

  const PantrySortOption(this.label);
  final String label;
}

/// Direction for sorting (ascending or descending)
enum SortDirection {
  ascending,
  descending,
}

/// State class for pantry filter and sort configuration
class PantryFilterSortState {
  /// Active filters by type
  final Map<PantryFilterType, dynamic> activeFilters;
  
  /// Current sort option
  final PantrySortOption activeSortOption;
  
  /// Current sort direction
  final SortDirection sortDirection;
  
  /// Whether filters are currently applied
  bool get hasFilters => activeFilters.isNotEmpty;
  
  /// Number of active filters
  int get filterCount => activeFilters.length;

  /// Whether category headers should be shown (only when sorting by category)
  bool get showCategoryHeaders => activeSortOption == PantrySortOption.category;

  /// Current search query (empty string if no search active)
  String get searchQuery => activeFilters[PantryFilterType.search] as String? ?? '';

  const PantryFilterSortState({
    this.activeFilters = const {},
    this.activeSortOption = PantrySortOption.category,
    this.sortDirection = SortDirection.ascending,
  });

  PantryFilterSortState copyWith({
    Map<PantryFilterType, dynamic>? activeFilters,
    PantrySortOption? activeSortOption,
    SortDirection? sortDirection,
  }) {
    return PantryFilterSortState(
      activeFilters: activeFilters ?? this.activeFilters,
      activeSortOption: activeSortOption ?? this.activeSortOption,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
  
  /// Adds or updates a filter
  PantryFilterSortState withFilter(PantryFilterType type, dynamic value) {
    final newFilters = Map<PantryFilterType, dynamic>.from(activeFilters);
    newFilters[type] = value;
    return copyWith(activeFilters: newFilters);
  }
  
  /// Removes a filter
  PantryFilterSortState withoutFilter(PantryFilterType type) {
    final newFilters = Map<PantryFilterType, dynamic>.from(activeFilters);
    newFilters.remove(type);
    return copyWith(activeFilters: newFilters);
  }
  
  /// Clears all filters
  PantryFilterSortState clearFilters() {
    return copyWith(activeFilters: {});
  }
}

/// Extension methods for applying filters and sorting to pantry item lists
extension PantryItemFiltering on List<PantryItemEntry> {
  /// Apply filters to a pantry item list
  List<PantryItemEntry> applyFilters(Map<PantryFilterType, dynamic> filters) {
    if (filters.isEmpty) return this;
    
    return where((item) {
      // Check each filter type
      for (final filterEntry in filters.entries) {
        final filterType = filterEntry.key;
        final filterValue = filterEntry.value;
        
        switch (filterType) {
          case PantryFilterType.category:
            final categoryFilters = filterValue as List<String>;
            if (categoryFilters.isNotEmpty) {
              final itemCategory = item.category ?? 'Other';
              if (!categoryFilters.contains(itemCategory)) {
                return false;
              }
            }
            
          case PantryFilterType.stockStatus:
            final stockStatusFilters = filterValue as List<StockStatus>;
            if (stockStatusFilters.isNotEmpty) {
              if (!stockStatusFilters.contains(item.stockStatus)) {
                return false;
              }
            }
            
          case PantryFilterType.showStaples:
            final showStaples = filterValue as bool;
            if (!showStaples && item.isStaple) {
              return false;
            }
            
          case PantryFilterType.search:
            final searchQuery = filterValue as String;
            if (searchQuery.isNotEmpty) {
              if (!item.name.toLowerCase().contains(searchQuery.toLowerCase())) {
                return false;
              }
            }
        }
      }
      
      return true;
    }).toList();
  }
}

/// Extension methods for sorting pantry item lists
extension PantryItemSorting on List<PantryItemEntry> {
  /// Sort pantry items based on the specified option and direction
  List<PantryItemEntry> applySorting(PantrySortOption option, SortDirection direction) {
    final sortedList = List<PantryItemEntry>.from(this);
    
    switch (option) {
      case PantrySortOption.category:
        // Group by category, sort categories, then sort items within each category
        sortedList.sort((a, b) {
          final aCategory = a.category ?? 'Other';
          final bCategory = b.category ?? 'Other';
          
          // Sort by category first (put "Other" last)
          int categoryComparison;
          if (aCategory == 'Other' && bCategory != 'Other') {
            categoryComparison = 1;
          } else if (bCategory == 'Other' && aCategory != 'Other') {
            categoryComparison = -1;
          } else {
            categoryComparison = aCategory.compareTo(bCategory);
          }
          
          if (categoryComparison != 0) return categoryComparison;
          
          // If same category, sort alphabetically by name
          return a.name.compareTo(b.name);
        });
        
      case PantrySortOption.alphabetical:
        sortedList.sort((a, b) => a.name.compareTo(b.name));
        
      case PantrySortOption.dateAdded:
        sortedList.sort((a, b) {
          // Handle null created dates (null values go last)
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          
          // Sort by created date (most recent first by default)
          return b.createdAt!.compareTo(a.createdAt!);
        });
        
      case PantrySortOption.dateModified:
        sortedList.sort((a, b) {
          // Handle null updated dates (null values go last)
          if (a.updatedAt == null && b.updatedAt == null) return 0;
          if (a.updatedAt == null) return 1;
          if (b.updatedAt == null) return -1;
          
          // Sort by updated date (most recent first by default)
          return b.updatedAt!.compareTo(a.updatedAt!);
        });
        
      case PantrySortOption.stockStatus:
        sortedList.sort((a, b) {
          // Sort by stock status (outOfStock -> lowStock -> inStock)
          final statusComparison = a.stockStatus.index.compareTo(b.stockStatus.index);
          if (statusComparison != 0) return statusComparison;
          
          // If same status, sort alphabetically by name
          return a.name.compareTo(b.name);
        });
    }
    
    // Apply direction (only reverse for non-default cases)
    if ((option == PantrySortOption.alphabetical && direction == SortDirection.descending) ||
        (option == PantrySortOption.stockStatus && direction == SortDirection.descending) ||
        ((option == PantrySortOption.dateAdded || option == PantrySortOption.dateModified) && 
         direction == SortDirection.ascending)) {
      return sortedList.reversed.toList();
    }
    
    return sortedList;
  }
}