import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/pantry_filter_sort_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/pantry_filter_sort.dart';
import '../widgets/filter_sort/unified_pantry_sort_filter_sheet.dart';
import '../widgets/pantry_item_list.dart';
import '../widgets/pantry_selection_fab.dart';
import 'add_pantry_item_modal.dart';

class PantryTab extends ConsumerWidget {
  const PantryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all pantry items
    final pantryItemsAsyncValue = ref.watch(pantryItemsProvider);

    // Watch filter/sort state
    final filterSortState = ref.watch(pantryFilterSort);

    return Stack(
      children: [
        AdaptiveSliverPage(
          title: 'Pantry',
          searchEnabled: true,
          onSearchChanged: (query) {
            ref.read(pantryFilterSortProvider.notifier).updateSearchQuery(query);
          },
          slivers: [
        // Filter and Sort + Add Item buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppButton(
                        text: 'Filter and Sort',
                        leadingIcon: const Icon(Icons.tune),
                        style: AppButtonStyle.mutedOutline,
                        shape: AppButtonShape.square,
                        size: AppButtonSize.medium,
                        theme: AppButtonTheme.primary,
                        fullWidth: true,
                        contentAlignment: AppButtonContentAlignment.left,
                        onPressed: () {
                          showUnifiedPantrySortFilterSheet(
                            context,
                            initialState: filterSortState,
                            onStateChanged: (newState) {
                              final notifier = ref.read(pantryFilterSortProvider.notifier);
                              notifier.clearFilters();
                              notifier.updateSortOption(newState.activeSortOption);
                              notifier.updateSortDirection(newState.sortDirection);
                              for (final entry in newState.activeFilters.entries) {
                                notifier.updateFilter(entry.key, entry.value);
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
                ),

                const SizedBox(width: 12), // Spacing between buttons

                // Add Item button (fixed width)
                AppButton(
                  text: 'Add Item',
                  leadingIcon: const Icon(Icons.add),
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  theme: AppButtonTheme.secondary,
                  onPressed: () {
                    showAddPantryItemModal(context);
                  },
                ),
              ],
            ),
          ),
        ),

        // Pantry items list with filtering and sorting applied
        pantryItemsAsyncValue.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (pantryItems) {
            // Apply filters
            List<PantryItemEntry> filteredItems = pantryItems;
            if (filterSortState.hasFilters) {
              filteredItems = pantryItems.applyFilters(filterSortState.activeFilters);
            }

            // Apply sorting
            filteredItems = filteredItems.applySorting(
              filterSortState.activeSortOption,
              filterSortState.sortDirection,
            );

            if (filteredItems.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        filterSortState.hasFilters
                          ? 'No pantry items match the current filters'
                          : 'No pantry items yet. Tap the + button to add items.',
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                      if (filterSortState.hasFilters)
                        TextButton(
                          onPressed: () {
                            ref.read(pantryFilterSortProvider.notifier).clearFilters();
                          },
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                ),
              );
            }

            return PantryItemList(
              pantryItems: filteredItems,
              showCategoryHeaders: filterSortState.showCategoryHeaders,
            );
          },
        ),
          ],
          trailing: AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'Add Pantry Item',
                icon: const Icon(CupertinoIcons.cart_badge_plus),
                onTap: () {
                  showAddPantryItemModal(context);
                },
              )
            ],
            child: const AppCircleButton(
              icon: AppCircleButtonIcon.plus,
            ),
          ),
        ),
        // Floating Action Button for selection
        const Positioned(
          bottom: 24,
          right: 24,
          child: PantrySelectionFAB(),
        ),
      ],
    );
  }
}
