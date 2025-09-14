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
// Central controller class to manage all filter state and sticky button
class _FilterStateController extends ChangeNotifier {
  final RecipeFilterSortState initialState;
  final Function(RecipeFilterSortState) onStateChanged;
  
  // Individual filter states
  Set<CookTimeFilter> cookTimeFilters = {};
  Set<RatingFilter> ratingFilters = {};
  double pantryMatchPercentage = 0.0;
  Set<String> selectedTagIds = {};
  TagFilterMode tagFilterMode = TagFilterMode.or;
  SortOption sortOption = SortOption.alphabetical;
  SortDirection sortDirection = SortDirection.ascending;
  
  // Initial states for comparison
  late Set<CookTimeFilter> _initialCookTimeFilters;
  late Set<RatingFilter> _initialRatingFilters;
  late double _initialPantryMatchPercentage;
  late Set<String> _initialSelectedTagIds;
  late TagFilterMode _initialTagFilterMode;
  late SortOption _initialSortOption;
  late SortDirection _initialSortDirection;

  _FilterStateController({
    required this.initialState,
    required this.onStateChanged,
  }) {
    _initializeFromState();
  }

  void _initializeFromState() {
    // Initialize cook time filters
    final existingCookTimeFilter = initialState.activeFilters[FilterType.cookTime] as CookTimeMultiFilter?;
    cookTimeFilters = existingCookTimeFilter?.selectedFilters.toSet() ?? {};
    _initialCookTimeFilters = Set.from(cookTimeFilters);

    // Initialize rating filters
    final existingRatingFilter = initialState.activeFilters[FilterType.rating] as RatingMultiFilter?;
    ratingFilters = existingRatingFilter?.selectedRatings.toSet() ?? {};
    _initialRatingFilters = Set.from(ratingFilters);

    // Initialize pantry match
    final existingPantryFilter = initialState.activeFilters[FilterType.pantryMatch] as PantryMatchSliderFilter?;
    pantryMatchPercentage = existingPantryFilter?.percentage ?? 0.0;
    _initialPantryMatchPercentage = pantryMatchPercentage;

    // Initialize tags
    final existingTagFilter = initialState.activeFilters[FilterType.tags] as TagFilter?;
    selectedTagIds = existingTagFilter?.selectedTagIds.toSet() ?? {};
    _initialSelectedTagIds = Set.from(selectedTagIds);
    tagFilterMode = existingTagFilter?.mode ?? TagFilterMode.or;
    _initialTagFilterMode = tagFilterMode;

    // Initialize sort
    sortOption = initialState.activeSortOption;
    sortDirection = initialState.sortDirection;
    _initialSortOption = sortOption;
    _initialSortDirection = sortDirection;
  }

  bool get hasChanges {
    return !_setsEqual(cookTimeFilters, _initialCookTimeFilters) ||
           !_setsEqual(ratingFilters, _initialRatingFilters) ||
           pantryMatchPercentage != _initialPantryMatchPercentage ||
           !_setsEqual(selectedTagIds, _initialSelectedTagIds) ||
           tagFilterMode != _initialTagFilterMode ||
           sortOption != _initialSortOption ||
           sortDirection != _initialSortDirection;
  }

  bool get isButtonEnabled => hasChanges;

  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    return set1.length == set2.length && set1.every((element) => set2.contains(element));
  }

  // Update methods for individual filters
  void updateCookTimeFilters(Set<CookTimeFilter> filters) {
    cookTimeFilters = filters;
    notifyListeners();
  }

  void updateRatingFilters(Set<RatingFilter> filters) {
    ratingFilters = filters;
    notifyListeners();
  }

  void updatePantryMatchPercentage(double percentage) {
    pantryMatchPercentage = percentage;
    notifyListeners();
  }

  void updateTagFilters(Set<String> tagIds, TagFilterMode mode) {
    selectedTagIds = tagIds;
    tagFilterMode = mode;
    notifyListeners();
  }

  void updateSort(SortOption option, SortDirection direction) {
    sortOption = option;
    sortDirection = direction;
    notifyListeners();
  }

  void applyChanges() {
    // Build the new state with all filter changes
    RecipeFilterSortState newState = initialState.copyWith(
      activeSortOption: sortOption,
      sortDirection: sortDirection,
    );

    // Apply cook time filter
    if (cookTimeFilters.isEmpty) {
      newState = newState.withoutFilter(FilterType.cookTime);
    } else {
      final cookTimeFilter = CookTimeMultiFilter(selectedFilters: cookTimeFilters);
      newState = newState.withFilter(FilterType.cookTime, cookTimeFilter);
    }

    // Apply rating filter
    if (ratingFilters.isEmpty) {
      newState = newState.withoutFilter(FilterType.rating);
    } else {
      final ratingFilter = RatingMultiFilter(selectedRatings: ratingFilters);
      newState = newState.withFilter(FilterType.rating, ratingFilter);
    }

    // Apply pantry match filter
    if (pantryMatchPercentage == 0.0) {
      newState = newState.withoutFilter(FilterType.pantryMatch);
    } else {
      final pantryFilter = PantryMatchSliderFilter(percentage: pantryMatchPercentage);
      newState = newState.withFilter(FilterType.pantryMatch, pantryFilter);
    }

    // Apply tag filter
    if (selectedTagIds.isEmpty) {
      newState = newState.withoutFilter(FilterType.tags);
    } else {
      final tagFilter = TagFilter(
        selectedTagIds: selectedTagIds.toList(),
        mode: tagFilterMode,
      );
      newState = newState.withFilter(FilterType.tags, tagFilter);
    }

    // Apply the new state
    onStateChanged(newState);
  }
}

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
        _UnifiedSortFilterModalPage.build(
          modalContext: modalContext,
          initialState: initialState,
          onStateChanged: onStateChanged,
          showPantryMatchOption: showPantryMatchOption,
        ),
      ];
    },
  );
}

