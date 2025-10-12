import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' as recipe_provider;
import 'package:recipe_app/src/providers/cook_provider.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../../database/database.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import 'cook_modal_search_results.dart';

void showAddRecipeSearchModal(BuildContext context, {required String cookId}) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.bottomSheet(),
    pageListBuilder: (modalContext) {
      return [
        WoltModalSheetPage(
          backgroundColor: AppColors.of(modalContext).background,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(modalContext).pop();
            },
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Recipe to Cook',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.of(modalContext).textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Flexible(
                  child: AddRecipeSearchContent(
                    cookId: cookId,
                    modalContext: modalContext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    },
    onModalDismissedWithBarrierTap: () {
      Navigator.of(context).pop();
    },
  );
}

class AddRecipeSearchContent extends ConsumerStatefulWidget {
  final String cookId;
  final BuildContext modalContext;

  const AddRecipeSearchContent({
    super.key,
    required this.cookId,
    required this.modalContext,
  });

  @override
  ConsumerState<AddRecipeSearchContent> createState() => _AddRecipeSearchContentState();
}

class _AddRecipeSearchContentState extends ConsumerState<AddRecipeSearchContent> {
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
    // Add the selected recipe to cook session
    final cookNotifier = ref.read(cookNotifierProvider.notifier);
    final userId = ref.read(userIdProvider);
    
    // Create a new cook for the selected recipe
    cookNotifier.startCook(
      recipeId: recipe.id,
      recipeName: recipe.title,
      userId: userId,
    ).then((_) {
      // Close the modal once selected
      Navigator.of(widget.modalContext).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(recipe_provider.cookModalRecipeSearchProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search box
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              onChanged: _onSearchChanged,
            ),

            const SizedBox(height: 20),

            // Search results
            Expanded(
              child: searchState.results.isEmpty && !searchState.isLoading
                  ? const Center(
                      child: Text('Search for recipes to add to your cook session'),
                    )
                  : CookModalSearchResults(
                      onResultSelected: _onRecipeSelected,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
