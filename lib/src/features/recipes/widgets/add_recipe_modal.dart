import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../database/database.dart';
import '../../../providers/recipe_provider.dart' as recipe_provider;
import '../../../providers/recently_viewed_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/recipe_list_item.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

/// Shared modal for adding recipes to different contexts (cook session, meal plan, etc.)
///
/// [title] - The title to show in the modal header
/// [onRecipeSelected] - Callback when a recipe is selected. Should return a Future that completes when done.
void showAddRecipeModal(
  BuildContext context, {
  required String title,
  required Future<void> Function(RecipeEntry recipe) onRecipeSelected,
}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      _AddRecipeModalPage.build(
        context: modalContext,
        title: title,
        onRecipeSelected: onRecipeSelected,
      ),
    ],
  );
}

class _AddRecipeModalPage {
  _AddRecipeModalPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext context,
    required String title,
    required Future<void> Function(RecipeEntry recipe) onRecipeSelected,
  }) {
    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: CupertinoColors.transparent,
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
          child: _AddRecipeContent(
            modalContext: context,
            onRecipeSelected: onRecipeSelected,
          ),
        ),
      ],
    );
  }
}

class _AddRecipeContent extends ConsumerStatefulWidget {
  final BuildContext modalContext;
  final Future<void> Function(RecipeEntry recipe) onRecipeSelected;

  const _AddRecipeContent({
    required this.modalContext,
    required this.onRecipeSelected,
  });

  @override
  ConsumerState<_AddRecipeContent> createState() => _AddRecipeContentState();
}

class _AddRecipeContentState extends ConsumerState<_AddRecipeContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Clear any previous search results and request focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset the search state to empty
      ref.read(recipe_provider.cookModalRecipeSearchProvider.notifier).search('');
      // Focus the search input
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(recipe_provider.cookModalRecipeSearchProvider.notifier).search(query);
  }

  void _onRecipeSelected(RecipeEntry recipe) {
    // Call the provided callback
    widget.onRecipeSelected(recipe).then((_) {
      // Close the modal once completed successfully
      if (widget.modalContext.mounted) {
        Navigator.of(widget.modalContext).pop();
      }
    }).catchError((error) {
      // Show error if something goes wrong
      _showError(error.toString());
    });
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text('Failed to add recipe: $message'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(recipe_provider.cookModalRecipeSearchProvider);
    final recentlyViewedAsync = ref.watch(recentlyViewedLimitedProvider(5));
    final hasSearchQuery = _searchController.text.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pinned search box
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: CupertinoSearchTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            placeholder: 'Search recipes...',
            onChanged: _onSearchChanged,
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
        ),

        // Scrollable content area with fixed height
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: CustomScrollView(
            slivers: [
              // Main content area (search results or empty states)
              if (!hasSearchQuery)
                _buildInitialState(context)
              else if (searchState.results.isEmpty && !searchState.isLoading)
                _buildNoResultsState(context)
              else if (searchState.isLoading)
                _buildLoadingState()
              else
                _buildSearchResults(searchState.results),

              // Recently viewed section (always at bottom if exists)
              ...recentlyViewedAsync.when(
                data: (recentlyViewedRecipes) {
                  if (recentlyViewedRecipes.isEmpty) {
                    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
                  }
                  return [
                    _buildRecentlyViewedSection(context, recentlyViewedRecipes),
                  ];
                },
                loading: () => [const SliverToBoxAdapter(child: SizedBox.shrink())],
                error: (_, __) => [const SliverToBoxAdapter(child: SizedBox.shrink())],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Initial state - no search query entered
  Widget _buildInitialState(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.search,
                size: 48,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Search for recipes to add',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // No results state - search query entered but no matches
  Widget _buildNoResultsState(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.doc_text_search,
                size: 48,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'No recipes found',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Try a different search term',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 14,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading state
  Widget _buildLoadingState() {
    return const SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
  }

  // Search results list
  Widget _buildSearchResults(List<RecipeEntry> results) {
    return SliverList.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final recipe = results[index];
        return RecipeListItem(
          recipe: recipe,
          onTap: null,
          trailing: AppButton(
            text: 'Add',
            onPressed: () => _onRecipeSelected(recipe),
            size: AppButtonSize.small,
            style: AppButtonStyle.outline,
            shape: AppButtonShape.square,
          ),
        );
      },
    );
  }

  // Recently viewed section
  Widget _buildRecentlyViewedSection(BuildContext context, List<RecipeEntry> recentlyViewedRecipes) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              'Recently Viewed',
              style: AppTypography.h2Serif.copyWith(
                color: AppColors.of(context).headingSecondary,
              ),
            ),
          ),
          // Recipe list
          ...recentlyViewedRecipes.map((recipe) {
            return RecipeListItem(
              recipe: recipe,
              onTap: null,
              trailing: AppButton(
                text: 'Add',
                onPressed: () => _onRecipeSelected(recipe),
                size: AppButtonSize.small,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.square,
              ),
            );
          }),
        ],
      ),
    );
  }
}
