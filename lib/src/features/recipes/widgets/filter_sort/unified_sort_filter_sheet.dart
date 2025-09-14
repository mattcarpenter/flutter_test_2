import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../constants/tag_colors.dart';
import '../../../../providers/recipe_tag_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/spacing.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_circle_button.dart';
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
          navBarHeight: 55,
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: false,
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
          trailingNavBarWidget: Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              onPressed: () {
                Navigator.of(modalContext).pop();
              },
            ),
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

  // Local state for tag filter
  late Set<String> _selectedTagIds;
  late TagFilterMode _tagFilterMode;

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

    // Initialize tag filter state
    final existingTagFilter = currentState.activeFilters[FilterType.tags] as TagFilter?;
    _selectedTagIds = existingTagFilter?.selectedTagIds.toSet() ?? {};
    _tagFilterMode = existingTagFilter?.mode ?? TagFilterMode.or;
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

  void _updateTagFilter() {
    if (_selectedTagIds.isEmpty) {
      currentState = currentState.withoutFilter(FilterType.tags);
    } else {
      final tagFilter = TagFilter(
        selectedTagIds: _selectedTagIds.toList(),
        mode: _tagFilterMode,
      );
      currentState = currentState.withFilter(FilterType.tags, tagFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sort Section - padded
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSortSection(),
              SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),

        // Divider - edge-to-edge (no padding)
        Container(
          height: 10,
          margin: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          color: AppColorSwatches.neutral[250]!,
        ),

        // Filter sections - padded
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCookTimeFilter(),
              SizedBox(height: AppSpacing.xl),
              _buildRatingFilter(),
              SizedBox(height: AppSpacing.xl),
              _buildPantryMatchFilter(),
              SizedBox(height: AppSpacing.xl),
              _buildTagsFilter(),
              SizedBox(height: AppSpacing.xl),

              // Apply button
              AppButton(
                text: 'Apply Changes',
                theme: AppButtonTheme.secondary,
                onPressed: () {
                  // Update tag filter in current state before applying
                  _updateTagFilter();
                  widget.onStateChanged(currentState);
                },
                fullWidth: true,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildTagsFilter() {
    final colors = AppColors.of(context);
    final tagsAsync = ref.watch(recipeTagNotifierProvider);

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with toggle switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tags',
                  style: AppTypography.h5.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Must have all tags',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    CupertinoSwitch(
                      value: _tagFilterMode == TagFilterMode.and,
                      onChanged: (value) {
                        setState(() {
                          _tagFilterMode = value ? TagFilterMode.and : TagFilterMode.or;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Tags wrapped buttons
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.start,
                children: tags.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  return AppButton(
                    text: tag.name,
                    size: AppButtonSize.small,
                    style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTagIds.remove(tag.id);
                        } else {
                          _selectedTagIds.add(tag.id);
                        }
                      });
                    },
                    leadingIcon: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: TagColors.fromHex(tag.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
