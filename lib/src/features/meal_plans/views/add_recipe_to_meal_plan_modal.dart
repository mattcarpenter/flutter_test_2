import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../recipes/widgets/add_recipe_modal.dart';

/// Thin wrapper around shared add recipe modal for meal plan context
void showAddRecipeToMealPlanModal(BuildContext context, String date) {
  // Get access to ref for the callback
  final container = ProviderScope.containerOf(context);

  showAddRecipeModal(
    context,
    title: 'Add Recipe',
    onRecipeSelected: (RecipeEntry recipe) async {
      // Add the selected recipe to meal plan
      await container.read(mealPlanNotifierProvider.notifier).addRecipe(
        date: date,
        recipeId: recipe.id,
        recipeTitle: recipe.title,
        userId: null,
        householdId: null,
      );
    },
  );
}