class _UnifiedSortFilterModalPage {
  _UnifiedSortFilterModalPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext modalContext,
    required RecipeFilterSortState initialState,
    required Function(RecipeFilterSortState) onStateChanged,
    required bool showPantryMatchOption,
  }) {
    final controller = _FilterStateController(
      initialState: initialState,
      onStateChanged: onStateChanged,
    );

    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(modalContext).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true, // Enable top bar layer to prevent overlap
      isTopBarLayerAlwaysVisible: true, // Keep nav bar always visible
      hasSabGradient: true, // Re-enable gradient for sticky content indication
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
      stickyActionBar: Container(
        decoration: BoxDecoration(
          color: AppColors.of(modalContext).background,
          border: Border(
            top: BorderSide(
              color: AppColors.of(modalContext).border,
              width: 0.5,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              return AppButton(
                text: 'Apply Changes',
                theme: AppButtonTheme.secondary,
                onPressed: controller.isButtonEnabled
                    ? () {
                        controller.applyChanges();
                        Navigator.of(modalContext).pop();
                      }
                    : null,
                fullWidth: true,
              );
            },
          ),
        ),
      ),
      mainContentSliversBuilder: (context) => [
        // Sort Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: _SortSection(
              controller: controller,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.lg),
        ),

        // Cook Time Filter - Individual sliver
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _IndividualCookTimeFilter(
              controller: controller,
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        // Rating Filter - Individual sliver
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _IndividualRatingFilter(
              controller: controller,
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        // Pantry Match Filter - Individual sliver
        if (showPantryMatchOption)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _IndividualPantryMatchFilter(
                controller: controller,
              ),
            ),
          ),

        if (showPantryMatchOption) SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        // Tags Filter - Individual sliver (this one can be large)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _IndividualTagsFilter(
              controller: controller,
            ),
          ),
        ),

        // Bottom padding for sticky action bar (reduced for tighter spacing)
        SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg), // Minimal space for sticky action bar
          sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
        ),
      ],
    );
  }
}

// Individual Cook Time Filter Widget
class _IndividualCookTimeFilter extends ConsumerStatefulWidget {
  final _FilterStateController controller;

  const _IndividualCookTimeFilter({
    required this.controller,
  });

  @override
  ConsumerState<_IndividualCookTimeFilter> createState() => _IndividualCookTimeFilterState();
}

