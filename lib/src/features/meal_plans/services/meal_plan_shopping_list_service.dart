import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../repositories/recipe_repository.dart';
import '../../../repositories/pantry_repository.dart';
import '../../../repositories/shopping_list_repository.dart';
import '../../../repositories/meal_plan_repository.dart';
import '../../../services/ingredient_parser_service.dart';
import '../models/aggregated_ingredient.dart';

class MealPlanShoppingListService {
  final RecipeRepository recipeRepository;
  final PantryRepository pantryRepository;
  final ShoppingListRepository shoppingListRepository;
  final MealPlanRepository mealPlanRepository;
  final IngredientParserService _parser = IngredientParserService();

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

    // Aggregate ingredients by overlapping terms
    // Use a list instead of map to allow overlap-based matching
    final aggregations = <_IngredientAggregation>[];

    for (final recipe in recipes) {
      if (recipe.ingredients == null) continue;

      for (final ingredient in recipe.ingredients!) {
        // Get canonicalized terms for this ingredient
        final terms = _extractIngredientTerms(ingredient);
        if (terms.isEmpty) continue;

        // Find existing aggregation with at least 1 overlapping term
        _IngredientAggregation? matchingAggregation;
        for (final agg in aggregations) {
          if (agg.hasOverlap(terms)) {
            matchingAggregation = agg;
            break;
          }
        }

        if (matchingAggregation != null) {
          // Add to existing aggregation
          matchingAggregation.addIngredient(ingredient, recipe, terms, this);
        } else {
          // Create new aggregation
          aggregations.add(_IngredientAggregation(
            name: ingredient.name,
            displayName: ingredient.displayName,
            terms: Set.from(terms),  // Create mutable copy
          )..addIngredient(ingredient, recipe, terms, this));
        }
      }
    }

    // Convert aggregations to AggregatedIngredient objects
    final aggregatedIngredients = <AggregatedIngredient>[];

    for (final aggregation in aggregations) {
      // Check pantry for matching items
      final pantryMatches = await pantryRepository.findItemsByTerms(aggregation.terms.toList());
      final matchingPantryItem = pantryMatches.isNotEmpty ? pantryMatches.first : null;

      // Check shopping lists for existing items
      final shoppingListMatches = await shoppingListRepository.findItemsByTerms(aggregation.terms.toList());
      final existsInShoppingList = shoppingListMatches.isNotEmpty;

      // Skip if already in shopping list
      if (existsInShoppingList) {
        continue;
      }

      // Determine if should be checked by default
      final isChecked = AggregatedIngredient.shouldBeCheckedByDefault(
        pantryItem: matchingPantryItem,
        existsInShoppingList: false, // We already filtered these out
      );

      aggregatedIngredients.add(AggregatedIngredient(
        id: _generateStableId(aggregation.terms),
        name: aggregation.name,
        displayName: aggregation.displayName,
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

  /// Generate a stable ID from terms for consistent identification across refetches
  String _generateStableId(Set<String> terms) {
    final sortedTerms = terms.toList()..sort();
    return sortedTerms.join('|');
  }

  /// Extract terms from an ingredient for matching purposes
  /// Primary: Cleaned ingredient name (stripped of quantities/units via parser)
  /// Secondary: All canonical terms (both user and API sources)
  Set<String> _extractIngredientTerms(Ingredient ingredient) {
    final terms = <String>{};

    // PRIMARY: Use parser to get cleaned ingredient name (strips quantities/units)
    final parseResult = _parser.parse(ingredient.name);
    final cleanedName = parseResult.cleanName.toLowerCase().trim();
    if (cleanedName.isNotEmpty) {
      terms.add(cleanedName);
    }

    // SECONDARY: Add ALL canonical terms (user + API) for additional matching
    if (ingredient.terms != null) {
      for (final term in ingredient.terms!) {
        final termValue = term.value.toLowerCase().trim();
        if (termValue.isNotEmpty) {
          terms.add(termValue);
        }
      }
    }

    // Fallback: if we still have no terms, use the raw ingredient name
    if (terms.isEmpty) {
      terms.add(ingredient.name.toLowerCase().trim());
    }

    return terms;
  }
}

/// Helper class for aggregating ingredients
class _IngredientAggregation {
  String name;  // Mutable to allow updating to better display name
  String? displayName;  // Clean name from canonicalization (if available)
  final Set<String> terms;
  final Set<String> sourceRecipeIds = {};
  final Set<String> sourceRecipeTitles = {};

  _IngredientAggregation({
    required this.name,
    this.displayName,
    required this.terms,
  });

  /// Check if this aggregation has at least 1 overlapping term with the given terms
  bool hasOverlap(Set<String> otherTerms) {
    return terms.any((term) => otherTerms.contains(term));
  }

  void addIngredient(Ingredient ingredient, RecipeEntry recipe, Set<String> ingredientTerms, MealPlanShoppingListService service) {
    // Add recipe info
    sourceRecipeIds.add(recipe.id);
    sourceRecipeTitles.add(recipe.title);

    // Merge the new terms into our term set for future matching
    terms.addAll(ingredientTerms);

    // Update display name if this ingredient has one and we don't,
    // or if this one is "better" (more specific)
    if (ingredient.displayName != null && ingredient.displayName!.isNotEmpty) {
      if (displayName == null || _isBetterDisplayName(ingredient.displayName!, displayName!, service)) {
        displayName = ingredient.displayName;
      }
    }

    // Update raw name if this one is better (more specific)
    if (_isBetterDisplayName(ingredient.name, name, service)) {
      name = ingredient.name;
    }
  }

  /// Determine if candidate is a better display name than current
  /// Prefers longer, more specific names after removing quantities
  bool _isBetterDisplayName(String candidate, String current, MealPlanShoppingListService service) {
    final candidateClean = service._parser.parse(candidate).cleanName;
    final currentClean = service._parser.parse(current).cleanName;

    // Prefer longer cleaned names (more specific)
    // e.g., "all-purpose flour" > "flour"
    return candidateClean.length > currentClean.length;
  }
}