import 'package:uuid/uuid.dart';
import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../repositories/recipe_repository.dart';
import '../../../repositories/pantry_repository.dart';
import '../../../repositories/shopping_list_repository.dart';
import '../../../repositories/meal_plan_repository.dart';
import '../models/aggregated_ingredient.dart';

class MealPlanShoppingListService {
  final RecipeRepository recipeRepository;
  final PantryRepository pantryRepository;
  final ShoppingListRepository shoppingListRepository;
  final MealPlanRepository mealPlanRepository;

  MealPlanShoppingListService({
    required this.recipeRepository,
    required this.pantryRepository,
    required this.shoppingListRepository,
    required this.mealPlanRepository,
  });

  /// Aggregate ingredients from all recipes in a meal plan date
  Future<List<AggregatedIngredient>> getAggregatedIngredients({
    required String date,
    required String? userId,
    required String? householdId,
  }) async {
    // Get meal plan for the date
    final mealPlan = await mealPlanRepository.getMealPlanByDate(date, userId, householdId);
    if (mealPlan == null || mealPlan.items == null) {
      return [];
    }

    // Extract recipe IDs from meal plan items
    final recipeIds = <String>[];
    for (final item in mealPlan.items!) {
      if (item.isRecipe && item.recipeId != null) {
        recipeIds.add(item.recipeId!);
      }
    }

    if (recipeIds.isEmpty) {
      return [];
    }

    // Fetch all recipes
    final recipes = await recipeRepository.getRecipesByIds(recipeIds);

    // Aggregate ingredients by terms
    final aggregationMap = <String, _IngredientAggregation>{};
    
    for (final recipe in recipes) {
      if (recipe.ingredients == null) continue;
      
      for (final ingredient in recipe.ingredients!) {
        // Get terms for this ingredient
        final terms = _extractIngredientTerms(ingredient);
        if (terms.isEmpty) continue;
        
        // Create a key from sorted terms for consistent aggregation
        final termKey = terms.toList()..sort();
        final key = termKey.join('|');
        
        if (aggregationMap.containsKey(key)) {
          // Add to existing aggregation
          aggregationMap[key]!.addIngredient(ingredient, recipe);
        } else {
          // Create new aggregation
          aggregationMap[key] = _IngredientAggregation(
            name: ingredient.name,
            terms: terms,
          )..addIngredient(ingredient, recipe);
        }
      }
    }

    // Convert aggregations to AggregatedIngredient objects
    final aggregatedIngredients = <AggregatedIngredient>[];
    
    for (final aggregation in aggregationMap.values) {
      // Check pantry for matching items
      final pantryMatches = await pantryRepository.findItemsByTerms(aggregation.terms.toList());
      final matchingPantryItem = pantryMatches.isNotEmpty ? pantryMatches.first : null;
      
      // Check shopping lists for existing items
      final shoppingListMatches = await shoppingListRepository.findItemsByTerms(aggregation.terms.toList());
      final existsInShoppingList = shoppingListMatches.isNotEmpty;
      
      // Skip if already in shopping list
      if (existsInShoppingList) continue;
      
      // Determine if should be checked by default
      final isChecked = AggregatedIngredient.shouldBeCheckedByDefault(
        pantryItem: matchingPantryItem,
        existsInShoppingList: false, // We already filtered these out
      );
      
      aggregatedIngredients.add(AggregatedIngredient(
        id: const Uuid().v4(),
        name: aggregation.name,
        terms: aggregation.terms.toList(),
        sourceRecipeIds: aggregation.sourceRecipeIds.toList(),
        sourceRecipeTitles: aggregation.sourceRecipeTitles.toList(),
        matchingPantryItem: matchingPantryItem,
        existsInShoppingList: false,
        isChecked: isChecked,
      ));
    }

    // Sort: checked items first, then alphabetically by name
    aggregatedIngredients.sort((a, b) {
      if (a.isChecked != b.isChecked) {
        return a.isChecked ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    return aggregatedIngredients;
  }

  /// Extract terms from an ingredient
  Set<String> _extractIngredientTerms(Ingredient ingredient) {
    final terms = <String>{};
    
    // Add the ingredient name as a term
    terms.add(ingredient.name.toLowerCase().trim());
    
    // Add any additional terms from the ingredient
    if (ingredient.terms != null) {
      for (final term in ingredient.terms!) {
        terms.add(term.value.toLowerCase().trim());
      }
    }
    
    return terms;
  }
}

/// Helper class for aggregating ingredients
class _IngredientAggregation {
  final String name;
  final Set<String> terms;
  final Set<String> sourceRecipeIds = {};
  final Set<String> sourceRecipeTitles = {};

  _IngredientAggregation({
    required this.name,
    required this.terms,
  });

  void addIngredient(Ingredient ingredient, RecipeEntry recipe) {
    // Add recipe info
    sourceRecipeIds.add(recipe.id);
    sourceRecipeTitles.add(recipe.title);
  }
}