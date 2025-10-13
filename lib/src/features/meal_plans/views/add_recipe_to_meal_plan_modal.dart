import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../database/database.dart';
import '../../../providers/recipe_provider.dart' as recipe_provider;
import '../../../providers/meal_plan_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/recipe_list_item.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';

void showAddRecipeToMealPlanModal(BuildContext context, String date) {
  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (modalContext) => [
      AddRecipeToMealPlanModalPage.build(
        context: modalContext,
        date: date,
      ),
    ],
  );
}

class AddRecipeToMealPlanModalPage {
  AddRecipeToMealPlanModalPage._();

  static SliverWoltModalSheetPage build({
    required BuildContext context,
    required String date,
  }) {
    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: CupertinoColors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      topBarTitle: const ModalSheetTitle('Add Recipe'),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      mainContentSliversBuilder: (context) => [
        SliverToBoxAdapter(
          child: AddRecipeToMealPlanContent(
            date: date,
            modalContext: context,
          ),
        ),
      ],
    );
  }
}

class AddRecipeToMealPlanContent extends ConsumerStatefulWidget {
  final String date;
  final BuildContext modalContext;

  const AddRecipeToMealPlanContent({
    super.key,
    required this.date,
    required this.modalContext,
  });

  @override
  ConsumerState<AddRecipeToMealPlanContent> createState() => _AddRecipeToMealPlanContentState();
}

class _AddRecipeToMealPlanContentState extends ConsumerState<AddRecipeToMealPlanContent> {
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
    // Add the selected recipe to meal plan
    ref.read(mealPlanNotifierProvider.notifier).addRecipe(
      date: widget.date,
      recipeId: recipe.id,
      recipeTitle: recipe.title,
      userId: null,
      householdId: null,
    ).then((_) {
      // Close the modal once added
      Navigator.of(widget.modalContext).pop();
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

        // Search results
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: searchState.results.isEmpty && !searchState.isLoading
              ? _buildEmptyState(context)
              : CustomScrollView(
                  slivers: [
                    SliverList.builder(
                      itemCount: searchState.results.length,
                      itemBuilder: (context, index) {
                        final recipe = searchState.results[index];
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
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
    );
  }
}
