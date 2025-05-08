import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../models/recipe_filter_sort.dart';

/// Shows a bottom sheet with recipe filtering options
void showRecipeFilterSheet(
  BuildContext context, {
  required RecipeFilterSortState initialState,
  required Function(RecipeFilterSortState) onFilterChanged,
}) {
  print('Opening filter sheet with initial state: ${initialState.activeFilters}');
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: const Text('Filter Recipes'),
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          trailingNavBarWidget: TextButton(
            onPressed: () {
              // Clear all filters
              onFilterChanged(initialState.clearFilters());
              Navigator.of(modalContext).pop();
            },
            child: const Text('Clear All'),
          ),
          child: RecipeFilterContent(
            initialState: initialState,
            onFilterChanged: (newState) {
              onFilterChanged(newState);
              Navigator.of(modalContext).pop();
            },
          ),
        ),
      ];
    },
    onModalDismissedWithBarrierTap: () {
      Navigator.of(context).pop();
    },
  );
}

class RecipeFilterContent extends ConsumerStatefulWidget {
  final RecipeFilterSortState initialState;
  final Function(RecipeFilterSortState) onFilterChanged;

  const RecipeFilterContent({
    super.key,
    required this.initialState,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<RecipeFilterContent> createState() => _RecipeFilterContentState();
}

class _RecipeFilterContentState extends ConsumerState<RecipeFilterContent> {
  late RecipeFilterSortState filterState;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the initial state to avoid reference issues
    filterState = RecipeFilterSortState(
      activeFilters: Map<FilterType, dynamic>.from(widget.initialState.activeFilters),
      activeSortOption: widget.initialState.activeSortOption,
      sortDirection: widget.initialState.sortDirection,
      folderId: widget.initialState.folderId,
      searchQuery: widget.initialState.searchQuery,
    );
    
    print('RecipeFilterContent initialized with filters: ${filterState.activeFilters}');
  }

  void _updateFilter(FilterType type, dynamic value) {
    setState(() {
      if (value == null) {
        filterState = filterState.withoutFilter(type);
      } else {
        filterState = filterState.withFilter(type, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCookTimeFilter(),
                    const Divider(),
                    _buildRatingFilter(),
                    const Divider(),
                    _buildPantryMatchFilter(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print('Applying filters: ${filterState.activeFilters}');
                  widget.onFilterChanged(filterState);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookTimeFilter() {
    final selectedValue = filterState.activeFilters[FilterType.cookTime] as CookTimeFilter?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Cook Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: CookTimeFilter.values.map((filter) {
            final isSelected = selectedValue == filter;
            return FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                _updateFilter(
                  FilterType.cookTime, 
                  selected ? filter : null
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    final selectedValue = filterState.activeFilters[FilterType.rating] as RatingFilter?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Rating',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: RatingFilter.values.map((filter) {
            final isSelected = selectedValue == filter;
            return FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                _updateFilter(
                  FilterType.rating, 
                  selected ? filter : null
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPantryMatchFilter() {
    final selectedValue = filterState.activeFilters[FilterType.pantryMatch] as PantryMatchFilter?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Pantry Match',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: PantryMatchFilter.values.map((filter) {
            final isSelected = selectedValue == filter;
            return FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                _updateFilter(
                  FilterType.pantryMatch, 
                  selected ? filter : null
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}