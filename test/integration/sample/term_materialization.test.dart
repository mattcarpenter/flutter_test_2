import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/pantry_item_terms.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/powersync.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/ingredient_term_override_provider.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/test_utils.dart';
import '../../utils/test_user_manager.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Term Materialization Tests', () {
    setUpAll(() async {
      await loadEnvVars();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    setUp(() async {
      container = ProviderContainer();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    tearDown(() async {
      container.dispose();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    testWidgets('Recipe ingredients with terms are correctly materialized in recipe_ingredient_terms table', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final recipeId = const Uuid().v4();

        // Create a list of terms for an ingredient
        final onionTerms = [
          IngredientTerm(value: "onion", source: "ai", sort: 1),
          IngredientTerm(value: "yellow onion", source: "ai", sort: 2),
        ];

        final tomatoTerms = [
          IngredientTerm(value: "tomato", source: "ai", sort: 1),
          IngredientTerm(value: "roma tomato", source: "ai", sort: 2),
        ];

        // Create test ingredients with terms
        final ingredients = [
          Ingredient(
            id: "ing_1",
            type: "ingredient",
            name: "Diced Yellow Onion",
            note: "Medium sized",
            primaryAmount1Value: "1",
            primaryAmount1Unit: "whole",
            primaryAmount1Type: "count",
            terms: onionTerms,
          ),
          Ingredient(
            id: "ing_2",
            type: "ingredient",
            name: "Roma Tomatoes",
            note: "Diced",
            primaryAmount1Value: "2",
            primaryAmount1Unit: "whole",
            primaryAmount1Type: "count",
            terms: tomatoTerms,
          ),
        ];

        // Create a test step
        final testStep = Step(
          id: "step1",
          type: "step",
          text: "Mix the onions and tomatoes together.",
          note: null,
          timerDurationSeconds: null,
        );

        // Add a recipe with the ingredients and step
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: recipeId,
          title: "Onion and Tomato Salad",
          language: "en",
          description: "A simple salad",
          userId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          ingredients: ingredients,
          steps: [testStep],
        );

        // Wait for the recipe to be stored
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.any((r) => r.recipe.title == "Onion and Tomato Salad"),
        );

        // Allow some time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Query the materialized terms table directly to verify the terms were added
        final materializedTerms = await appDb.customSelect(
          '''
          SELECT * FROM recipe_ingredient_terms 
          WHERE recipe_id = ?
          ORDER BY ingredient_id, sort
          ''',
          variables: [Variable.withString(recipeId)],
        ).get();

        // Debug log
        print('Materialized terms: ${materializedTerms.map((e) => e.data).toList()}');

        // We should have 4 terms in total (2 for each ingredient)
        expect(materializedTerms.length, 4);

        // Verify onion terms
        final onionMaterializedTerms = materializedTerms
            .where((row) => row.read<String>('ingredient_id') == 'ing_1')
            .toList();
        expect(onionMaterializedTerms.length, 2);
        expect(onionMaterializedTerms[0].read<String>('term'), 'onion');
        expect(onionMaterializedTerms[1].read<String>('term'), 'yellow onion');

        // Verify tomato terms
        final tomatoMaterializedTerms = materializedTerms
            .where((row) => row.read<String>('ingredient_id') == 'ing_2')
            .toList();
        expect(tomatoMaterializedTerms.length, 2);
        expect(tomatoMaterializedTerms[0].read<String>('term'), 'tomato');
        expect(tomatoMaterializedTerms[1].read<String>('term'), 'roma tomato');

        // Now update a recipe to test the update trigger
        final List<Ingredient> updatedIngredients = List.from(ingredients);
        // Add a new term to the first ingredient
        updatedIngredients[0] = updatedIngredients[0].copyWith(
          terms: [
            ...onionTerms,
            IngredientTerm(value: "allium", source: "ai", sort: 3),
          ],
        );

        await container.read(recipeNotifierProvider.notifier).updateIngredients(
          recipeId: recipeId,
          ingredients: updatedIngredients,
        );

        // Allow time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Query the materialized terms table again
        final updatedMaterializedTerms = await appDb.customSelect(
          '''
          SELECT * FROM recipe_ingredient_terms 
          WHERE recipe_id = ? AND ingredient_id = 'ing_1'
          ORDER BY sort
          ''',
          variables: [Variable.withString(recipeId)],
        ).get();

        // We should now have 3 terms for the first ingredient
        expect(updatedMaterializedTerms.length, 3);
        expect(updatedMaterializedTerms[2].read<String>('term'), 'allium');
      });
    });

    testWidgets('Pantry items with terms are correctly materialized in pantry_item_terms table', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Create a list of terms for a pantry item
        final appleTerms = [
          PantryItemTerm(value: "apple", source: "user", sort: 1),
          PantryItemTerm(value: "granny smith", source: "user", sort: 2),
        ];

        // Add a pantry item with terms
        final pantryItemId = await container.read(pantryItemsProvider.notifier).addItem(
          name: "Granny Smith Apples",
          inStock: true,
          userId: userId,
        );

        // Wait for the pantry item to be stored
        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
          (items) => items.any((item) => item.name == "Granny Smith Apples"),
        );

        // Update the pantry item to add terms
        await appDb.update(appDb.pantryItems).replace(
          PantryItemsCompanion(
            id: Value(pantryItemId),
            name: const Value("Granny Smith Apples"),
            inStock: const Value(true),
            userId: Value(userId),
            terms: Value(appleTerms),
          ),
        );

        // Allow some time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Query the materialized terms table directly to verify the terms were added
        final materializedTerms = await appDb.customSelect(
          '''
          SELECT * FROM pantry_item_terms 
          WHERE pantry_item_id = ?
          ORDER BY sort
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).get();

        // Debug log
        print('Pantry item materialized terms: ${materializedTerms.map((e) => e.data).toList()}');

        // We should have 2 terms in total
        expect(materializedTerms.length, 2);
        expect(materializedTerms[0].read<String>('term'), 'apple');
        expect(materializedTerms[1].read<String>('term'), 'granny smith');

        // Now update the pantry item to test the update trigger
        final updatedTerms = [
          ...appleTerms,
          PantryItemTerm(value: "fruit", source: "user", sort: 3),
        ];

        await appDb.update(appDb.pantryItems).replace(
          PantryItemsCompanion(
            id: Value(pantryItemId),
            name: const Value("Granny Smith Apples"),
            inStock: const Value(true),
            userId: Value(userId),
            terms: Value(updatedTerms),
          ),
        );

        // Allow time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Query the materialized terms table again
        final updatedMaterializedTerms = await appDb.customSelect(
          '''
          SELECT * FROM pantry_item_terms 
          WHERE pantry_item_id = ?
          ORDER BY sort
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).get();

        // We should now have 3 terms
        expect(updatedMaterializedTerms.length, 3);
        expect(updatedMaterializedTerms[2].read<String>('term'), 'fruit');
      });
    });

    testWidgets('Ingredient term overrides are correctly materialized in ingredient_term_overrides_flattened table', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        final notifier = container.read(
          ingredientTermOverrideNotifierProvider.notifier,
        );

        const inputTerm = "margarine";
        const mappedTerm = "butter";

        // Add an override
        await notifier.addOverride(
          inputTerm: inputTerm,
          mappedTerm: mappedTerm,
          userId: userId,
        );

        // Wait for the override to be stored
        final overrides = await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
          (overrides) => overrides.any((o) => o.inputTerm == inputTerm),
        );

        final overrideId = overrides.firstWhere((o) => o.inputTerm == inputTerm).id;

        // Allow some time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Query the materialized overrides table directly to verify the override was added
        final materializedOverrides = await appDb.customSelect(
          '''
          SELECT * FROM ingredient_term_overrides_flattened 
          WHERE id = ?
          ''',
          variables: [Variable.withString(overrideId)],
        ).get();

        // Debug log
        print('Override materialized: ${materializedOverrides.map((e) => e.data).toList()}');

        // We should have 1 override
        expect(materializedOverrides.length, 1);
        expect(materializedOverrides[0].read<String>('input_term'), 'margarine');
        expect(materializedOverrides[0].read<String>('mapped_term'), 'butter');
        expect(materializedOverrides[0].read<String>('user_id'), userId);

        // Test deletion of override
        await notifier.deleteOverrideById(overrideId);

        // Allow time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Query the materialized overrides table again
        final afterDeleteOverrides = await appDb.customSelect(
          '''
          SELECT * FROM ingredient_term_overrides_flattened 
          WHERE id = ?
          ''',
          variables: [Variable.withString(overrideId)],
        ).get();

        // The override should still exist but have deleted_at set
        expect(afterDeleteOverrides.length, 1);
        expect(afterDeleteOverrides[0].read<int?>('deleted_at'), isNotNull);
      });
    });

    testWidgets('Recipe ingredient terms can be matched with pantry item terms', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final recipeId = const Uuid().v4();

        // 1. Create a recipe with an ingredient that has terms
        final onionTerms = [
          IngredientTerm(value: "onion", source: "ai", sort: 1),
          IngredientTerm(value: "yellow onion", source: "ai", sort: 2),
        ];

        final ingredients = [
          Ingredient(
            id: "ing_1",
            type: "ingredient",
            name: "Diced Yellow Onion",
            note: "Medium sized",
            primaryAmount1Value: "1",
            primaryAmount1Unit: "whole",
            primaryAmount1Type: "count",
            terms: onionTerms,
          ),
        ];

        // Add the recipe
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: recipeId,
          title: "Onion Recipe",
          language: "en",
          description: "A recipe with onion",
          userId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          ingredients: ingredients,
        );

        // Wait for the recipe to be stored
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.any((r) => r.recipe.title == "Onion Recipe"),
        );

        // 2. Create a pantry item with a matching term
        final pantryTerms = [
          PantryItemTerm(value: "onion", source: "user", sort: 1),
        ];

        final pantryItemId = await container.read(pantryItemsProvider.notifier).addItem(
          name: "Onions",
          inStock: true,
          userId: userId,
        );

        // Update the pantry item to add terms
        await appDb.update(appDb.pantryItems).replace(
          PantryItemsCompanion(
            id: Value(pantryItemId),
            name: const Value("Onions"),
            inStock: const Value(true),
            userId: Value(userId),
            terms: Value(pantryTerms),
          ),
        );

        // Allow some time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // 3. Perform a query to find recipes that have ingredients matching the pantry items
        final matchingRecipes = await appDb.customSelect(
          '''
          SELECT DISTINCT r.id, r.data 
          FROM recipes r
          JOIN recipe_ingredient_terms rit ON r.id = rit.recipe_id
          JOIN pantry_item_terms pit ON rit.term = pit.term
          WHERE pit.pantry_item_id = ?
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).get();

        // We should find our recipe
        expect(matchingRecipes.length, 1);
        final matchingRecipeId = matchingRecipes[0].read<String>('id');
        expect(matchingRecipeId, recipeId);

        // 4. Test with an ingredient term override
        // First, add a term override that maps "shallot" to "onion"
        await container.read(ingredientTermOverrideNotifierProvider.notifier).addOverride(
          inputTerm: "shallot",
          mappedTerm: "onion",
          userId: userId,
        );

        // Wait for the override to be stored
        await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
          (overrides) => overrides.any((o) => o.inputTerm == "shallot"),
        );

        // Allow time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Create a new recipe with a shallot ingredient that has "shallot" as a term
        final recipeId2 = const Uuid().v4();
        final shallotTerms = [
          IngredientTerm(value: "shallot", source: "ai", sort: 1),
        ];

        final shallotIngredients = [
          Ingredient(
            id: "ing_1",
            type: "ingredient",
            name: "Diced Shallot",
            note: "Finely chopped",
            primaryAmount1Value: "2",
            primaryAmount1Unit: "whole",
            primaryAmount1Type: "count",
            terms: shallotTerms,
          ),
        ];

        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: recipeId2,
          title: "Shallot Recipe",
          language: "en",
          description: "A recipe with shallot",
          userId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          ingredients: shallotIngredients,
        );

        // Wait for the recipe to be stored
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.any((r) => r.recipe.title == "Shallot Recipe"),
        );

        // Allow time for triggers to execute
        await Future.delayed(const Duration(seconds: 1));

        // Query for recipes that match with pantry items, now using the term override
        final matchingRecipesWithOverride = await appDb.customSelect(
          '''
          SELECT DISTINCT r.id, r.data 
          FROM recipes r
          JOIN recipe_ingredient_terms rit ON r.id = rit.recipe_id
          LEFT JOIN ingredient_term_overrides_flattened ito ON rit.term = ito.input_term AND ito.deleted_at IS NULL
          JOIN pantry_item_terms pit ON 
            (ito.mapped_term IS NOT NULL AND ito.mapped_term = pit.term) OR
            (ito.mapped_term IS NULL AND rit.term = pit.term)
          WHERE pit.pantry_item_id = ?
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).get();

        // Now we should find both recipes
        expect(matchingRecipesWithOverride.length, 2);
        final matchingIds = matchingRecipesWithOverride.map((row) => row.read<String>('id')).toList();
        expect(matchingIds.contains(recipeId), true);
        expect(matchingIds.contains(recipeId2), true);
      });
    });
  });
}
