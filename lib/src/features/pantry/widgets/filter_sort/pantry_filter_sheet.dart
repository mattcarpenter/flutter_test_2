import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../../database/database.dart';
import '../../../../../database/models/pantry_items.dart';
import '../../../../providers/pantry_provider.dart';
import '../../models/pantry_filter_sort.dart';

/// Shows a bottom sheet with pantry filtering options
void showPantryFilterSheet(
  BuildContext context, {
  required PantryFilterSortState initialState,
  required Function(PantryFilterSortState) onFilterChanged,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: const Text('Filter Pantry Items'),
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
          child: PantryFilterContent(
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
      // The modal will auto-dismiss, no need to manually pop
    },
  );
}

class PantryFilterContent extends ConsumerStatefulWidget {
  final PantryFilterSortState initialState;
  final Function(PantryFilterSortState) onFilterChanged;

  const PantryFilterContent({
    super.key,
    required this.initialState,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<PantryFilterContent> createState() => _PantryFilterContentState();
}

class _PantryFilterContentState extends ConsumerState<PantryFilterContent> {
  late PantryFilterSortState filterState;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the initial state to avoid reference issues
    filterState = PantryFilterSortState(
      activeFilters: Map<PantryFilterType, dynamic>.from(widget.initialState.activeFilters),
      activeSortOption: widget.initialState.activeSortOption,
      sortDirection: widget.initialState.sortDirection,
    );
  }

  void _updateFilter(PantryFilterType type, dynamic value) {
    setState(() {
      if (value == null || 
          (value is List && value.isEmpty) ||
          (value is bool && !value)) {
        filterState = filterState.withoutFilter(type);
      } else {
        filterState = filterState.withFilter(type, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantryItemsAsyncValue = ref.watch(pantryItemsProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: pantryItemsAsyncValue.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (pantryItems) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryFilter(pantryItems),
                      const Divider(),
                      _buildStockStatusFilter(),
                      const Divider(),
                      _buildShowStaplesFilter(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
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

  Widget _buildCategoryFilter(List<PantryItemEntry> pantryItems) {
    // Extract unique categories from pantry items
    final categories = pantryItems
        .map((item) => item.category ?? 'Other')
        .toSet()
        .toList()
      ..sort((a, b) {
        if (a == 'Other' && b != 'Other') return 1;
        if (b == 'Other' && a != 'Other') return -1;
        return a.compareTo(b);
      });

    final selectedCategories = filterState.activeFilters[PantryFilterType.category] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (categories.isEmpty)
          const Text('No categories available')
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: categories.map((category) {
              final isSelected = selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  final newCategories = List<String>.from(selectedCategories);
                  if (selected) {
                    newCategories.add(category);
                  } else {
                    newCategories.remove(category);
                  }
                  _updateFilter(PantryFilterType.category, newCategories);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStockStatusFilter() {
    final selectedStatuses = filterState.activeFilters[PantryFilterType.stockStatus] as List<StockStatus>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Stock Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: StockStatusFilter.values.map((filter) {
            final isSelected = selectedStatuses.contains(filter.stockStatus);
            return FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                final newStatuses = List<StockStatus>.from(selectedStatuses);
                if (selected) {
                  newStatuses.add(filter.stockStatus);
                } else {
                  newStatuses.remove(filter.stockStatus);
                }
                _updateFilter(PantryFilterType.stockStatus, newStatuses);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShowStaplesFilter() {
    final showStaples = filterState.activeFilters[PantryFilterType.showStaples] as bool? ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FilterChip(
          label: const Text('Show Staples'),
          selected: showStaples,
          onSelected: (selected) {
            _updateFilter(PantryFilterType.showStaples, selected);
          },
        ),
      ],
    );
  }
}