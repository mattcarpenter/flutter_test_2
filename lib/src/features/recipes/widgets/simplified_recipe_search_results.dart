import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../providers/recipe_provider.dart';
import '../../../providers/unified_filter_sort_provider.dart';
import '../models/recipe_filter_sort.dart';
import '../utils/simplified_filter_utils.dart';
import 'filter_sort/recipe_filter_sheet.dart';
import 'filter_sort/recipe_sort_dropdown.dart';

/// A simplified version of RecipeSearchResults that uses the unified filter system
class SimplifiedRecipeSearchResults extends ConsumerWidget {
  final String? folderId;
  final void Function(RecipeEntry)? onResultSelected;
  final void Function(UnifiedFilterSortState)? onFilterSortStateChanged;

  const SimplifiedRecipeSearchResults({
    super.key, 
    this.folderId, 
    this.onResultSelected,
    this.onFilterSortStateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get the data we need from providers - more direct, less indirection
    final searchState = ref.watch(recipeSearchNotifierProvider);
    final filterSortState = ref.watch(recipeSearchFilterSort);
    final pantryMatchesAsyncValue = ref.watch(pantryRecipeMatchProvider);
    
    // 2. Simplified listener for filter changes to load pantry data
    ref.listen(recipeSearchFilterSort, (previous, current) {
      // Directly call the simplified method
      SimplifiedFilterUtils.loadPantryMatchesIfNeeded(
        filterState: current,
        ref: ref,
      );
    });
    
    // 3. Make sure folder ID is updated
    if (filterSortState.folderId != folderId) {
      // Use addPostFrameCallback to avoid triggering a rebuild during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(recipeSearchFilterSortProvider.notifier).updateFolderId(folderId);
      });
    }

    // 4. Show error if there is one
    if (searchState.error != null) {
      return Center(child: Text('Error: ${searchState.error}'));
    }
    
    // 5. Show loading if pantry match filter is active and we're still loading matches
    if (SimplifiedFilterUtils.isPantryMatchLoading(
        filterState: filterSortState,
        pantryMatchesAsyncValue: pantryMatchesAsyncValue)) {
      return const Center(child: CircularProgressIndicator());
    }

    // 6. Get search results and apply filtering/sorting in a more direct way
    List<RecipeEntry> results = searchState.results;

    // Apply folder filtering
    results = SimplifiedFilterUtils.applyFolderFilter(
      results, 
      folderId, 
      kUncategorizedFolderId,
    );
    
    // Apply all filters in one pass
    if (filterSortState.hasFilters) {
      results = SimplifiedFilterUtils.applyFilters(
        recipes: results,
        filterState: filterSortState,
        pantryMatchesAsyncValue: pantryMatchesAsyncValue,
      );
    }
    
    // Apply sorting based on context
    if (filterSortState.activeSortOption == SortOption.pantryMatch) {
      results = SimplifiedFilterUtils.applyPantryMatchSorting(
        recipes: results,
        pantryMatchesAsyncValue: pantryMatchesAsyncValue,
        sortDirection: filterSortState.sortDirection,
      );
    } else {
      results = SimplifiedFilterUtils.applySorting(
        recipes: results,
        filterState: filterSortState,
      );
    }
    
    // 7. Show loading if still loading and no results
    if (results.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 8. Show empty state with clear filters option
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No recipes match your search.'),
            if (filterSortState.hasFilters)
              TextButton(
                onPressed: () {
                  ref.read(recipeSearchFilterSortProvider.notifier).clearFilters();
                  if (onFilterSortStateChanged != null) {
                    onFilterSortStateChanged!(
                      UnifiedFilterSortState(
                        activeFilters: {},
                        activeSortOption: SortOption.alphabetical,
                        sortDirection: SortDirection.ascending,
                        context: FilterContext.recipeSearch
                      )
                    );
                  }
                },
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      );
    }

    // 9. Show results with filter controls
    return Column(
      children: [
        // Filter and sort controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter button with counter badge
              GestureDetector(
                onTap: () {
                  // Show filter sheet with current state
                  showRecipeFilterSheet(
                    context,
                    initialState: filterSortState,
                    onFilterChanged: (newState) {
                      final notifier = ref.read(recipeSearchFilterSortProvider.notifier);
                      
                      // Clear existing filters first
                      notifier.clearFilters();
                      
                      // Add new filters
                      for (final entry in newState.activeFilters.entries) {
                        notifier.updateFilter(entry.key, entry.value);
                      }
                      
                      if (onFilterSortStateChanged != null) {
                        // Convert to UnifiedFilterSortState
                        final unifiedState = UnifiedFilterSortState(
                          activeFilters: newState.activeFilters,
                          activeSortOption: newState.activeSortOption,
                          sortDirection: newState.sortDirection,
                          folderId: newState.folderId,
                          searchQuery: newState.searchQuery,
                          context: FilterContext.recipeSearch,
                        );
                        onFilterSortStateChanged!(unifiedState);
                      }
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list),
                      if (filterSortState.hasFilters)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            filterSortState.filterCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Sort dropdown
              RecipeSortDropdown(
                sortOption: filterSortState.activeSortOption,
                sortDirection: filterSortState.sortDirection,
                onSortOptionChanged: (option) {
                  ref.read(recipeSearchFilterSortProvider.notifier).updateSortOption(option);
                },
                onSortDirectionChanged: (direction) {
                  ref.read(recipeSearchFilterSortProvider.notifier).updateSortDirection(direction);
                },
                showPantryMatchOption: false,
              ),
            ],
          ),
        ),
        
        // Results count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${results.length} results',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final recipe = results[index];
              return ListTile(
                title: Text(recipe.title),
                subtitle: Text(recipe.description ?? ''),
                onTap: () {
                  if (onResultSelected != null) {
                    onResultSelected!(recipe);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}