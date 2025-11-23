import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../providers/recipe_folder_provider.dart';
import '../../../providers/recipe_tag_provider.dart';
import '../../../providers/smart_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../models/ingredient_term_search_result.dart';
import '../../../utils/term_search_utils.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

/// Show the smart folder creation modal
Future<String?> showAddSmartFolderModal(BuildContext context) {
  return WoltModalSheet.show<String>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      AddSmartFolderModalPage.build(context: bottomSheetContext),
    ],
  );
}

class AddSmartFolderModalPage {
  AddSmartFolderModalPage._();

  static SliverWoltModalSheetPage build({required BuildContext context}) {
    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      topBarTitle: ModalSheetTitle('New Smart Folder'),
      hasSabGradient: true,
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
          child: AddSmartFolderForm(),
        ),
      ],
    );
  }
}

class AddSmartFolderForm extends ConsumerStatefulWidget {
  const AddSmartFolderForm({super.key});

  @override
  ConsumerState<AddSmartFolderForm> createState() => _AddSmartFolderFormState();
}

class _AddSmartFolderFormState extends ConsumerState<AddSmartFolderForm> {
  int _selectedType = 0; // 0 = tags, 1 = ingredients
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _matchAll = false; // false = OR, true = AND
  bool _isCreating = false;

  // For tag-based folders
  final Set<String> _selectedTagNames = {};

  // For ingredient-based folders
  final List<String> _selectedTerms = [];
  bool _isSearching = false;
  bool _hasSearched = false; // Track if user has searched at least once

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canCreate {
    if (_nameController.text.trim().isEmpty) return false;
    if (_selectedType == 0) {
      return _selectedTagNames.isNotEmpty;
    } else {
      return _selectedTerms.isNotEmpty;
    }
  }

  Future<void> _createSmartFolder() async {
    if (!_canCreate || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final container = ProviderScope.containerOf(context);
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;

      await container.read(recipeFolderNotifierProvider.notifier).addSmartFolder(
        name: _nameController.text.trim(),
        folderType: _selectedType == 0 ? 1 : 2,
        filterLogic: _matchAll ? 1 : 0,
        tags: _selectedType == 0 ? _selectedTagNames.toList() : null,
        terms: _selectedType == 1 ? _selectedTerms : null,
        userId: userId,
      );

      if (mounted) {
        Navigator.of(context).pop(_nameController.text.trim());
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
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

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Folder name input
          AppTextFieldSimple(
            controller: _nameController,
            placeholder: 'Folder name',
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),

          SizedBox(height: AppSpacing.xl),

          // Type selector (Cupertino segmented control)
          Text(
            'Filter recipes by',
            style: AppTypography.label.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedType,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Tags'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Ingredients'),
                ),
              },
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // AND/OR toggle
          Row(
            children: [
              Text(
                'Match',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              SizedBox(width: AppSpacing.sm),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: _matchAll,
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() => _matchAll = value);
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
          if (_selectedType == 0)
            _buildTagSelection(colors)
          else
            _buildIngredientSelection(colors),

          SizedBox(height: AppSpacing.xl),

          // Create button
          AppButtonVariants.primaryFilled(
            text: 'Create Smart Folder',
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
            loading: _isCreating,
            onPressed: _canCreate ? _createSmartFolder : null,
          ),

          // Extra bottom padding for safe area
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
            // Use grouped list styling for tags
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

    // Determine if we should show the results container
    final showResultsContainer = _hasSearched || searchQuery.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected terms as pills (show above search if any selected)
        if (_selectedTerms.isNotEmpty) ...[
          Text(
            'Selected ingredients',
            style: AppTypography.label.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm),
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
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
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
                        color: colors.primary.withOpacity(0.6),
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
              child: _buildSearchResultsContent(colors, searchAsync, searchQuery),
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

    if (searchQuery.isEmpty) {
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
              'Type to search ingredients',
              style: AppTypography.body.copyWith(color: colors.textTertiary),
            ),
          ),
        ),
      );
    }

    if (searchAsync == null) {
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

        // Sort results by relevance
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
              final isFirst = index == 0;
              final isLast = index == sorted.length - 1;

              return _IngredientResultRow(
                term: result.term,
                recipeCount: result.recipeCount,
                isSelected: isAlreadySelected,
                isFirst: isFirst,
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

/// Tag selection row using grouped list styling
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
            // Color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: tagColorParsed,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Tag name
            Expanded(
              child: Text(
                tagName,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
            // Checkbox
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

/// Ingredient search result row using grouped list styling
class _IngredientResultRow extends StatelessWidget {
  final String term;
  final int recipeCount;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const _IngredientResultRow({
    required this.term,
    required this.recipeCount,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // For items inside a container that already has borders,
    // we only need separators between items (not full GroupedListStyling borders)
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
            // Term name and recipe count
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
            // Selection indicator
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
