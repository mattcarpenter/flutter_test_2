import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../models/ingredient_term_search_result.dart';
import '../../../providers/recipe_folder_provider.dart';
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

/// Show the smart folder edit modal
Future<bool?> showEditSmartFolderModal(BuildContext context, RecipeFolderEntry folder) {
  return WoltModalSheet.show<bool>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      _EditSmartFolderPage.build(context: bottomSheetContext, folder: folder),
    ],
  );
}

class _EditSmartFolderPage {
  _EditSmartFolderPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext context,
    required RecipeFolderEntry folder,
  }) {
    final isTagBased = folder.folderType == 1;
    final title = isTagBased ? 'Edit Tags' : 'Edit Ingredients';

    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      topBarTitle: ModalSheetTitle(title),
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
        SliverToBoxAdapter(
          child: _EditSmartFolderContent(folder: folder),
        ),
      ],
    );
  }
}

class _EditSmartFolderContent extends ConsumerStatefulWidget {
  final RecipeFolderEntry folder;

  const _EditSmartFolderContent({required this.folder});

  @override
  ConsumerState<_EditSmartFolderContent> createState() => _EditSmartFolderContentState();
}

class _EditSmartFolderContentState extends ConsumerState<_EditSmartFolderContent> {
  final _searchController = TextEditingController();
  late bool _matchAll;
  bool _isSaving = false;
  bool _isSearching = false;
  bool _hasSearched = false;

  // For tag-based folders
  late Set<String> _selectedTagNames;

  // For ingredient-based folders
  late List<String> _selectedTerms;

  @override
  void initState() {
    super.initState();
    _matchAll = widget.folder.filterLogic == 1;

    // Initialize selected items based on folder type
    if (widget.folder.folderType == 1) {
      // Tag-based
      _selectedTagNames = widget.folder.smartFilterTags != null
          ? Set<String>.from((jsonDecode(widget.folder.smartFilterTags!) as List).cast<String>())
          : {};
      _selectedTerms = [];
    } else {
      // Ingredient-based
      _selectedTagNames = {};
      _selectedTerms = widget.folder.smartFilterTerms != null
          ? List<String>.from((jsonDecode(widget.folder.smartFilterTerms!) as List).cast<String>())
          : [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (widget.folder.folderType == 1) {
      return _selectedTagNames.isNotEmpty;
    } else {
      return _selectedTerms.isNotEmpty;
    }
  }

  Future<void> _saveChanges() async {
    if (!_canSave || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final container = ProviderScope.containerOf(context);

      await container.read(recipeFolderNotifierProvider.notifier).updateSmartFolderSettings(
        id: widget.folder.id,
        filterLogic: _matchAll ? 1 : 0,
        tags: widget.folder.folderType == 1 ? _selectedTagNames.toList() : null,
        terms: widget.folder.folderType == 2 ? _selectedTerms : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

  void _addTerm(String term) {
    if (!_selectedTerms.contains(term)) {
      setState(() {
        _selectedTerms.add(term);
        _searchController.clear();
        _hasSearched = false;
      });
    }
  }

  void _removeTerm(String term) {
    setState(() {
      _selectedTerms.remove(term);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isTagBased = widget.folder.folderType == 1;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Type-specific content (each has its own match toggle at bottom)
          if (isTagBased)
            _buildTagSelection(colors)
          else
            _buildIngredientSelection(colors),

          SizedBox(height: AppSpacing.xl),

          // Save button
          AppButtonVariants.primaryFilled(
            text: 'Save Changes',
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
            loading: _isSaving,
            onPressed: _canSave ? _saveChanges : null,
          ),

          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildTagSelection(AppColors colors) {
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
              'No tags available.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with subtext
            Text(
              'Matching Tags',
              style: AppTypography.h5.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Recipes with these tags will appear in this folder',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: AppSpacing.sm),
            ...tags.asMap().entries.map((entry) {
              final index = entry.key;
              final tag = entry.value;
              final isSelected = _selectedTagNames.contains(tag.name);
              final isFirst = index == 0;
              final isLast = index == tags.length - 1;

              return _TagSelectionRow(
                tagName: tag.name,
                tagColor: tag.color,
                isSelected: isSelected,
                isFirst: isFirst,
                isLast: isLast,
                onToggle: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTagNames.remove(tag.name);
                    } else {
                      _selectedTagNames.add(tag.name);
                    }
                  });
                },
              );
            }),

            SizedBox(height: AppSpacing.lg),

            // Match logic section with description
            Text(
              'Matching',
              style: AppTypography.h5.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _matchAll,
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() => _matchAll = value);
                    }
                  },
                  children: const {
                    false: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Any'),
                    ),
                    true: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('All'),
                    ),
                  },
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              _matchAll
                  ? 'Recipe must have every selected tag'
                  : 'Recipe must have at least one selected tag',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIngredientSelection(AppColors colors) {
    final searchQuery = _searchController.text.trim();
    final searchAsync = searchQuery.isNotEmpty
        ? ref.watch(ingredientTermSearchProvider(searchQuery))
        : null;

    final showResultsContainer = _hasSearched || searchQuery.isNotEmpty;
    final hasSelectedTerms = _selectedTerms.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with subtext
        Text(
          'Matching Ingredients',
          style: AppTypography.h5.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Recipes containing these ingredients will appear in this folder',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: AppSpacing.md),

        // Selected terms as chips
        if (hasSelectedTerms) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _selectedTerms.map((term) {
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
                      onTap: () => _removeTerm(term),
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
          SizedBox(height: AppSpacing.md),
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
              child: _buildSearchResultsContent(colors, searchAsync, searchQuery),
            ),
          ),
        ),

        SizedBox(height: AppSpacing.lg),

        // Match logic section with description
        Text(
          'Matching',
          style: AppTypography.h5.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            CupertinoSlidingSegmentedControl<bool>(
              groupValue: _matchAll,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() => _matchAll = value);
                }
              },
              children: const {
                false: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Any'),
                ),
                true: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('All'),
                ),
              },
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          _matchAll
              ? 'Recipe must contain every selected ingredient'
              : 'Recipe must contain at least one selected ingredient',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSearchResultsContent(
    AppColors colors,
    AsyncValue<List<IngredientTermSearchResult>>? searchAsync,
    String searchQuery,
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
              final isAlreadySelected = _selectedTerms.contains(result.term);
              final isLast = index == sorted.length - 1;

              return _IngredientResultRow(
                term: result.term,
                recipeCount: result.recipeCount,
                isSelected: isAlreadySelected,
                isLast: isLast,
                onTap: isAlreadySelected ? null : () => _addTerm(result.term),
              );
            },
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
            isSelected
                ? HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: colors.primary,
                    size: 22,
                  )
                : Icon(
                    CupertinoIcons.circle,
                    color: colors.textTertiary,
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
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: colors.primary,
                size: 22,
              )
            else
              HugeIcon(
                icon: HugeIcons.strokeRoundedAddCircle,
                color: colors.textTertiary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
