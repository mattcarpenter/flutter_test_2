import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_filter_sort_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../models/recipe_filter_sort.dart';
import '../utils/filter_utils.dart';
import '../widgets/filter_sort/recipe_filter_sheet.dart';
import '../widgets/filter_sort/recipe_sort_dropdown.dart';
import '../widgets/recipe_list.dart';
import '../widgets/recipe_search_results.dart';
import 'add_recipe_modal.dart';

class RecipesFolderPage extends ConsumerWidget {
  final String? folderId;
  final String title;
  final String previousPageTitle;

  const RecipesFolderPage({
    super.key,
    this.folderId,
    required this.title,
    required this.previousPageTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all recipes
    final recipesAsyncValue = ref.watch(recipeNotifierProvider);

    // Watch pantry recipe matches if needed for filtering
    final pantryMatchesAsyncValue = ref.watch(pantryRecipeMatchProvider);

    // Listen to filter changes for debugging and to load necessary data
    ref.listen(recipeFolderFilterSortProvider, (previous, current) {
      print('Filter state changed:');
      print('Previous: ${previous?.activeFilters}');
      print('Current: ${current.activeFilters}');

      // Initiate pantry match loading if needed
      FilterUtils.loadPantryMatchesIfNeeded(
        filterState: current,
        ref: ref,
      );
    });

    // Watch filter/sort state
    final filterSortState = ref.watch(recipeFolderFilterSort);

    // Update folder ID in filter/sort state if needed
    if (filterSortState.folderId != folderId) {
      // Use addPostFrameCallback to avoid triggering a rebuild during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(recipeFolderFilterSortProvider.notifier).updateFolderId(folderId);
      });
    }

    return AdaptiveSliverPage(
      title: title,
      searchEnabled: true,
      searchResultsBuilder: (context, query) => RecipeSearchResults(
        folderId: folderId,
        onFilterSortStateChanged: (state) {
          // This only updates search-specific filtering
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.activeFilters.isNotEmpty) {
              ref.read(recipeSearchFilterSortProvider.notifier).updateFilter(
                state.activeFilters.keys.first,
                state.activeFilters.values.first
              );
            } else {
              // If filters are cleared, clear them in the provider too
              ref.read(recipeSearchFilterSortProvider.notifier).clearFilters();
            }
          });
        },
      ),
      onSearchChanged: (query) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(recipeSearchNotifierProvider.notifier).search(query);
          ref.read(recipeSearchFilterSortProvider.notifier).updateSearchQuery(query);
        });
      },
      slivers: [
        // Sort dropdown in a SliverPersistentHeader - make sure it's pinned
        SliverPersistentHeader(
          pinned: false, // Essential to keep it visible when scrolling
          floating: true, // Setting to false to ensure pinned behavior takes precedence
          delegate: _SortHeaderDelegate(
            sortOption: filterSortState.activeSortOption,
            sortDirection: filterSortState.sortDirection,
            filterState: filterSortState, // Pass the filter state
            onSortOptionChanged: (option) {
              ref.read(recipeFolderFilterSortProvider.notifier).updateSortOption(option);
            },
            onSortDirectionChanged: (direction) {
              ref.read(recipeFolderFilterSortProvider.notifier).updateSortDirection(direction);
            },
            // Only show pantry match sort option in pantry context
            showPantryMatchOption: false,
          ),
        ),

        // Recipe list with filtering and sorting applied
        recipesAsyncValue.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (recipesWithFolders) {
            // Show loading indicator if pantry match filter is active and we're still loading matches
            if (FilterUtils.isPantryMatchLoading(
                filterState: filterSortState,
                pantryMatchesAsyncValue: pantryMatchesAsyncValue)) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Extract recipes from wrapper objects
            final recipes = recipesWithFolders.map((r) => r.recipe).toList();

            // Apply filters and sorting
            List<RecipeEntry> filteredRecipes;

            // Apply folder filtering
            filteredRecipes = FilterUtils.applyFolderFilter(
              recipes,
              folderId,
              kUncategorizedFolderId,
            );

            // Apply all other filters
            if (filterSortState.hasFilters) {
              print('Applying filters to ${filteredRecipes.length} recipes: ${filterSortState.activeFilters}');

              filteredRecipes = FilterUtils.applyFilters(
                recipes: filteredRecipes,
                filterState: filterSortState,
                pantryMatchesAsyncValue: pantryMatchesAsyncValue,
              );

              print('After filtering: ${filteredRecipes.length} recipes remaining');
            }

            // Apply sorting
            if (filterSortState.activeSortOption == SortOption.pantryMatch) {
              filteredRecipes = FilterUtils.applyPantryMatchSorting(
                recipes: filteredRecipes,
                pantryMatchesAsyncValue: pantryMatchesAsyncValue,
                sortDirection: filterSortState.sortDirection,
              );
            } else {
              filteredRecipes = FilterUtils.applySorting(
                recipes: filteredRecipes,
                filterState: filterSortState,
              );
            }

            if (filteredRecipes.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No recipes match the current filters'),
                      if (filterSortState.hasFilters)
                        TextButton(
                          onPressed: () {
                            ref.read(recipeFolderFilterSortProvider.notifier).clearFilters();
                          },
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                ),
              );
            }

            return RecipesList(recipes: filteredRecipes, currentPageTitle: title);
          },
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Add Recipe',
            icon: const Icon(CupertinoIcons.book),
            onTap: () {
              // Don't pass folderId for uncategorized folder
              final saveFolderId = folderId == kUncategorizedFolderId ? null : folderId;
              showRecipeEditorModal(context, folderId: saveFolderId);
            },
          )
        ],
        child: const Icon(CupertinoIcons.add_circled),
      ),
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: true,
    );
  }
}

