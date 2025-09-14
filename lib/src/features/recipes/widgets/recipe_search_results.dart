import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../providers/recipe_filter_sort_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../models/recipe_filter_sort.dart';
import '../utils/filter_utils.dart';
import 'filter_sort/unified_sort_filter_sheet.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/recipe_list_item.dart';
import '../../../theme/spacing.dart';

class RecipeSearchResults extends ConsumerWidget {
  final String? folderId;
  final void Function(RecipeEntry)? onResultSelected;
  final void Function(UnifiedFilterSortState)? onFilterSortStateChanged;

  const RecipeSearchResults({
    super.key,
    this.folderId,
    this.onResultSelected,
    this.onFilterSortStateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(recipeSearchNotifierProvider);
    final filterSortState = ref.watch(recipeSearchFilterSort);
    final pantryMatchesAsyncValue = ref.watch(pantryRecipeMatchProvider);

    // Listen to filter changes to load necessary data
    ref.listen(recipeSearchFilterSort, (previous, current) {
      // Initiate pantry match loading if needed
      FilterUtils.loadPantryMatchesIfNeeded(
        filterState: current,
        ref: ref,
      );
    });

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

    // Show loading if pantry match filter is active and we're still loading matches
    if (FilterUtils.isPantryMatchLoading(
        filterState: filterSortState,
        pantryMatchesAsyncValue: pantryMatchesAsyncValue)) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get search results
    List<RecipeEntry> results = searchState.results;

    // Apply folder filtering
    results = FilterUtils.applyFolderFilter(
      results,
      folderId,
      kUncategorizedFolderId,
    );

    // Apply additional filters
    if (filterSortState.hasFilters) {
      results = FilterUtils.applyFilters(
        recipes: results,
        filterState: filterSortState,
        pantryMatchesAsyncValue: pantryMatchesAsyncValue,
      );
    }

    // Apply sorting
    if (filterSortState.activeSortOption == SortOption.pantryMatch) {
      results = FilterUtils.applyPantryMatchSorting(
        recipes: results,
        pantryMatchesAsyncValue: pantryMatchesAsyncValue,
        sortDirection: filterSortState.sortDirection,
      );
    } else {
      results = FilterUtils.applySorting(
        recipes: results,
        filterState: filterSortState,
      );
    }

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
                    onFilterSortStateChanged!(UnifiedFilterSortState(
                      context: FilterContext.recipeSearch
                    ));
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Unified filter and sort button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppButton(
                    text: 'Filter and Sort',
                    leadingIcon: const Icon(Icons.tune),
                    style: AppButtonStyle.mutedOutline,
                    shape: AppButtonShape.square,
                    size: AppButtonSize.medium,
                    theme: AppButtonTheme.primary,
                    onPressed: () {
                      showUnifiedSortFilterSheet(
                        context,
                        initialState: filterSortState,
                        showPantryMatchOption: true,
                        onStateChanged: (newState) {
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

                          // Update sort options
                          ref.read(recipeSearchFilterSortProvider.notifier)
                            .updateSortOption(newState.activeSortOption);
                          ref.read(recipeSearchFilterSortProvider.notifier)
                            .updateSortDirection(newState.sortDirection);

                          if (onFilterSortStateChanged != null) {
                            // Convert RecipeFilterSortState to UnifiedFilterSortState
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
                  ),
                  // Active filters indicator
                  if (filterSortState.hasFilters)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
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

        // Results list with responsive layout
        Expanded(
          child: _buildResponsiveGrid(context, results, onResultSelected),
        ),
      ],
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, List<RecipeEntry> recipes, void Function(RecipeEntry)? onResultSelected) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive layout: 1 column mobile, 2 columns wider screens
    final crossAxisCount = screenWidth < 600 ? 1 : 2;

    if (crossAxisCount == 1) {
      // Single column - use simple list
      return ListView.builder(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return RecipeListItem(
            recipe: recipe,
            onTap: () {
              if (onResultSelected != null) {
                onResultSelected(recipe);
              }
            },
          );
        },
      );
    } else {
      // Two column grid
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 4.0, // Wide aspect ratio for recipe list items
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return RecipeListItem(
            recipe: recipe,
            onTap: () {
              if (onResultSelected != null) {
                onResultSelected(recipe);
              }
            },
          );
        },
      ),
      );
    }
  }
}
