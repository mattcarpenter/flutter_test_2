import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_radio_button_group.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/colors.dart';
import '../../models/recipe_filter_sort.dart';

/// A modal for selecting recipe sort options and direction
/// Uses Wolt modal sheet for consistent design
class RecipeSortModal {
  /// Shows the sort modal and returns the selected options
  static Future<void> show(
    BuildContext context, {
    required SortOption currentSortOption,
    required SortDirection currentSortDirection,
    required Function(SortOption) onSortOptionChanged,
    required Function(SortDirection) onSortDirectionChanged,
    bool showPantryMatchOption = false,
  }) async {
    // Create local state for the modal
    SortOption selectedSortOption = currentSortOption;
    SortDirection selectedSortDirection = currentSortDirection;

    await WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (modalSheetContext) => [
        WoltModalSheetPage(
          backgroundColor: AppColors.of(modalSheetContext).background,
          hasSabGradient: false,
          topBarTitle: const Text('Sort Options'),
          isTopBarLayerAlwaysVisible: true,
          trailingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(modalSheetContext).pop(),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sort Direction Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sort Direction',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16), // Space between label and button
                        Container(
                          margin: const EdgeInsets.only(right: 12), // Align centers with radio buttons
                          child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedSortDirection = selectedSortDirection == SortDirection.ascending
                                  ? SortDirection.descending
                                  : SortDirection.ascending;
                            });
                            onSortDirectionChanged(selectedSortDirection);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              selectedSortDirection == SortDirection.ascending
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Sort Options Radio Group
                    AppRadioButtonGroup<SortOption>(
                      options: _buildSortOptions(showPantryMatchOption),
                      selectedValue: selectedSortOption,
                      onChanged: (SortOption newOption) {
                        setState(() {
                          selectedSortOption = newOption;
                        });
                        onSortOptionChanged(newOption);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the list of sort options, conditionally including pantry match
  static List<RadioOption<SortOption>> _buildSortOptions(bool showPantryMatchOption) {
    final options = <RadioOption<SortOption>>[];
    
    for (final sortOption in SortOption.values) {
      // Filter out pantry match option when not needed
      if (sortOption == SortOption.pantryMatch && !showPantryMatchOption) {
        continue;
      }
      
      options.add(RadioOption(
        value: sortOption,
        label: sortOption.label,
      ));
    }
    
    return options;
  }
}