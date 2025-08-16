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
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/recipe_filter_sort.dart';
import '../utils/filter_utils.dart';
import '../widgets/filter_sort/unified_sort_filter_sheet.dart';
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
        // Unified Sort/Filter header
        SliverPersistentHeader(
          pinned: false,
          floating: false,
          delegate: _UnifiedHeaderDelegate(
            filterSortState: filterSortState,
            folderId: folderId,
            onStateChanged: (newState) {
              final notifier = ref.read(recipeFolderFilterSortProvider.notifier);

              // Clear all existing filters first
              notifier.clearFilters();

              // Update sort
              notifier.updateSortOption(newState.activeSortOption);
              notifier.updateSortDirection(newState.sortDirection);

              // Add all filters from new state
              for (final entry in newState.activeFilters.entries) {
                notifier.updateFilter(entry.key, entry.value);
              }
            },
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
        child: const AppCircleButton(
          icon: AppCircleButtonIcon.plus,
        ),
      ),
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: true,
    );
  }
}

/// Delegate for the unified sort/filter header
class _UnifiedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final RecipeFilterSortState filterSortState;
  final String? folderId;
  final Function(RecipeFilterSortState) onStateChanged;

  _UnifiedHeaderDelegate({
    required this.filterSortState,
    required this.folderId,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 1.0 : 0.0,
      color: Colors.white.withValues(alpha: 0.95),
      child: Container(
        height: minExtent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        constraints: const BoxConstraints(maxWidth: 800), // Max width for wider screens
        child: Row(
          children: [
            // Unified Sort/Filter button (takes available space)
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AppButton(
                    text: 'Sort by ${filterSortState.activeSortOption.label}',
                    leadingIcon: const Icon(Icons.filter_list), // Filter funnel icon
                    trailingIcon: Icon(
                      filterSortState.sortDirection == SortDirection.ascending
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                    trailingIconOffset: const Offset(0, -1.0), // Slight upward nudge for small size
                    style: AppButtonStyle.mutedOutline,
                    shape: AppButtonShape.square,
                    size: AppButtonSize.small,
                    theme: AppButtonTheme.primary,
                    fullWidth: true,
                    onPressed: () {
                      showUnifiedSortFilterSheet(
                        context,
                        initialState: filterSortState,
                        onStateChanged: onStateChanged,
                        showPantryMatchOption: false,
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
            ),

            const SizedBox(width: 12),

            // Add Recipe button (fixed width)
            AppButton(
              text: 'Add Recipe',
              leadingIcon: const Icon(Icons.add),
              style: AppButtonStyle.outline,
              shape: AppButtonShape.square,
              size: AppButtonSize.small,
              theme: AppButtonTheme.secondary,
              onPressed: () {
                final saveFolderId = folderId == kUncategorizedFolderId ? null : folderId;
                showRecipeEditorModal(context, folderId: saveFolderId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _UnifiedHeaderDelegate oldDelegate) {
    return oldDelegate.filterSortState != filterSortState ||
           oldDelegate.folderId != folderId;
  }

  @override
  TickerProvider? get vsync => null;
}
