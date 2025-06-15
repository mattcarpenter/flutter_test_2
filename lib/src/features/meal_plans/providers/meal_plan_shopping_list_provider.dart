import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/recipe_repository.dart';
import '../../../repositories/pantry_repository.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../providers/meal_plan_provider.dart';
import '../services/meal_plan_shopping_list_service.dart';
import '../models/aggregated_ingredient.dart';

final mealPlanShoppingListServiceProvider = Provider<MealPlanShoppingListService>((ref) {
  return MealPlanShoppingListService(
    recipeRepository: ref.watch(recipeRepositoryProvider),
    pantryRepository: ref.watch(pantryRepositoryProvider),
    shoppingListRepository: ref.watch(shoppingListRepositoryProvider),
    mealPlanRepository: ref.watch(mealPlanRepositoryProvider),
  );
});

final aggregatedIngredientsProvider = FutureProvider.family<List<AggregatedIngredient>, String>((ref, date) async {
  final service = ref.watch(mealPlanShoppingListServiceProvider);
  
  // TODO: Get actual user/household IDs
  return service.getAggregatedIngredients(
    date: date,
    userId: null,
    householdId: null,
  );
});