/// Delegate for the sort dropdown in a sliver persistent header
class _SortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final SortOption sortOption;
  final SortDirection sortDirection;
  final Function(SortOption) onSortOptionChanged;
  final Function(SortDirection) onSortDirectionChanged;
  final bool showPantryMatchOption;
  final RecipeFilterSortState filterState; // Store the filter state

  _SortHeaderDelegate({
    required this.sortOption,
    required this.sortDirection,
    required this.onSortOptionChanged,
    required this.onSortDirectionChanged,
    required this.filterState, // Add to constructor
    this.showPantryMatchOption = false,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Use the filter state passed through the constructor

    // Use Material widget to get elevation/shadow
    return Material(
      elevation: overlapsContent ? 1.0 : 0.0, // Apply elevation only when content scrolls under
      color: Colors.white.withOpacity(0.95),
      child: Container(
        height: minExtent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical alignment
          children: [
          // Filter button with counter badge
          Material(
            // Use Material for proper ink effects
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                // Use the current filter state
                print('Current filter state: ${filterState.activeFilters}');

                showRecipeFilterSheet(
                  context,
                  initialState: filterState,
                  onFilterChanged: (newState) {
                    // Use a more direct approach to update filters
                    print('Filter sheet returned state: ${newState.activeFilters}');

                    final container = ProviderScope.containerOf(context);
                    final notifier = container.read(recipeFolderFilterSortProvider.notifier);

                    // Clear all existing filters first
                    notifier.clearFilters();

                    // Add all filters from new state
                    for (final entry in newState.activeFilters.entries) {
                      print('Adding filter: ${entry.key} = ${entry.value}');
                      notifier.updateFilter(entry.key, entry.value);
                    }
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical alignment
                  children: [
                    const Icon(Icons.filter_list),
                    if (filterState.hasFilters)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          filterState.filterCount.toString(),
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
          ),

          // Sort dropdown
          RecipeSortDropdown(
            sortOption: sortOption,
            sortDirection: sortDirection,
            onSortOptionChanged: onSortOptionChanged,
            onSortDirectionChanged: onSortDirectionChanged,
            showPantryMatchOption: showPantryMatchOption,
          ),
        ],
      ),
      ),
    );
  }

  @override
  double get maxExtent => 48.0; // Slightly taller for better touch targets

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _SortHeaderDelegate oldDelegate) {
    return oldDelegate.sortOption != sortOption ||
           oldDelegate.sortDirection != sortDirection ||
           oldDelegate.showPantryMatchOption != showPantryMatchOption ||
           oldDelegate.filterState.filterCount != filterState.filterCount ||
           oldDelegate.filterState.hasFilters != filterState.hasFilters;
  }

  @override
  TickerProvider? get vsync => null; // No animation needed
}
