import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/recipe_repository.dart';
import '../../../repositories/pantry_repository.dart';
import '../../../providers/shopping_list_provider.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../providers/pantry_provider.dart';
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
  
  // Watch all shopping list items to refresh when items are added/removed
  // This ensures we refresh when user deletes items from shopping list
  final shoppingListsAsync = ref.watch(shoppingListsProvider);
  
  // Watch items for each shopping list to ensure we refresh when items change
  if (shoppingListsAsync.hasValue) {
    for (final list in shoppingListsAsync.value!) {
      ref.watch(shoppingListItemsProvider(list.id));
    }
  }
  
  // Also watch the default list (null ID)
  ref.watch(shoppingListItemsProvider(null));
  
  // Watch pantry items to refresh when pantry stock status changes
  // This is important to update the ingredient list when user updates pantry
  ref.watch(pantryItemsProvider);
  
  // TODO: Get actual user/household IDs
  return service.getAggregatedIngredients(
    date: date,
    userId: null,
    householdId: null,
  );
});