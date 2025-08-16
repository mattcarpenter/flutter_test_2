import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/spacing.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../models/recipe_filter_sort.dart';

/// Shows a unified bottom sheet with both sort and filter options
void showUnifiedSortFilterSheet(
  BuildContext context, {
  required RecipeFilterSortState initialState,
  required Function(RecipeFilterSortState) onStateChanged,
  bool showPantryMatchOption = false,
}) {
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
              // Clear all filters and reset sort
              final clearedState = initialState.clearFilters().copyWith(
                activeSortOption: SortOption.alphabetical,
                sortDirection: SortDirection.ascending,
              );
              onStateChanged(clearedState);
              Navigator.of(modalContext).pop();
            },
            child: const Text('Reset All'),
          ),
          trailingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          child: UnifiedSortFilterContent(
            initialState: initialState,
            onStateChanged: (newState) {
              onStateChanged(newState);
              Navigator.of(modalContext).pop();
            },
            showPantryMatchOption: showPantryMatchOption,
          ),
        ),
      ];
    },
  );
}

class UnifiedSortFilterContent extends ConsumerStatefulWidget {
  final RecipeFilterSortState initialState;
  final Function(RecipeFilterSortState) onStateChanged;
  final bool showPantryMatchOption;

  const UnifiedSortFilterContent({
    super.key,
    required this.initialState,
    required this.onStateChanged,
    this.showPantryMatchOption = false,
  });

  @override
  ConsumerState<UnifiedSortFilterContent> createState() => _UnifiedSortFilterContentState();
}

class _UnifiedSortFilterContentState extends ConsumerState<UnifiedSortFilterContent> {
  late RecipeFilterSortState currentState;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the initial state
    currentState = RecipeFilterSortState(
      activeFilters: Map<FilterType, dynamic>.from(widget.initialState.activeFilters),
      activeSortOption: widget.initialState.activeSortOption,
      sortDirection: widget.initialState.sortDirection,
      folderId: widget.initialState.folderId,
      searchQuery: widget.initialState.searchQuery,
    );
  }

  void _updateFilter(FilterType type, dynamic value) {
    setState(() {
      if (value == null) {
        currentState = currentState.withoutFilter(type);
      } else {
        currentState = currentState.withFilter(type, value);
      }
    });
  }

  void _updateSort(SortOption option, SortDirection direction) {
    setState(() {
      currentState = currentState.copyWith(
        activeSortOption: option,
        sortDirection: direction,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sort Section
          _buildSortSection(),
          
          SizedBox(height: AppSpacing.xl),
          
          // Divider
          Container(
            height: 1,
            color: colors.border,
            margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          
          // Filter Sections
          _buildCookTimeFilter(),
          SizedBox(height: AppSpacing.xl),
          _buildRatingFilter(),
          SizedBox(height: AppSpacing.xl),
          _buildPantryMatchFilter(),
          SizedBox(height: AppSpacing.xl),
          
          // Apply button
          AppButton(
            text: 'Apply Changes',
            theme: AppButtonTheme.secondary,
            onPressed: () {
              widget.onStateChanged(currentState);
            },
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    final colors = AppColors.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort',
          style: AppTypography.h5.copyWith(
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        
        Row(
          children: [
            // Sort dropdown button using AdaptivePullDownButton with AppButton
            Expanded(
              child: AdaptivePullDownButton(
                items: _buildSortOptions().map((option) {
                  final isSelected = currentState.activeSortOption == option;
                  return AdaptiveMenuItem(
                    title: isSelected ? '${option.label} ✓' : option.label,
                    icon: Icon(
                      isSelected ? Icons.check_circle : Icons.sort,
                      size: 16,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                    onTap: () {
                      _updateSort(option, currentState.sortDirection);
                    },
                  );
                }).toList(),
                child: AppButton(
                  text: 'Sort by ${currentState.activeSortOption.label}',
                  trailingIcon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                  ),
                  style: AppButtonStyle.mutedOutline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.small,
                  theme: AppButtonTheme.primary,
                  fullWidth: true,
                  onPressed: null, // AdaptivePullDownButton handles the tap
                  visuallyEnabled: true, // Keep it looking enabled
                ),
              ),
            ),
            
            SizedBox(width: AppSpacing.md),
            
            // Direction toggle button
            AppButton(
              text: currentState.sortDirection == SortDirection.ascending ? 'A-Z' : 'Z-A',
              leadingIcon: Icon(
                currentState.sortDirection == SortDirection.ascending
                    ? Icons.north
                    : Icons.south,
                size: 16,
              ),
              style: AppButtonStyle.mutedOutline,
              shape: AppButtonShape.square,
              size: AppButtonSize.small,
              theme: AppButtonTheme.primary,
              onPressed: () {
                final newDirection = currentState.sortDirection == SortDirection.ascending
                    ? SortDirection.descending
                    : SortDirection.ascending;
                _updateSort(currentState.activeSortOption, newDirection);
              },
            ),
          ],
        ),
      ],
    );
  }

  List<SortOption> _buildSortOptions() {
    final options = <SortOption>[];
    
    for (final sortOption in SortOption.values) {
      // Filter out pantry match option when not needed
      if (sortOption == SortOption.pantryMatch && !widget.showPantryMatchOption) {
        continue;
      }
      options.add(sortOption);
    }
    
    return options;
  }

  Widget _buildCookTimeFilter() {
    final colors = AppColors.of(context);
    final selectedValue = currentState.activeFilters[FilterType.cookTime] as CookTimeFilter?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            'Cook Time',
            style: AppTypography.h5.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.start,
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
    final selectedValue = currentState.activeFilters[FilterType.rating] as RatingFilter?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            'Rating',
            style: AppTypography.h5.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.start,
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
    final selectedValue = currentState.activeFilters[FilterType.pantryMatch] as PantryMatchFilter?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            'Pantry Match',
            style: AppTypography.h5.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.start,
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