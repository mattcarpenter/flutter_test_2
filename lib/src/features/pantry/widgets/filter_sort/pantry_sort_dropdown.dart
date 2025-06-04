import 'package:flutter/material.dart';
import '../../models/pantry_filter_sort.dart';

/// A dropdown component for selecting pantry sort options
class PantrySortDropdown extends StatelessWidget {
  /// The current sort option
  final PantrySortOption sortOption;
  
  /// The current sort direction
  final SortDirection sortDirection;
  
  /// Callback when the sort option changes
  final Function(PantrySortOption) onSortOptionChanged;
  
  /// Callback when the sort direction changes
  final Function(SortDirection) onSortDirectionChanged;

  const PantrySortDropdown({
    super.key,
    required this.sortOption,
    required this.sortDirection,
    required this.onSortOptionChanged,
    required this.onSortDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sort option dropdown
          PopupMenuButton<PantrySortOption>(
            tooltip: 'Sort by',
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.sort),
                  const SizedBox(width: 4),
                  Text(sortOption.label),
                ],
              ),
            ),
            onSelected: onSortOptionChanged,
            itemBuilder: (context) {
              return PantrySortOption.values.map((option) {
                return PopupMenuItem<PantrySortOption>(
                  value: option,
                  child: Row(
                    children: [
                      if (sortOption == option)
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(option.label),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          
          // Direction toggle
          Container(
            height: 36,
            alignment: Alignment.center,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: sortDirection == SortDirection.ascending 
                  ? 'Sort ascending' 
                  : 'Sort descending',
              icon: Icon(
                sortDirection == SortDirection.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 20,
              ),
              onPressed: () {
                onSortDirectionChanged(
                  sortDirection == SortDirection.ascending
                      ? SortDirection.descending
                      : SortDirection.ascending,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}