import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../../database/models/pantry_items.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/app_circle_button.dart';
import '../../models/pantry_filter_sort.dart';

/// Shows the unified pantry sort and filter bottom sheet
void showUnifiedPantrySortFilterSheet(
  BuildContext context, {
  required PantryFilterSortState initialState,
  required Function(PantryFilterSortState) onStateChanged,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) {
      return [
        _UnifiedPantrySortFilterModalPage.build(
          modalContext: modalContext,
          initialState: initialState,
          onStateChanged: onStateChanged,
        ),
      ];
    },
  );
}

class _UnifiedPantrySortFilterModalPage {
  _UnifiedPantrySortFilterModalPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext modalContext,
    required PantryFilterSortState initialState,
    required Function(PantryFilterSortState) onStateChanged,
  }) {
    final controller = _PantryFilterStateController(
      initialState: initialState,
      onStateChanged: onStateChanged,
    );

    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(modalContext).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      hasSabGradient: true,
      leadingNavBarWidget: TextButton(
        onPressed: () {
          controller.resetAll();
        },
        child: const Text('Reset All'),
      ),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(modalContext).pop(),
        ),
      ),
      stickyActionBar: Container(
        color: AppColors.of(modalContext).background,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return AppButton(
                text: 'Apply Changes',
                theme: AppButtonTheme.secondary,
                fullWidth: true,
                onPressed: controller.isButtonEnabled
                    ? () {
                        controller.applyChanges();
                        Navigator.of(modalContext).pop();
                      }
                    : null,
              );
            },
          ),
        ),
      ),
    mainContentSliversBuilder: (context) => [
      // Sort section
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: _SortSection(controller: controller),
        ),
      ),

      SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

      // Category section
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _CategoryFilterSection(controller: controller),
        ),
      ),

      SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

      // Stock status section
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _StockStatusFilterSection(controller: controller),
        ),
      ),

      SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

      // Show staples section
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _ShowStaplesSection(controller: controller),
        ),
      ),

      // Bottom padding for sticky action bar (ensures enough height for scrolling)
      SliverPadding(
        padding: EdgeInsets.only(bottom: AppSpacing.xxl * 4),
        sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
    ],
    );
  }
}

/// State controller for the pantry filter sheet
class _PantryFilterStateController extends ChangeNotifier {
  final PantryFilterSortState _initialState;
  final Function(PantryFilterSortState) onStateChanged;

  // Current filter states
  Set<String> _selectedCategories = {};
  Set<StockStatus> _selectedStockStatuses = {};
  bool _showStaples = true;
  PantrySortOption _sortOption = PantrySortOption.category;
  SortDirection _sortDirection = SortDirection.ascending;

  // Initial states for comparison
  final Set<String> _initialCategories;
  final Set<StockStatus> _initialStockStatuses;
  final bool _initialShowStaples;
  final PantrySortOption _initialSortOption;
  final SortDirection _initialSortDirection;

  _PantryFilterStateController({
    required PantryFilterSortState initialState,
    required this.onStateChanged,
  })  : _initialState = initialState,
        _initialCategories = Set<String>.from(
          initialState.activeFilters[PantryFilterType.category] as List<String>? ?? [],
        ),
        _initialStockStatuses = Set<StockStatus>.from(
          initialState.activeFilters[PantryFilterType.stockStatus] as List<StockStatus>? ?? [],
        ),
        _initialShowStaples = initialState.activeFilters[PantryFilterType.showStaples] as bool? ?? true,
        _initialSortOption = initialState.activeSortOption,
        _initialSortDirection = initialState.sortDirection {
    // Initialize current states from initial state
    _selectedCategories = Set<String>.from(_initialCategories);
    _selectedStockStatuses = Set<StockStatus>.from(_initialStockStatuses);
    _showStaples = _initialShowStaples;
    _sortOption = _initialSortOption;
    _sortDirection = _initialSortDirection;
  }

  // Getters
  Set<String> get selectedCategories => _selectedCategories;
  Set<StockStatus> get selectedStockStatuses => _selectedStockStatuses;
  bool get showStaples => _showStaples;
  PantrySortOption get sortOption => _sortOption;
  SortDirection get sortDirection => _sortDirection;

  // Change detection
  bool get hasChanges {
    return !_setEquals(_selectedCategories, _initialCategories) ||
        !_setEquals(_selectedStockStatuses, _initialStockStatuses) ||
        _showStaples != _initialShowStaples ||
        _sortOption != _initialSortOption ||
        _sortDirection != _initialSortDirection;
  }

  bool get isButtonEnabled => hasChanges;

  // Helper to compare sets
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }

  // Update methods
  void updateCategories(Set<String> categories) {
    _selectedCategories = categories;
    notifyListeners();
  }

  void updateStockStatuses(Set<StockStatus> statuses) {
    _selectedStockStatuses = statuses;
    notifyListeners();
  }

  void toggleShowStaples(bool value) {
    _showStaples = value;
    notifyListeners();
  }

  void updateSortOption(PantrySortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void updateSortDirection(SortDirection direction) {
    _sortDirection = direction;
    notifyListeners();
  }

  void resetAll() {
    _selectedCategories.clear();
    _selectedStockStatuses.clear();
    _showStaples = true;
    _sortOption = PantrySortOption.category;
    _sortDirection = SortDirection.ascending;
    notifyListeners();
  }

  void applyChanges() {
    var newState = _initialState.copyWith(
      activeSortOption: _sortOption,
      sortDirection: _sortDirection,
    );

    // Clear existing filters
    newState = newState.clearFilters();

    // Apply category filter if any selected
    if (_selectedCategories.isNotEmpty) {
      newState = newState.withFilter(
        PantryFilterType.category,
        _selectedCategories.toList(),
      );
    }

    // Apply stock status filter if any selected
    if (_selectedStockStatuses.isNotEmpty) {
      newState = newState.withFilter(
        PantryFilterType.stockStatus,
        _selectedStockStatuses.toList(),
      );
    }

    // Apply show staples filter (only if false)
    if (!_showStaples) {
      newState = newState.withFilter(
        PantryFilterType.showStaples,
        false,
      );
    }

    onStateChanged(newState);
  }
}

