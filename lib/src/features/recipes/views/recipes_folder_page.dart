import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_filter_sort_provider.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../../../providers/recipe_provider.dart';
import '../../../providers/smart_folder_provider.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/recipe_filter_sort.dart';
import '../utils/filter_utils.dart';
import '../widgets/filter_sort/unified_sort_filter_sheet.dart';
import '../widgets/recipe_list.dart';
import '../widgets/recipe_search_results.dart';
import '../widgets/smart_folder_search_results.dart';
import 'add_recipe_modal.dart';
import 'ai_recipe_generator_modal.dart';
import 'edit_smart_folder_modal.dart';
import 'photo_capture_review_modal.dart';
import 'photo_import_modal.dart';
import 'url_import_modal.dart';

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

  /// Build menu items for adding recipes
  List<AdaptiveMenuItem> _buildAddRecipeMenuItems(BuildContext context, WidgetRef ref) {
    final saveFolderId = folderId == kUncategorizedFolderId ? null : folderId;
    return [
      AdaptiveMenuItem(
        title: 'New Recipe',
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedBook01),
        onTap: () {
          showRecipeEditorModal(context, ref: ref, folderId: saveFolderId);
        },
      ),
      AdaptiveMenuItem(
        title: 'Generate with AI',
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedMagicWand01),
        onTap: () {
          showAiRecipeGeneratorModal(context, ref: ref, folderId: saveFolderId);
        },
      ),
      AdaptiveMenuItem(
        title: 'Import from Camera',
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01),
        onTap: () {
          showPhotoCaptureReviewModal(context, ref: ref, folderId: saveFolderId);
        },
      ),
      AdaptiveMenuItem(
        title: 'Import from Photos',
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedImage01),
        onTap: () {
          showPhotoImportModal(context, ref: ref, source: ImageSource.gallery, folderId: saveFolderId);
        },
      ),
      AdaptiveMenuItem(
        title: 'Import from URL',
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedLink01),
        onTap: () {
          showUrlImportModal(context, ref: ref, folderId: saveFolderId);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this is a smart folder
    final foldersAsync = ref.watch(recipeFolderNotifierProvider);
    final currentFolder = foldersAsync.whenOrNull(
      data: (folders) => folders.where((f) => f.id == folderId).firstOrNull,
    );
    final isSmartFolder = currentFolder != null && currentFolder.folderType != 0;

    // If smart folder, use the dedicated provider
    if (isSmartFolder) {
      return _buildSmartFolderPage(context, ref, currentFolder);
    }

    // Build menu items once for reuse
    final addRecipeMenuItems = _buildAddRecipeMenuItems(context, ref);

    // Watch all recipes (for normal folders)
    final recipesAsyncValue = ref.watch(recipeNotifierProvider);

    // Watch pantry recipe matches if needed for filtering
    final pantryMatchesAsyncValue = ref.watch(pantryRecipeMatchProvider);

    // Listen to filter changes to load necessary data
    ref.listen(recipeFolderFilterSortProvider, (previous, current) {
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
            addRecipeMenuItems: addRecipeMenuItems,
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
              filteredRecipes = FilterUtils.applyFilters(
                recipes: filteredRecipes,
                filterState: filterSortState,
                pantryMatchesAsyncValue: pantryMatchesAsyncValue,
              );
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
        items: addRecipeMenuItems,
        child: const AppCircleButton(
          icon: AppCircleButtonIcon.plus,
        ),
      ),
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: true,
    );
  }

  /// Build page for smart folders using the dedicated provider
  Widget _buildSmartFolderPage(BuildContext context, WidgetRef ref, RecipeFolderEntry folder) {
    final recipesAsync = ref.watch(smartFolderRecipesProvider(folder));

    return AdaptiveSliverPage(
      title: title,
      searchEnabled: true,
      searchResultsBuilder: (context, query) => SmartFolderSearchResults(
        folder: folder,
        currentPageTitle: title,
      ),
      onSearchChanged: (query) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(smartFolderSearchQueryProvider.notifier).search(query);
        });
      },
      slivers: [
        recipesAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (recipes) {
            if (recipes.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Text(
                    folder.folderType == 1
                        ? 'No recipes match the selected tags'
                        : 'No recipes match the selected ingredients',
                  ),
                ),
              );
            }
            return RecipesList(recipes: recipes, currentPageTitle: title);
          },
        ),
      ],
      // Trailing menu with edit option for smart folders
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Edit Smart Folder',
            icon: const Icon(Icons.tune),
            onTap: () {
              showEditSmartFolderModal(context, folder);
            },
          ),
        ],
        child: const AppCircleButton(
          icon: AppCircleButtonIcon.ellipsis,
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
  final List<AdaptiveMenuItem> addRecipeMenuItems;

  _UnifiedHeaderDelegate({
    required this.filterSortState,
    required this.folderId,
    required this.onStateChanged,
    required this.addRecipeMenuItems,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final size = MediaQuery.sizeOf(context);
    // Use compact layout (content-sized button) only in landscape mode
    final isLandscape = size.width > size.height;

    // Filter button with indicator dot
    Widget filterButton({required bool fullWidth}) => Stack(
      clipBehavior: Clip.none,
      children: [
        AppButton(
          text: 'Filter and Sort',
          leadingIcon: const Icon(Icons.tune),
          style: AppButtonStyle.mutedOutline,
          shape: AppButtonShape.square,
          size: AppButtonSize.medium,
          theme: AppButtonTheme.primary,
          fullWidth: fullWidth,
          contentAlignment: AppButtonContentAlignment.left,
          onPressed: () {
            showUnifiedSortFilterSheet(
              context,
              initialState: filterSortState,
              onStateChanged: onStateChanged,
              showPantryMatchOption: true,
            );
          },
        ),
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
    );

    // Add Recipe button with dropdown menu
    Widget addRecipeButton() => AdaptivePullDownButton(
      items: addRecipeMenuItems,
      child: const AppButton(
        text: 'Add Recipe',
        leadingIcon: Icon(Icons.add),
        style: AppButtonStyle.outline,
        shape: AppButtonShape.square,
        size: AppButtonSize.medium,
        theme: AppButtonTheme.secondary,
        visuallyEnabled: true,
      ),
    );

    return Material(
      elevation: overlapsContent ? 1.0 : 0.0,
      color: Colors.transparent,
      child: Container(
        height: minExtent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        constraints: const BoxConstraints(maxWidth: 800),
        child: isLandscape
            // Landscape: content-sized filter button, spacer, add recipe button
            ? Row(
                children: [
                  filterButton(fullWidth: false),
                  const Spacer(),
                  addRecipeButton(),
                ],
              )
            // Portrait: expanded filter button, add recipe button
            : Row(
                children: [
                  Expanded(child: filterButton(fullWidth: true)),
                  const SizedBox(width: 12),
                  addRecipeButton(),
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