class _IndividualCookTimeFilterState extends ConsumerState<_IndividualCookTimeFilter> {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cook Time',
              style: AppTypography.h5.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.start,
                children: CookTimeFilter.values.map((filter) {
                  final isSelected = widget.controller.cookTimeFilters.contains(filter);
                  return AppButton(
                    text: filter.label,
                    size: AppButtonSize.small,
                    style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                    onPressed: () {
                      final newFilters = Set<CookTimeFilter>.from(widget.controller.cookTimeFilters);
                      if (isSelected) {
                        newFilters.remove(filter);
                      } else {
                        newFilters.add(filter);
                      }
                      widget.controller.updateCookTimeFilters(newFilters);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Individual Rating Filter Widget
class _IndividualRatingFilter extends ConsumerStatefulWidget {
  final _FilterStateController controller;

  const _IndividualRatingFilter({
    required this.controller,
  });

  @override
  ConsumerState<_IndividualRatingFilter> createState() => _IndividualRatingFilterState();
}

class _IndividualRatingFilterState extends ConsumerState<_IndividualRatingFilter> {

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating',
              style: AppTypography.h5.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.start,
                children: RatingFilter.values.map((filter) {
                  final isSelected = widget.controller.ratingFilters.contains(filter);
                  return AppButton(
                    text: filter.stars,
                    size: AppButtonSize.small,
                    style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                    onPressed: () {
                      if (isSelected) {
                        widget.controller.ratingFilters.remove(filter);
                      } else {
                        widget.controller.ratingFilters.add(filter);
                      }
                      widget.controller.notifyListeners();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Individual Pantry Match Filter Widget
class _IndividualPantryMatchFilter extends ConsumerStatefulWidget {
  final _FilterStateController controller;

  const _IndividualPantryMatchFilter({
    required this.controller,
  });

  @override
  ConsumerState<_IndividualPantryMatchFilter> createState() => _IndividualPantryMatchFilterState();
}

class _IndividualPantryMatchFilterState extends ConsumerState<_IndividualPantryMatchFilter> {

  String _getSliderLabel(double value) {
    final percent = (value * 100).round();
    if (percent == 0) return "Match any recipe (Stock not required)";
    if (percent == 25) return 'A few ingredients in stock (25%)';
    if (percent == 50) return 'At least half ingredients in stock (50%)';
    if (percent == 75) return 'Most ingredients in stock (75%)';
    if (percent == 100) return 'All ingredients in stock (100%)';
    return '$percent% match';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pantry Match',
          style: AppTypography.h5.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: AppSpacing.md),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: AppColorSwatches.neutral[300],
                    thumbColor: colors.primary,
                    overlayColor: colors.primary.withValues(alpha: 0.1),
                    tickMarkShape: RoundSliderTickMarkShape(),
                    activeTickMarkColor: colors.primary,
                    inactiveTickMarkColor: AppColorSwatches.neutral[400],
                  ),
                  child: Slider(
                    value: widget.controller.pantryMatchPercentage,
                    min: 0.0,
                    max: 1.0,
                    divisions: 4,
                    onChanged: (value) {
                      widget.controller.pantryMatchPercentage = value;
                      widget.controller.notifyListeners();
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    _getSliderLabel(widget.controller.pantryMatchPercentage),
                    style: AppTypography.body.copyWith(color: colors.textSecondary),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Individual Tags Filter Widget
class _IndividualTagsFilter extends ConsumerStatefulWidget {
  final _FilterStateController controller;

  const _IndividualTagsFilter({
    required this.controller,
  });

  @override
  ConsumerState<_IndividualTagsFilter> createState() => _IndividualTagsFilterState();
}

class _IndividualTagsFilterState extends ConsumerState<_IndividualTagsFilter> {

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tagsAsync = ref.watch(recipeTagNotifierProvider);

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tags',
                  style: AppTypography.h5.copyWith(color: colors.textPrimary),
                ),
                Row(
                  children: [
                    Text(
                      'Must have all tags',
                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    CupertinoSwitch(
                      value: widget.controller.tagFilterMode == TagFilterMode.and,
                      onChanged: (value) {
                        widget.controller.tagFilterMode = value ? TagFilterMode.and : TagFilterMode.or;
                        widget.controller.notifyListeners();
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.start,
                children: tags.map((tag) {
                  final isSelected = widget.controller.selectedTagIds.contains(tag.id);
                  return AppButton(
                    text: tag.name,
                    size: AppButtonSize.small,
                    style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                    onPressed: () {
                      if (isSelected) {
                        widget.controller.selectedTagIds.remove(tag.id);
                      } else {
                        widget.controller.selectedTagIds.add(tag.id);
                      }
                      widget.controller.notifyListeners();
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
            SizedBox(height: 200),
          ],
        );
          },
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Sort section widget
class _SortSection extends ConsumerStatefulWidget {
  final _FilterStateController controller;

  const _SortSection({
    required this.controller,
  });

  @override
  ConsumerState<_SortSection> createState() => _SortSectionState();
}

class _SortSectionState extends ConsumerState<_SortSection> {


  @override
  Widget build(BuildContext context) {
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
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, child) {
                  return AdaptivePullDownButton(
                    items: _buildSortOptions().map((option) {
                  final isSelected = widget.controller.sortOption == option;
                  return AdaptiveMenuItem(
                    title: option.label,
                    icon: Icon(
                      isSelected ? Icons.check_circle : Icons.sort,
                      size: 16,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                    onTap: () {
                      widget.controller.sortOption = option;
                      widget.controller.notifyListeners();
                    },
                  );
                }).toList(),
                child: AppButton(
                  text: 'Sort by ${widget.controller.sortOption.label}',
                  trailingIcon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                  ),
                  style: AppButtonStyle.mutedOutline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  theme: AppButtonTheme.primary,
                  fullWidth: true,
                  onPressed: null, // AdaptivePullDownButton handles the tap
                  visuallyEnabled: true, // Keep it looking enabled
                ),
              );
                },
              ),
            ),

            SizedBox(width: AppSpacing.md),

            // Direction toggle button
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, child) {
                return AppButton(
              text: widget.controller.sortDirection == SortDirection.ascending ? 'A-Z' : 'Z-A',
              leadingIcon: Icon(
                widget.controller.sortDirection == SortDirection.ascending
                    ? Icons.north
                    : Icons.south,
                size: 16,
              ),
              style: AppButtonStyle.mutedOutline,
              shape: AppButtonShape.square,
              size: AppButtonSize.medium,
              theme: AppButtonTheme.primary,
              onPressed: () {
                final newDirection = widget.controller.sortDirection == SortDirection.ascending
                    ? SortDirection.descending
                    : SortDirection.ascending;
                widget.controller.sortDirection = newDirection;
                widget.controller.notifyListeners();
              },
            );
              },
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  List<SortOption> _buildSortOptions() {
    final options = <SortOption>[];

    for (final sortOption in SortOption.values) {
      // Filter out pantry match option when not needed - we'll handle this properly later
      options.add(sortOption);
    }

    return options;
  }
}
