import 'package:flutter/material.dart';
import '../../../../../database/models/pantry_items.dart';
import '../../models/pantry_filter_sort.dart';
import 'category_filter_sheet.dart';
import 'stock_status_filter_sheet.dart';

class PantryFilterChips extends StatelessWidget {
  final PantryFilterSortState filterState;
  final Function(PantryFilterType, dynamic) onFilterChanged;

  const PantryFilterChips({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategoryChip(context),
          const SizedBox(width: 8),
          _buildStockStatusChip(context),
          const SizedBox(width: 8),
          _buildShowStaplesChip(context),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    final selectedCategories = filterState.activeFilters[PantryFilterType.category] as List<String>? ?? [];
    final hasSelection = selectedCategories.isNotEmpty;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Category'),
          if (hasSelection) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                selectedCategories.length.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: hasSelection,
      onSelected: (_) {
        showCategoryFilterSheet(
          context,
          selectedCategories: selectedCategories,
          onCategoriesChanged: (categories) {
            onFilterChanged(PantryFilterType.category, categories);
          },
        );
      },
    );
  }

  Widget _buildStockStatusChip(BuildContext context) {
    final selectedStatuses = filterState.activeFilters[PantryFilterType.stockStatus] as List<StockStatus>? ?? [];
    final hasSelection = selectedStatuses.isNotEmpty;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Stock Status'),
          if (hasSelection) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                selectedStatuses.length.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: hasSelection,
      onSelected: (_) {
        showStockStatusFilterSheet(
          context,
          selectedStatuses: selectedStatuses,
          onStatusesChanged: (statuses) {
            onFilterChanged(PantryFilterType.stockStatus, statuses);
          },
        );
      },
    );
  }

  Widget _buildShowStaplesChip(BuildContext context) {
    // showStaples defaults to true, so we only show the chip as "active" when it's true
    final showStaples = filterState.activeFilters[PantryFilterType.showStaples] as bool? ?? true;

    return FilterChip(
      label: const Text('Show Staples'),
      selected: showStaples,
      onSelected: (selected) {
        onFilterChanged(PantryFilterType.showStaples, selected);
      },
    );
  }
}