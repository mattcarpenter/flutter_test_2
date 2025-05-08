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
    
    // Listen to filter changes for debugging
    ref.listen(recipeFolderFilterSortProvider, (previous, current) {
      print('Filter state changed:');
      print('Previous: ${previous?.activeFilters}');
      print('Current: ${current.activeFilters}');
      
      // Initiate pantry match loading if needed
      if (current.activeFilters.containsKey(FilterType.pantryMatch) && 
          pantryMatchesAsyncValue.value?.matches.isEmpty != false) {
        print('Pantry match filter active - loading pantry matches');
        ref.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();
      }
    });
    
    // Watch filter/sort state
    final filterSortState = ref.watch(recipeFolderFilterSortProvider);
    
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
            ref.read(recipeSearchFilterSortProvider.notifier).updateFilter(
              state.activeFilters.keys.first, 
              state.activeFilters.values.first
            );
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
          pinned: true,
          delegate: _SortHeaderDelegate(
            sortOption: filterSortState.activeSortOption,
            sortDirection: filterSortState.sortDirection,
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
            if (filterSortState.activeFilters.containsKey(FilterType.pantryMatch) && 
                pantryMatchesAsyncValue.isLoading) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()), 
              );
            }
            final recipes = recipesWithFolders.map((r) => r.recipe).toList();

            // Filter recipes based on folder ID first
            List<RecipeEntry> filteredRecipes;

            if (folderId == kUncategorizedFolderId) {
              // Show recipes with no folder assignments
              filteredRecipes = recipes.where((recipe) {
                return recipe.folderIds == null || recipe.folderIds!.isEmpty;
              }).toList();
            } else if (folderId == null) {
              // Show all recipes
              filteredRecipes = recipes;
            } else {
              // Show recipes in the specified folder
              filteredRecipes = recipes
                  .where((recipe) => recipe.folderIds?.contains(folderId) ?? false)
                  .toList();
            }
            
            // Apply additional filters from filter state
            if (filterSortState.hasFilters) {
              print('Applying filters to ${filteredRecipes.length} recipes: ${filterSortState.activeFilters}');
              
              // Handle pantry match filter separately if present
              final hasPantryMatchFilter = filterSortState.activeFilters.containsKey(FilterType.pantryMatch);
              
              if (hasPantryMatchFilter) {
                final pantryFilter = filterSortState.activeFilters[FilterType.pantryMatch] as PantryMatchFilter;
                print('Applying pantry match filter: $pantryFilter');
                
                // For "Any match" option, we'll treat it as no filter
                if (pantryFilter == PantryMatchFilter.anyMatch) {
                  print('Ignoring "Any match" filter as it should show all recipes');
                  // No filtering needed - keep all recipes
                }
                // Check if we have loaded the pantry match data (even if it's empty)
                else if (pantryMatchesAsyncValue.value != null) {
                  // Create a map of recipe IDs to their match percentage
                  final Map<String, int> recipeMatchPercentages = {};
                  for (final match in pantryMatchesAsyncValue.value!.matches) {
                    recipeMatchPercentages[match.recipe.id] = match.matchPercentage;
                  }
                  
                  print('Applying pantry match filter - found ${recipeMatchPercentages.length} recipes with match data');
                  
                  // Filter recipes based on pantry match percentage
                  filteredRecipes = filteredRecipes.where((recipe) {
                    // If recipe isn't in the match data, its match percentage is 0
                    final matchPercentage = recipeMatchPercentages[recipe.id] ?? 0;
                    
                    // Apply the appropriate filter
                    switch (pantryFilter) {
                      case PantryMatchFilter.anyMatch:
                        // This case is handled above - should never reach here
                        return true;
                      case PantryMatchFilter.goodMatch:
                        return matchPercentage > 50;
                      case PantryMatchFilter.greatMatch:
                        return matchPercentage > 75;
                      case PantryMatchFilter.perfectMatch:
                        return matchPercentage == 100;
                    }
                  }).toList();
                } else {
                  print('Pantry match data not loaded yet - showing loading indicator instead');
                }
                
                // Remove pantry filter before applying other filters
                final otherFilters = Map<FilterType, dynamic>.from(filterSortState.activeFilters);
                otherFilters.remove(FilterType.pantryMatch);
                
                // Apply other filters
                if (otherFilters.isNotEmpty) {
                  filteredRecipes = filteredRecipes.applyFilters(otherFilters);
                }
              } else {
                // No pantry filter, just apply regular filters
                filteredRecipes = filteredRecipes.applyFilters(filterSortState.activeFilters);
              }
              
              print('After filtering: ${filteredRecipes.length} recipes remaining');
            }
            
            // Apply sorting
            filteredRecipes = filteredRecipes.applySorting(
              filterSortState.activeSortOption,
              filterSortState.sortDirection,
            );

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
  
  _SortHeaderDelegate({
    required this.sortOption,
    required this.sortDirection,
    required this.onSortOptionChanged,
    required this.onSortDirectionChanged,
    this.showPantryMatchOption = false,
  });
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Get the filter state to show the badge
    final filterSortState = ProviderScope.containerOf(context).read(recipeFolderFilterSortProvider);
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: minExtent,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filter button with counter badge
          GestureDetector(
            onTap: () {
              // Get the latest filter state directly from the provider
              final latestFilterState = ProviderScope.containerOf(context)
                  .read(recipeFolderFilterSortProvider);
              print('Latest filter state: ${latestFilterState.activeFilters}');
                  
              showRecipeFilterSheet(
                context,
                initialState: latestFilterState,
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
            sortOption: sortOption,
            sortDirection: sortDirection,
            onSortOptionChanged: onSortOptionChanged,
            onSortDirectionChanged: onSortDirectionChanged,
            showPantryMatchOption: showPantryMatchOption,
          ),
        ],
      ),
    );
  }
  
  @override
  double get maxExtent => 44.0;
  
  @override
  double get minExtent => 44.0;
  
  @override
  bool shouldRebuild(covariant _SortHeaderDelegate oldDelegate) {
    return oldDelegate.sortOption != sortOption ||
           oldDelegate.sortDirection != sortDirection ||
           oldDelegate.showPantryMatchOption != showPantryMatchOption;
  }
}