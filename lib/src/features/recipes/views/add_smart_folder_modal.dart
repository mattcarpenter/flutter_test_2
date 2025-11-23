import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../models/ingredient_term_search_result.dart';
import '../../../providers/recipe_tag_provider.dart';
import '../../../providers/smart_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/term_search_utils.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/smart_folder_wizard_view_model.dart';

/// Show the smart folder creation wizard
Future<String?> showAddSmartFolderModal(BuildContext context) {
  return WoltModalSheet.show<String>(
    useRootNavigator: true,
    context: context,
    modalDecorator: (child) {
      return Consumer(
        builder: (context, ref, _) {
          return provider.ChangeNotifierProvider<SmartFolderWizardViewModel>(
            create: (_) => SmartFolderWizardViewModel(ref: ref),
            child: child,
          );
        },
      );
    },
    pageListBuilder: (bottomSheetContext) => [
      _TypeSelectionPage.build(context: bottomSheetContext),
      _ConfigurationPage.build(context: bottomSheetContext),
      _NamingPage.build(context: bottomSheetContext),
    ],
  );
}

// =============================================================================
// Page 1: Type Selection
// =============================================================================

class _TypeSelectionPage {
  _TypeSelectionPage._();

  static WoltModalSheetPage build({required BuildContext context}) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: const _TypeSelectionContent(),
    );
  }
}

class _TypeSelectionContent extends StatelessWidget {
  const _TypeSelectionContent();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'New Smart Folder',
            style: AppTypography.h4.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Smart folders automatically collect recipes based on your criteria.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xl),

          // Tags option card
          _TypeOptionCard(
            icon: CupertinoIcons.tag,
            title: 'By Tags',
            description: 'Group recipes that have specific tags like "Vegetarian" or "Quick Meals"',
            onTap: () {
              final viewModel = provider.Provider.of<SmartFolderWizardViewModel>(
                context,
                listen: false,
              );
              viewModel.setFolderType(1);
              WoltModalSheet.of(context).showNext();
            },
          ),

          SizedBox(height: AppSpacing.md),

          // Ingredients option card
          _TypeOptionCard(
            icon: CupertinoIcons.list_bullet,
            title: 'By Ingredients',
            description: 'Group recipes that contain specific ingredients like "chicken" or "pasta"',
            onTap: () {
              final viewModel = provider.Provider.of<SmartFolderWizardViewModel>(
                context,
                listen: false,
              );
              viewModel.setFolderType(2);
              WoltModalSheet.of(context).showNext();
            },
          ),

          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _TypeOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _TypeOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          border: Border.all(color: colors.groupedListBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: 24,
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: colors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Page 2: Configuration (Tags or Ingredients)
// =============================================================================

class _ConfigurationPage {
  _ConfigurationPage._();

  static SliverWoltModalSheetPage build({required BuildContext context}) {
    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      topBarTitle: const _ConfigurationPageTitle(),
      leadingNavBarWidget: Padding(
        padding: EdgeInsets.only(left: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.back,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () {
            WoltModalSheet.of(context).showPrevious();
          },
        ),
      ),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      mainContentSliversBuilder: (context) => [
        const SliverToBoxAdapter(
          child: _ConfigurationContent(),
        ),
      ],
    );
  }
}

class _ConfigurationPageTitle extends StatelessWidget {
  const _ConfigurationPageTitle();

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<SmartFolderWizardViewModel>(
      builder: (context, viewModel, _) {
        final title = viewModel.folderType == 1 ? 'Select Tags' : 'Select Ingredients';
        return ModalSheetTitle(title);
      },
    );
  }
}

class _ConfigurationContent extends ConsumerStatefulWidget {
  const _ConfigurationContent();

  @override
  ConsumerState<_ConfigurationContent> createState() => _ConfigurationContentState();
}