/// Sort section widget
class _SortSection extends StatelessWidget {
  final _PantryFilterStateController controller;

  const _SortSection({required this.controller});

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
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Row(
              children: [
                // Sort dropdown button
                Expanded(
                  child: AdaptivePullDownButton(
                    items: PantrySortOption.values.map((option) {
                      final isSelected = controller.sortOption == option;
                      return AdaptiveMenuItem(
                        title: _sortOptionLabel(option),
                        icon: Icon(
                          isSelected ? Icons.check_circle : Icons.sort,
                          size: 16,
                          color: isSelected ? colors.primary : colors.textSecondary,
                        ),
                        onTap: () {
                          controller.updateSortOption(option);
                        },
                      );
                    }).toList(),
                    child: AppButton(
                      text: 'Sort by ${_sortOptionLabel(controller.sortOption)}',
                      trailingIcon: const Icon(
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
                  ),
                ),

                SizedBox(width: AppSpacing.md),

                // Direction toggle button
                AppButton(
                  text: controller.sortDirection == SortDirection.ascending ? 'A-Z' : 'Z-A',
                  leadingIcon: Icon(
                    controller.sortDirection == SortDirection.ascending
                        ? Icons.north
                        : Icons.south,
                    size: 16,
                  ),
                  style: AppButtonStyle.mutedOutline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.medium,
                  theme: AppButtonTheme.primary,
                  onPressed: () {
                    controller.updateSortDirection(
                      controller.sortDirection == SortDirection.ascending
                          ? SortDirection.descending
                          : SortDirection.ascending,
                    );
                  },
                ),
              ],
            );
          },
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  String _sortOptionLabel(PantrySortOption option) {
    switch (option) {
      case PantrySortOption.category:
        return 'Category';
      case PantrySortOption.alphabetical:
        return 'Alphabetical';
      case PantrySortOption.dateAdded:
        return 'Date Added';
      case PantrySortOption.dateModified:
        return 'Date Modified';
      case PantrySortOption.stockStatus:
        return 'Stock Status';
    }
  }
}

/// Category filter section widget
class _CategoryFilterSection extends ConsumerWidget {
  final _PantryFilterStateController controller;

  const _CategoryFilterSection({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantryItemsAsyncValue = ref.watch(pantryItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTypography.h5.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        pantryItemsAsyncValue.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
          data: (pantryItems) {
            // Extract unique categories
            final categories = <String>{};
            for (final item in pantryItems) {
              categories.add(item.category ?? 'Other');
            }

            // Sort categories alphabetically, with "Other" last
            final sortedCategories = categories.toList()..sort((a, b) {
              if (a == 'Other') return 1;
              if (b == 'Other') return -1;
              return a.compareTo(b);
            });

            if (sortedCategories.isEmpty) {
              return Text(
                'No categories available',
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              );
            }

            return ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: sortedCategories.map((category) {
                    final isSelected = controller.selectedCategories.contains(category);
                    return _buildCategoryButton(context, category, isSelected);
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryButton(BuildContext context, String category, bool isSelected) {
    return AppButton(
      text: category,
      size: AppButtonSize.small,
      style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
      onPressed: () {
        final newCategories = Set<String>.from(controller.selectedCategories);
        if (isSelected) {
          newCategories.remove(category);
        } else {
          newCategories.add(category);
        }
        controller.updateCategories(newCategories);
      },
    );
  }
}

/// Stock status filter section widget
class _StockStatusFilterSection extends StatelessWidget {
  final _PantryFilterStateController controller;

  const _StockStatusFilterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Status',
          style: AppTypography.h5.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: StockStatus.values.map((status) {
                final isSelected = controller.selectedStockStatuses.contains(status);
                return _buildStockStatusButton(context, status, isSelected);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStockStatusButton(BuildContext context, StockStatus status, bool isSelected) {
    return AppButton(
      text: _stockStatusLabel(status),
      size: AppButtonSize.small,
      style: isSelected ? AppButtonStyle.fill : AppButtonStyle.mutedOutline,
      onPressed: () {
        final newStatuses = Set<StockStatus>.from(controller.selectedStockStatuses);
        if (isSelected) {
          newStatuses.remove(status);
        } else {
          newStatuses.add(status);
        }
        controller.updateStockStatuses(newStatuses);
      },
    );
  }

  String _stockStatusLabel(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.inStock:
        return 'In Stock';
    }
  }
}

/// Show staples section widget
class _ShowStaplesSection extends StatelessWidget {
  final _PantryFilterStateController controller;

  const _ShowStaplesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show Staples',
          style: AppTypography.h5.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.of(context).border,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  'Include staple items',
                  style: AppTypography.body.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                trailing: CupertinoSwitch(
                  value: controller.showStaples,
                  onChanged: (value) {
                    controller.toggleShowStaples(value);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
