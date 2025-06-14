import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../../database/database.dart';
import '../../../providers/recipe_provider.dart' as recipe_provider;
import '../../../providers/meal_plan_provider.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../widgets/meal_plan_recipe_search_results.dart';

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

  static WoltModalSheetPage build({
    required BuildContext context,
    required String date,
  }) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? CupertinoTheme.of(context).barBackgroundColor
        : CupertinoTheme.of(context).scaffoldBackgroundColor;

    return WoltModalSheetPage(
      backgroundColor: backgroundColor,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Add Recipe'),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: AddRecipeToMealPlanContent(
          date: date,
          modalContext: context,
        ),
      ),
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
      userId: null, // TODO: Pass actual user info
      householdId: null, // TODO: Pass actual household info
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Text(
            'Search for a recipe to add to your meal plan.',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),

          const SizedBox(height: 16),

          // Search box
          CupertinoSearchTextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            placeholder: 'Search recipes...',
            onChanged: _onSearchChanged,
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),

          const SizedBox(height: 20),

          // Search results
          Expanded(
            child: searchState.results.isEmpty && !searchState.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 48,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for recipes to add',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontSize: 16,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : MealPlanRecipeSearchResults(
                    onResultSelected: _onRecipeSelected,
                  ),
          ),
        ],
      ),
    );
  }
}