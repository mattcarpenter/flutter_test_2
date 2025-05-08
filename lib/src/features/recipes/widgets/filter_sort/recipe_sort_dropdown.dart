import 'package:flutter/material.dart';
import '../../models/recipe_filter_sort.dart';

/// A dropdown component for selecting recipe sort options
class RecipeSortDropdown extends StatelessWidget {
  /// The current sort option
  final SortOption sortOption;
  
  /// The current sort direction
  final SortDirection sortDirection;
  
  /// Callback when the sort option changes
  final Function(SortOption) onSortOptionChanged;
  
  /// Callback when the sort direction changes
  final Function(SortDirection) onSortDirectionChanged;
  
  /// Whether to show the pantry match option (only relevant when in pantry matching context)
  final bool showPantryMatchOption;

  const RecipeSortDropdown({
    super.key,
    required this.sortOption,
    required this.sortDirection,
    required this.onSortOptionChanged,
    required this.onSortDirectionChanged,
    this.showPantryMatchOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sort option dropdown
        PopupMenuButton<SortOption>(
          tooltip: 'Sort by',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort),
                const SizedBox(width: 4),
                Text(sortOption.label),
              ],
            ),
          ),
          onSelected: onSortOptionChanged,
          itemBuilder: (context) {
            // Build sort options, conditionally including pantry match
            final options = SortOption.values.where((option) {
              // Filter out pantry match option when not needed
              if (option == SortOption.pantryMatch && !showPantryMatchOption) {
                return false;
              }
              return true;
            }).toList();
            
            return options.map((option) {
              return PopupMenuItem<SortOption>(
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
        IconButton(
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
      ],
    );
  }
}