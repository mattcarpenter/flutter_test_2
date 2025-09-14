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
// Simple controller class to manage sticky button state
class _StickyButtonController extends ChangeNotifier {
  bool _hasChanges = false;
  VoidCallback? _applyChanges;

  bool get hasChanges => _hasChanges;
  VoidCallback? get applyChanges => _applyChanges;

  bool get isButtonEnabled => _hasChanges && _applyChanges != null;

  void updateHasChanges(bool hasChanges) {
    if (_hasChanges != hasChanges) {
      _hasChanges = hasChanges;
      notifyListeners();
    }
  }

  void updateApplyCallback(VoidCallback? callback) {
    _applyChanges = callback;
    notifyListeners();
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
    final controller = _StickyButtonController();

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
                        controller.applyChanges!();
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
              initialState: initialState,
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
              initialState: initialState,
              onHasChangesChanged: controller.updateHasChanges,
              onApplyChangesCallbackChanged: controller.updateApplyCallback,
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        // Rating Filter - Individual sliver
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _IndividualRatingFilter(
              initialState: initialState,
              onHasChangesChanged: controller.updateHasChanges,
              onApplyChangesCallbackChanged: controller.updateApplyCallback,
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
                initialState: initialState,
                onHasChangesChanged: controller.updateHasChanges,
                onApplyChangesCallbackChanged: controller.updateApplyCallback,
              ),
            ),
          ),

        if (showPantryMatchOption) SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

        // Tags Filter - Individual sliver (this one can be large)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _IndividualTagsFilter(
              initialState: initialState,
              onHasChangesChanged: controller.updateHasChanges,
              onApplyChangesCallbackChanged: controller.updateApplyCallback,
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
  final RecipeFilterSortState initialState;
  final Function(bool) onHasChangesChanged;
  final Function(VoidCallback?) onApplyChangesCallbackChanged;

  const _IndividualCookTimeFilter({
    required this.initialState,
    required this.onHasChangesChanged,
    required this.onApplyChangesCallbackChanged,
  });

  @override
  ConsumerState<_IndividualCookTimeFilter> createState() => _IndividualCookTimeFilterState();
}

class _IndividualCookTimeFilterState extends ConsumerState<_IndividualCookTimeFilter> {
  late Set<CookTimeFilter> _selectedCookTimes;
  late Set<CookTimeFilter> _initialCookTimes;

  @override
  void initState() {
    super.initState();
    final existingCookTimeFilter = widget.initialState.activeFilters[FilterType.cookTime] as CookTimeMultiFilter?;
    _selectedCookTimes = existingCookTimeFilter?.selectedFilters.toSet() ?? {};
    _initialCookTimes = Set.from(_selectedCookTimes);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onApplyChangesCallbackChanged(_applyChanges);
    });
  }

  void _applyChanges() {
    // This will be handled by the main state management system
    // Individual filters just track their local changes
  }

  void _checkForChanges() {
    final hasChanges = !_setsEqual(_selectedCookTimes, _initialCookTimes);
    widget.onHasChangesChanged(hasChanges);
  }

  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    return set1.length == set2.length && set1.every((element) => set2.contains(element));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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
              final isSelected = _selectedCookTimes.contains(filter);
              return AppButton(
                text: filter.label,
                size: AppButtonSize.small,
                style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCookTimes.remove(filter);
                    } else {
                      _selectedCookTimes.add(filter);
                    }
                    _checkForChanges();
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Individual Rating Filter Widget
class _IndividualRatingFilter extends ConsumerStatefulWidget {
  final RecipeFilterSortState initialState;
  final Function(bool) onHasChangesChanged;
  final Function(VoidCallback?) onApplyChangesCallbackChanged;

  const _IndividualRatingFilter({
    required this.initialState,
    required this.onHasChangesChanged,
    required this.onApplyChangesCallbackChanged,
  });

  @override
  ConsumerState<_IndividualRatingFilter> createState() => _IndividualRatingFilterState();
}

class _IndividualRatingFilterState extends ConsumerState<_IndividualRatingFilter> {
  late Set<RatingFilter> _selectedRatings;
  late Set<RatingFilter> _initialRatings;

  @override
  void initState() {
    super.initState();
    final existingRatingFilter = widget.initialState.activeFilters[FilterType.rating] as RatingMultiFilter?;
    _selectedRatings = existingRatingFilter?.selectedRatings.toSet() ?? {};
    _initialRatings = Set.from(_selectedRatings);
  }

