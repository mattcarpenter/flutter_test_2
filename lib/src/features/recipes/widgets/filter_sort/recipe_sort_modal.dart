import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_radio_button_group.dart';
import '../../../../theme/spacing.dart';
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
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sort Direction Toggle Button
                    AppButton(
                      text: selectedSortDirection == SortDirection.ascending 
                          ? 'Ascending' 
                          : 'Descending',
                      onPressed: () {
                        setState(() {
                          selectedSortDirection = selectedSortDirection == SortDirection.ascending
                              ? SortDirection.descending
                              : SortDirection.ascending;
                        });
                        onSortDirectionChanged(selectedSortDirection);
                      },
                      theme: AppButtonTheme.primary,
                      style: AppButtonStyle.outline,
                      size: AppButtonSize.small,
                      leadingIcon: Icon(
                        selectedSortDirection == SortDirection.ascending
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
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
                    
                    const SizedBox(height: AppSpacing.xl),
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