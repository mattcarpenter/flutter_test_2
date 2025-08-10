import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/spacing.dart';
import '../../../../widgets/app_button.dart';
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
          backgroundColor: AppColors.of(modalContext).background,
          leadingNavBarWidget: TextButton(
            onPressed: () {
              // Clear all filters
              onFilterChanged(initialState.clearFilters());
              Navigator.of(modalContext).pop();
            },
            child: const Text('Clear All'),
          ),
          trailingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
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
    final colors = AppColors.of(context);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm, // Reduced top spacing
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Size to content
        children: [
          _buildCookTimeFilter(),
          SizedBox(height: AppSpacing.xl), // Replace divider with spacing
          _buildRatingFilter(),
          SizedBox(height: AppSpacing.xl), // Replace divider with spacing
          _buildPantryMatchFilter(),
          SizedBox(height: AppSpacing.xl), // Extra margin before Apply button
          AppButton(
            text: 'Apply Filters',
            theme: AppButtonTheme.secondary,
            onPressed: () {
              print('Applying filters: ${filterState.activeFilters}');
              widget.onFilterChanged(filterState);
            },
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCookTimeFilter() {
    final colors = AppColors.of(context);
    final selectedValue = filterState.activeFilters[FilterType.cookTime] as CookTimeFilter?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Center(
            child: Text(
              'Cook Time',
              style: AppTypography.h5.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: CookTimeFilter.values.map((filter) {
            final isSelected = selectedValue == filter;
              return AppButton(
                text: filter.label,
                size: AppButtonSize.small,
                style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                onPressed: () {
                  _updateFilter(
                    FilterType.cookTime, 
                    isSelected ? null : filter
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    final colors = AppColors.of(context);
    final selectedValue = filterState.activeFilters[FilterType.rating] as RatingFilter?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Center(
            child: Text(
              'Rating',
              style: AppTypography.h5.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: RatingFilter.values.map((filter) {
              final isSelected = selectedValue == filter;
              return AppButton(
                text: filter.label,
                size: AppButtonSize.small,
                style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                onPressed: () {
                  _updateFilter(
                    FilterType.rating, 
                    isSelected ? null : filter
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPantryMatchFilter() {
    final colors = AppColors.of(context);
    final selectedValue = filterState.activeFilters[FilterType.pantryMatch] as PantryMatchFilter?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Center(
            child: Text(
              'Pantry Match',
              style: AppTypography.h5.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: PantryMatchFilter.values.map((filter) {
              final isSelected = selectedValue == filter;
              return AppButton(
                text: filter.label,
                size: AppButtonSize.small,
                style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                onPressed: () {
                  _updateFilter(
                    FilterType.pantryMatch, 
                    isSelected ? null : filter
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}