  void _checkForChanges() {
    final hasChanges = !_setsEqual(_selectedRatings, _initialRatings);
    widget.onHasChangesChanged(hasChanges);
  }

  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    return set1.length == set2.length && set1.every((element) => set2.contains(element));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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
              final isSelected = _selectedRatings.contains(filter);
              return AppButton(
                text: filter.stars,
                size: AppButtonSize.small,
                style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      _selectedRatings.remove(filter);
                    } else {
                      _selectedRatings.add(filter);
                    }
                    _checkForChanges();
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Individual Pantry Match Filter Widget
class _IndividualPantryMatchFilter extends ConsumerStatefulWidget {
  final RecipeFilterSortState initialState;
  final Function(bool) onHasChangesChanged;
  final Function(VoidCallback?) onApplyChangesCallbackChanged;

  const _IndividualPantryMatchFilter({
    required this.initialState,
    required this.onHasChangesChanged,
    required this.onApplyChangesCallbackChanged,
  });

  @override
  ConsumerState<_IndividualPantryMatchFilter> createState() => _IndividualPantryMatchFilterState();
}

class _IndividualPantryMatchFilterState extends ConsumerState<_IndividualPantryMatchFilter> {
  late double _pantryMatchPercentage;
  late double _initialPantryMatchPercentage;

  @override
  void initState() {
    super.initState();
    final existingPantryFilter = widget.initialState.activeFilters[FilterType.pantryMatch] as PantryMatchSliderFilter?;
    _pantryMatchPercentage = existingPantryFilter?.percentage ?? 0.0;
    _initialPantryMatchPercentage = _pantryMatchPercentage;
  }

  void _checkForChanges() {
    final hasChanges = _pantryMatchPercentage != _initialPantryMatchPercentage;
    widget.onHasChangesChanged(hasChanges);
  }

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
            value: _pantryMatchPercentage,
            min: 0.0,
            max: 1.0,
            divisions: 4,
            onChanged: (value) {
              setState(() {
                _pantryMatchPercentage = value;
                _checkForChanges();
              });
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            _getSliderLabel(_pantryMatchPercentage),
            style: AppTypography.body.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

// Individual Tags Filter Widget
class _IndividualTagsFilter extends ConsumerStatefulWidget {
  final RecipeFilterSortState initialState;
  final Function(bool) onHasChangesChanged;
  final Function(VoidCallback?) onApplyChangesCallbackChanged;

  const _IndividualTagsFilter({
    required this.initialState,
    required this.onHasChangesChanged,
    required this.onApplyChangesCallbackChanged,
  });

  @override
  ConsumerState<_IndividualTagsFilter> createState() => _IndividualTagsFilterState();
}

class _IndividualTagsFilterState extends ConsumerState<_IndividualTagsFilter> {
  late Set<String> _selectedTagIds;
  late Set<String> _initialTagIds;
  late TagFilterMode _tagFilterMode;
  late TagFilterMode _initialTagFilterMode;

  @override
  void initState() {
    super.initState();
    final existingTagFilter = widget.initialState.activeFilters[FilterType.tags] as TagFilter?;
    _selectedTagIds = existingTagFilter?.selectedTagIds.toSet() ?? {};
    _initialTagIds = Set.from(_selectedTagIds);
    _tagFilterMode = existingTagFilter?.mode ?? TagFilterMode.or;
    _initialTagFilterMode = _tagFilterMode;
  }

  void _checkForChanges() {
    final hasChanges = !_setsEqual(_selectedTagIds, _initialTagIds) ||
                      _tagFilterMode != _initialTagFilterMode;
    widget.onHasChangesChanged(hasChanges);
  }

  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    return set1.length == set2.length && set1.every((element) => set2.contains(element));
  }

  @override
  Widget build(BuildContext context) {
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
                      value: _tagFilterMode == TagFilterMode.and,
                      onChanged: (value) {
                        setState(() {
                          _tagFilterMode = value ? TagFilterMode.and : TagFilterMode.or;
                          _checkForChanges();
                        });
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
                        _checkForChanges();
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
            SizedBox(height: 200),
          ],
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Sort section widget
class _SortSection extends ConsumerStatefulWidget {
  final RecipeFilterSortState initialState;
  final _StickyButtonController controller;

  const _SortSection({
    required this.initialState,
    required this.controller,
  });

  @override
  ConsumerState<_SortSection> createState() => _SortSectionState();
}

class _SortSectionState extends ConsumerState<_SortSection> {
  late RecipeFilterSortState currentState;

  @override
  void initState() {
    super.initState();
    currentState = RecipeFilterSortState(
      activeFilters: Map<FilterType, dynamic>.from(widget.initialState.activeFilters),
      activeSortOption: widget.initialState.activeSortOption,
      sortDirection: widget.initialState.sortDirection,
      folderId: widget.initialState.folderId,
      searchQuery: widget.initialState.searchQuery,
    );
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
