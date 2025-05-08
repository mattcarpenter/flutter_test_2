import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../providers/recipe_filter_sort_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../models/recipe_filter_sort.dart';
import 'filter_sort/recipe_filter_sheet.dart';
import 'filter_sort/recipe_sort_dropdown.dart';

class RecipeSearchResults extends ConsumerWidget {
  final String? folderId;
  final void Function(RecipeEntry)? onResultSelected;
  final void Function(RecipeFilterSortState)? onFilterSortStateChanged;

  const RecipeSearchResults({
    super.key, 
    this.folderId, 
    this.onResultSelected,
    this.onFilterSortStateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(recipeSearchNotifierProvider);
    final filterSortState = ref.watch(recipeSearchFilterSortProvider);
    
    // Update folder ID in filter/sort state if needed
    if (filterSortState.folderId != folderId) {
      // Use addPostFrameCallback to avoid triggering a rebuild during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(recipeSearchFilterSortProvider.notifier).updateFolderId(folderId);
      });
    }

    if (searchState.error != null) {
      return Center(child: Text('Error: ${searchState.error}'));
    }

    // Apply initial folder filtering
    List<RecipeEntry> results = searchState.results;

    if (folderId != null) {
      if (folderId == kUncategorizedFolderId) {
        results = results.where((r) => r.folderIds?.isEmpty ?? true).toList();
      } else {
        results = results.where((r) => r.folderIds?.contains(folderId) ?? false).toList();
      }
    }
    
    // Apply additional filters from filter state
    results = results.applyFilters(filterSortState.activeFilters);
    
    // Apply sorting
    results = results.applySorting(
      filterSortState.activeSortOption,
      filterSortState.sortDirection,
    );
    
    if (results.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    onFilterSortStateChanged!(RecipeFilterSortState());
                  }
                },
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      );
    }

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
                  showRecipeFilterSheet(
                    context,
                    initialState: filterSortState,
                    onFilterChanged: (newState) {
                      // Use the updated active filters
                      for (final entry in filterSortState.activeFilters.entries) {
                        if (!newState.activeFilters.containsKey(entry.key)) {
                          ref.read(recipeSearchFilterSortProvider.notifier)
                            .updateFilter(entry.key, null);
                        }
                      }
                      
                      for (final entry in newState.activeFilters.entries) {
                        ref.read(recipeSearchFilterSortProvider.notifier)
                          .updateFilter(entry.key, entry.value);
                      }
                      
                      if (onFilterSortStateChanged != null) {
                        onFilterSortStateChanged!(newState);
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