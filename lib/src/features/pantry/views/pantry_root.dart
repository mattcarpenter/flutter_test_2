import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/pantry_provider.dart';
import '../../../providers/pantry_filter_sort_provider.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/pantry_filter_sort.dart';
import '../widgets/filter_sort/pantry_filter_chips.dart';
import '../widgets/filter_sort/pantry_sort_dropdown.dart';
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
        // Filter/Sort header in a SliverPersistentHeader
        SliverPersistentHeader(
          pinned: false,
          floating: true,
          delegate: _FilterSortHeaderDelegate(
            filterState: filterSortState,
            onFilterChanged: (type, value) {
              ref.read(pantryFilterSortProvider.notifier).updateFilter(type, value);
            },
            sortOption: filterSortState.activeSortOption,
            sortDirection: filterSortState.sortDirection,
            onSortOptionChanged: (option) {
              ref.read(pantryFilterSortProvider.notifier).updateSortOption(option);
            },
            onSortDirectionChanged: (direction) {
              ref.read(pantryFilterSortProvider.notifier).updateSortDirection(direction);
            },
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
                      Text(filterSortState.hasFilters 
                          ? 'No pantry items match the current filters'
                          : 'No pantry items yet. Tap the + button to add items.'),
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

/// Delegate for the filter/sort header in a sliver persistent header
class _FilterSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final PantryFilterSortState filterState;
  final Function(PantryFilterType, dynamic) onFilterChanged;
  final PantrySortOption sortOption;
  final SortDirection sortDirection;
  final Function(PantrySortOption) onSortOptionChanged;
  final Function(SortDirection) onSortDirectionChanged;

  _FilterSortHeaderDelegate({
    required this.filterState,
    required this.onFilterChanged,
    required this.sortOption,
    required this.sortDirection,
    required this.onSortOptionChanged,
    required this.onSortDirectionChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 1.0 : 0.0,
      color: Colors.white.withValues(alpha: 0.95),
      child: Container(
        height: minExtent,
        padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
        child: Row(
          children: [
            // Sort dropdown on the left
            PantrySortDropdown(
              sortOption: sortOption,
              sortDirection: sortDirection,
              onSortOptionChanged: onSortOptionChanged,
              onSortDirectionChanged: onSortDirectionChanged,
            ),
            
            const SizedBox(width: 16),
            
            // Filter chips on the right, horizontally scrollable
            Expanded(
              child: PantryFilterChips(
                filterState: filterState,
                onFilterChanged: onFilterChanged,
              ),
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
  bool shouldRebuild(covariant _FilterSortHeaderDelegate oldDelegate) {
    return oldDelegate.filterState.filterCount != filterState.filterCount ||
           oldDelegate.filterState.hasFilters != filterState.hasFilters ||
           oldDelegate.filterState.activeFilters != filterState.activeFilters ||
           oldDelegate.sortOption != sortOption ||
           oldDelegate.sortDirection != sortDirection;
  }

  @override
  TickerProvider? get vsync => null;
}