class _ConfigurationContentState extends ConsumerState<_ConfigurationContent> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTerms(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      await ref.read(ingredientTermSearchProvider(query).future);
      if (mounted) {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return provider.Consumer<SmartFolderWizardViewModel>(
      builder: (context, viewModel, _) {
        final isTagBased = viewModel.folderType == 1;

        return Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Match logic toggle
              Row(
                children: [
                  Text(
                    'Match',
                    style: AppTypography.body.copyWith(color: colors.textPrimary),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  CupertinoSlidingSegmentedControl<bool>(
                    groupValue: viewModel.matchAll,
                    onValueChanged: (value) {
                      if (value != null) {
                        viewModel.setMatchAll(value);
                      }
                    },
                    children: const {
                      false: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text('Any'),
                      ),
                      true: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text('All'),
                      ),
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.xl),

              // Type-specific content
              if (isTagBased)
                _buildTagSelection(colors, viewModel)
              else
                _buildIngredientSelection(colors, viewModel),

              SizedBox(height: AppSpacing.xl),

              // Next button
              AppButtonVariants.primaryFilled(
                text: 'Next',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                onPressed: viewModel.canProceedFromPage2
                    ? () => WoltModalSheet.of(context).showNext()
                    : null,
              ),

              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagSelection(AppColors colors, SmartFolderWizardViewModel viewModel) {
    final tagsAsync = ref.watch(recipeTagNotifierProvider);

    return tagsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Text('Error loading tags: $e'),
      data: (tags) {
        if (tags.isEmpty) {
          return Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No tags available. Create tags by editing a recipe.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select tags',
              style: AppTypography.label.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: AppSpacing.sm),
            ...tags.asMap().entries.map((entry) {
              final index = entry.key;
              final tag = entry.value;
              final isSelected = viewModel.isTagSelected(tag.name);
              final isFirst = index == 0;
              final isLast = index == tags.length - 1;

              return _TagSelectionRow(
                tagName: tag.name,
                tagColor: tag.color,
                isSelected: isSelected,
                isFirst: isFirst,
                isLast: isLast,
                onToggle: () => viewModel.toggleTag(tag.name),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildIngredientSelection(AppColors colors, SmartFolderWizardViewModel viewModel) {
    final searchQuery = _searchController.text.trim();
    final searchAsync = searchQuery.isNotEmpty
        ? ref.watch(ingredientTermSearchProvider(searchQuery))
        : null;

    final showResultsContainer = _hasSearched || searchQuery.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected terms as pills
        if (viewModel.selectedTerms.isNotEmpty) ...[
          Text(
            'Selected ingredients',
            style: AppTypography.label.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: viewModel.selectedTerms.map((term) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      term,
                      style: AppTypography.body.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => viewModel.removeTerm(term),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 18,
                        color: colors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.lg),
        ],

        // Search input
        AppTextFieldSimple(
          controller: _searchController,
          placeholder: 'Search ingredients...',
          onChanged: (query) => _searchTerms(query),
        ),

        SizedBox(height: AppSpacing.md),

        // Animated search results container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: showResultsContainer ? 200 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: showResultsContainer ? 1.0 : 0.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildSearchResultsContent(colors, searchAsync, searchQuery, viewModel),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsContent(
    AppColors colors,
    AsyncValue<List<IngredientTermSearchResult>>? searchAsync,
    String searchQuery,
    SmartFolderWizardViewModel viewModel,
  ) {
    if (_isSearching) {
      return Container(
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          border: Border.all(color: colors.groupedListBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (searchQuery.isEmpty || searchAsync == null) {
      return const SizedBox.shrink();
    }

    return searchAsync.when(
      loading: () => Container(
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          border: Border.all(color: colors.groupedListBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => Container(
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          border: Border.all(color: colors.groupedListBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('Error: $e')),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: colors.groupedListBackground,
              border: Border.all(color: colors.groupedListBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No ingredients found',
                  style: AppTypography.body.copyWith(color: colors.textSecondary),
                ),
              ),
            ),
          );
        }

        final sorted = TermSearchUtils.sortByRelevance(results, searchQuery);

        return Container(
          decoration: BoxDecoration(
            color: colors.groupedListBackground,
            border: Border.all(color: colors.groupedListBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final result = sorted[index];
              final isAlreadySelected = viewModel.isTermSelected(result.term);
              final isLast = index == sorted.length - 1;

              return _IngredientResultRow(
                term: result.term,
                recipeCount: result.recipeCount,
                isSelected: isAlreadySelected,
                isLast: isLast,
                onTap: isAlreadySelected
                    ? null
                    : () {
                        viewModel.addTerm(result.term);
                        _searchController.clear();
                        setState(() => _hasSearched = false);
                      },
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// Page 3: Naming
// =============================================================================

class _NamingPage {
  _NamingPage._();

  static WoltModalSheetPage build({required BuildContext context}) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      leadingNavBarWidget: Padding(
        padding: EdgeInsets.only(left: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.back,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () {
            WoltModalSheet.of(context).showPrevious();
          },
        ),
      ),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: const _NamingContent(),
    );
  }
}

class _NamingContent extends StatefulWidget {
  const _NamingContent();

  @override
  State<_NamingContent> createState() => _NamingContentState();
}

class _NamingContentState extends State<_NamingContent> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final viewModel = provider.Provider.of<SmartFolderWizardViewModel>(
      context,
      listen: false,
    );

    final result = await viewModel.createSmartFolder();
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return provider.Consumer<SmartFolderWizardViewModel>(
      builder: (context, viewModel, _) {
        // Build summary text
        final summaryParts = <String>[];
        if (viewModel.folderType == 1) {
          final count = viewModel.selectedTagNames.length;
          summaryParts.add('$count tag${count == 1 ? '' : 's'} selected');
        } else {
          final count = viewModel.selectedTerms.length;
          summaryParts.add('$count ingredient${count == 1 ? '' : 's'} selected');
        }
        summaryParts.add(viewModel.matchAll ? 'Match All' : 'Match Any');

        return Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Name Your Folder',
                style: AppTypography.h4.copyWith(color: colors.textPrimary),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                summaryParts.join(' \u2022 '),
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
              SizedBox(height: AppSpacing.xl),

              // Name input
              AppTextFieldSimple(
                controller: _nameController,
                placeholder: 'Folder name',
                autofocus: true,
                onChanged: (value) {
                  viewModel.setFolderName(value);
                },
              ),

              SizedBox(height: AppSpacing.xl),

              // Error message
              if (viewModel.errorMessage != null) ...[
                Text(
                  viewModel.errorMessage!,
                  style: AppTypography.body.copyWith(color: colors.error),
                ),
                SizedBox(height: AppSpacing.md),
              ],

              // Create button
              AppButtonVariants.primaryFilled(
                text: 'Create Smart Folder',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                loading: viewModel.isCreating,
                onPressed: viewModel.canCreate ? _createFolder : null,
              ),

              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================

class _TagSelectionRow extends StatelessWidget {
  final String tagName;
  final String tagColor;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onToggle;

  const _TagSelectionRow({
    required this.tagName,
    required this.tagColor,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Color tagColorParsed;
    try {
      tagColorParsed = Color(int.parse(tagColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      tagColorParsed = colors.primary;
    }

    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: colors.groupedListBackground,
          border: border,
          borderRadius: borderRadius,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: tagColorParsed,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                tagName,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? colors.primary : colors.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientResultRow extends StatelessWidget {
  final String term;
  final int recipeCount;
  final bool isSelected;
  final bool isLast;
  final VoidCallback? onTap;

  const _IngredientResultRow({
    required this.term,
    required this.recipeCount,
    required this.isSelected,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final showSeparator = !isLast;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: showSeparator
              ? Border(bottom: BorderSide(color: colors.groupedListBorder))
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    recipeCount == 1 ? '1 recipe' : '$recipeCount recipes',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: colors.primary,
                size: 22,
              )
            else
              Icon(
                CupertinoIcons.plus_circle,
                color: colors.textTertiary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
