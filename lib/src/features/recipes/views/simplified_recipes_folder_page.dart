import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_provider.dart';
import '../../../providers/unified_filter_sort_provider.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../models/recipe_filter_sort.dart';
import '../utils/simplified_filter_utils.dart';
import '../widgets/filter_sort/recipe_filter_sheet.dart';
import '../widgets/filter_sort/recipe_sort_dropdown.dart';
import '../widgets/recipe_list.dart';
import '../widgets/simplified_recipe_search_results.dart';
import 'add_recipe_modal.dart';

class SimplifiedRecipesFolderPage extends ConsumerWidget {
  final String? folderId;
  final String title;
  final String previousPageTitle;

  const SimplifiedRecipesFolderPage({
    super.key,
    this.folderId,
    required this.title,
    required this.previousPageTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simplified approach - get data directly from providers
    final recipesAsyncValue = ref.watch(recipeNotifierProvider);
    final pantryMatchesAsyncValue = ref.watch(pantryRecipeMatchProvider);
    final filterSortState = ref.watch(recipeFolderFilterSort);

    // Simplified pantry match loading logic
    ref.listen(recipeFolderFilterSort, (previous, current) {
      SimplifiedFilterUtils.loadPantryMatchesIfNeeded(
        filterState: current,
        ref: ref,
      );
    });

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
      searchResultsBuilder: (context, query) => SimplifiedRecipeSearchResults(
        folderId: folderId,
        onFilterSortStateChanged: (state) {
          // This only updates search-specific filtering
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.activeFilters.isNotEmpty) {
              // Get the first filter
              final firstFilterKey = state.activeFilters.keys.first;
              final firstFilterValue = state.activeFilters.values.first;
              ref.read(recipeSearchFilterSortProvider.notifier).updateFilter(firstFilterKey, firstFilterValue);
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
        // Sort dropdown in a SliverPersistentHeader
        SliverPersistentHeader(
          pinned: false,
          floating: true,
          delegate: _SimplifiedSortHeaderDelegate(
            filterState: filterSortState,
            updateFilterHandler: (newState) {
              final notifier = ref.read(recipeFolderFilterSortProvider.notifier);
              
              // Clear existing filters first
              notifier.clearFilters();
              
              // Add new filters
              for (final entry in newState.activeFilters.entries) {
                notifier.updateFilter(entry.key, entry.value);
              }
            },
            updateSortOptionHandler: (option) {
              ref.read(recipeFolderFilterSortProvider.notifier).updateSortOption(option);
            },
            updateSortDirectionHandler: (direction) {
              ref.read(recipeFolderFilterSortProvider.notifier).updateSortDirection(direction);
            },
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
            if (SimplifiedFilterUtils.isPantryMatchLoading(
                filterState: filterSortState,
                pantryMatchesAsyncValue: pantryMatchesAsyncValue)) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Extract recipes from wrapper objects and apply filtering in a single clear flow
            final recipes = recipesWithFolders.map((r) => r.recipe).toList();

            // Apply folder filtering
            var filteredRecipes = SimplifiedFilterUtils.applyFolderFilter(
              recipes,
              folderId,
              kUncategorizedFolderId,
            );

            // Apply all other filters
            if (filterSortState.hasFilters) {
              filteredRecipes = SimplifiedFilterUtils.applyFilters(
                recipes: filteredRecipes,
                filterState: filterSortState,
                pantryMatchesAsyncValue: pantryMatchesAsyncValue,
              );
            }

            // Apply sorting
            if (filterSortState.activeSortOption == SortOption.pantryMatch) {
              filteredRecipes = SimplifiedFilterUtils.applyPantryMatchSorting(
                recipes: filteredRecipes,
                pantryMatchesAsyncValue: pantryMatchesAsyncValue,
                sortDirection: filterSortState.sortDirection,
              );
            } else {
              filteredRecipes = SimplifiedFilterUtils.applySorting(
                recipes: filteredRecipes,
                filterState: filterSortState,
              );
            }

            // Show empty state if no recipes
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

/// Simplified delegate for the sort dropdown in a sliver persistent header
class _SimplifiedSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final UnifiedFilterSortState filterState;
  final Function(UnifiedFilterSortState) updateFilterHandler;
  final Function(SortOption) updateSortOptionHandler;
  final Function(SortDirection) updateSortDirectionHandler;
  final bool showPantryMatchOption;

  _SimplifiedSortHeaderDelegate({
    required this.filterState,
    required this.updateFilterHandler,
    required this.updateSortOptionHandler,
    required this.updateSortDirectionHandler,
    this.showPantryMatchOption = false,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Use Material widget to get elevation/shadow
    return Material(
      elevation: overlapsContent ? 1.0 : 0.0, // Apply elevation only when content scrolls under
      color: Colors.white.withOpacity(0.95), // TODO: Update to .withValues() in future
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
                  showRecipeFilterSheet(
                    context,
                    initialState: filterState,
                    onFilterChanged: (newState) {
                      // Convert standard RecipeFilterSortState to UnifiedFilterSortState
                      final unifiedState = UnifiedFilterSortState(
                        activeFilters: newState.activeFilters,
                        activeSortOption: newState.activeSortOption,
                        sortDirection: newState.sortDirection,
                        folderId: newState.folderId,
                        searchQuery: newState.searchQuery,
                        context: FilterContext.recipeFolder,
                      );
                      updateFilterHandler(unifiedState);
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

            // Sort dropdown with direct handlers
            RecipeSortDropdown(
              sortOption: filterState.activeSortOption,
              sortDirection: filterState.sortDirection,
              onSortOptionChanged: updateSortOptionHandler,
              onSortDirectionChanged: updateSortDirectionHandler,
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
  bool shouldRebuild(covariant _SimplifiedSortHeaderDelegate oldDelegate) {
    return oldDelegate.filterState.activeSortOption != filterState.activeSortOption ||
           oldDelegate.filterState.sortDirection != filterState.sortDirection ||
           oldDelegate.showPantryMatchOption != showPantryMatchOption ||
           oldDelegate.filterState.filterCount != filterState.filterCount ||
           oldDelegate.filterState.hasFilters != filterState.hasFilters;
  }

  @override
  TickerProvider? get vsync => null; // No animation needed
}