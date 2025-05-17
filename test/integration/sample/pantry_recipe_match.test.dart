import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/pantry_item_terms.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:recipe_app/src/managers/ingredient_term_queue_manager.dart';
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';
import 'package:recipe_app/src/models/recipe_pantry_match.dart';
import 'package:recipe_app/src/providers/ingredient_term_override_provider.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/repositories/ingredient_term_queue_repository.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity_status');

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Pantry Recipe Matching Tests', () {
    setUpAll(() async {
      await loadEnvVars();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    setUp(() async {
      container = ProviderContainer();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'listen') {
          return null;
        }
        return null;
      });
    });

    tearDown(() async {
      container.dispose();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    // Helper function to create a test recipe with ingredients and terms
    Future<String> createTestRecipe({
      required String title,
      required List<Map<String, dynamic>> ingredients,
      List<String>? steps,
    }) async {
      final recipeRepository = container.read(recipeRepositoryProvider);
      final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);

      // Enable test mode
      ingredientTermManager.testMode = true;

      // Connect repositories and managers
      ingredientTermManager.recipeRepository = recipeRepository;
      recipeRepository.ingredientTermQueueManager = ingredientTermManager;

      final recipeId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Convert ingredient maps to actual ingredients with terms
      final ingredientObjects = ingredients.map((ing) {
        final id = const Uuid().v4();
        return Ingredient(
          id: id,
          type: 'ingredient',
          name: ing['name'],
          primaryAmount1Value: ing['amount']?.toString(),
          primaryAmount1Unit: ing['unit'],
          terms: (ing['terms'] as List<String>).asMap().entries.map((entry) {
            return IngredientTerm(
              value: entry.value,
              source: 'test',
              sort: entry.key,
            );
          }).toList(),
        );
      }).toList();

      // Convert steps to Step objects
      final stepObjects = (steps ?? []).asMap().entries.map((entry) {
        return Step(
          id: const Uuid().v4(),
          type: 'step',
          text: entry.value,
        );
      }).toList();

      // Create the recipe
      await recipeRepository.addRecipe(
        RecipesCompanion.insert(
          id: Value(recipeId),
          title: title,
          description: const Value('Test recipe'),
          language: const Value('en'),
          userId: Value(userId),
          createdAt: Value(now),
          updatedAt: Value(now),
          ingredients: Value(ingredientObjects),
          steps: Value(stepObjects),
          folderIds: const Value([]),
          images: const Value([]),
        ),
      );

      return recipeId;
    }

    // Helper function to create a pantry item with terms
    Future<String> createPantryItem({
      required String name,
      required List<String> terms,
    }) async {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Create pantry item terms
      final pantryItemTerms = terms.asMap().entries.map((entry) {
        return PantryItemTerm(
          value: entry.value,
          source: 'test',
          sort: entry.key,
        );
      }).toList();

      // Add pantry item
      final itemId = await container.read(pantryNotifierProvider.notifier).addItem(
        name: name,
        userId: userId,
        terms: pantryItemTerms,
      );

      return itemId;
    }

    testWidgets('Perfect match - recipe with all ingredients in pantry', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('pantry_match_tester');

      await withTestUser('pantry_match_tester', () async {
        // Enable test mode for the ingredient term queue manager
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;
        // Create a recipe with ingredients that will match pantry
        final recipeId = await createTestRecipe(
          title: 'Perfect Match Recipe',
          ingredients: [
            {
              'name': 'Onion',
              'amount': '1',
              'unit': 'whole',
              'terms': ['onion', 'onions'],
            },
            {
              'name': 'Garlic',
              'amount': '2',
              'unit': 'cloves',
              'terms': ['garlic', 'garlic cloves'],
            },
            {
              'name': 'Olive Oil',
              'amount': '1',
              'unit': 'tablespoon',
              'terms': ['olive oil', 'oil'],
            },
          ],
          steps: ['Chop onion and garlic', 'Sauté in olive oil'],
        );

        // Create pantry items with matching terms
        await createPantryItem(name: 'Onions', terms: ['onion', 'onions']);
        await createPantryItem(name: 'Garlic', terms: ['garlic']);
        await createPantryItem(name: 'Olive Oil', terms: ['olive oil', 'oil']);

        // Find matching recipes
        await container.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();

        // Verify results
        final matchState = container.read(pantryRecipeMatchProvider).value!;
        expect(matchState.matches.length, 1);
        expect(matchState.matches[0].recipe.id, recipeId);
        expect(matchState.matches[0].matchRatio, 1.0);  // 100% match
        expect(matchState.matches[0].isPerfectMatch, true);
      });
    });

    testWidgets('Partial match - recipe with some ingredients in pantry', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('pantry_match_tester');

      await withTestUser('pantry_match_tester', () async {
        // Enable test mode for the ingredient term queue manager
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;
        // Create a recipe with ingredients that will partially match pantry
        final recipeId = await createTestRecipe(
          title: 'Partial Match Recipe',
          ingredients: [
            {
              'name': 'Chicken',
              'amount': '500',
              'unit': 'g',
              'terms': ['chicken', 'chicken breast'],
            },
            {
              'name': 'Rice',
              'amount': '1',
              'unit': 'cup',
              'terms': ['rice', 'white rice'],
            },
            {
              'name': 'Broccoli',
              'amount': '1',
              'unit': 'head',
              'terms': ['broccoli'],
            },
            {
              'name': 'Soy Sauce',
              'amount': '2',
              'unit': 'tablespoons',
              'terms': ['soy sauce'],
            },
          ],
        );

        // Create pantry items with matching terms - only 2 out of 4 ingredients
        await createPantryItem(name: 'Chicken Breast', terms: ['chicken', 'chicken breast']);
        await createPantryItem(name: 'Rice', terms: ['rice', 'white rice']);

        // Find matching recipes
        await container.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();

        // Verify results
        final matchState = container.read(pantryRecipeMatchProvider).value!;
        expect(matchState.matches.length, 1);
        expect(matchState.matches[0].recipe.id, recipeId);
        expect(matchState.matches[0].matchedTerms, 2);  // 2 ingredients matched
        expect(matchState.matches[0].totalTerms, 4);    // out of 4 total
        expect(matchState.matches[0].matchRatio, 0.5);  // 50% match
        expect(matchState.matches[0].isPerfectMatch, false);
      });
    });

    testWidgets('Multiple recipes with different match ratios', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('pantry_match_tester');

      await withTestUser('pantry_match_tester', () async {
        // Enable test mode for the ingredient term queue manager
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;
        // Create three recipes with different ingredients
        final highMatchRecipeId = await createTestRecipe(
          title: 'High Match Recipe',
          ingredients: [
            {'name': 'Tomato', 'terms': ['tomato', 'tomatoes']},
            {'name': 'Mozzarella', 'terms': ['mozzarella', 'cheese']},
            {'name': 'Basil', 'terms': ['basil', 'fresh basil']},
          ],
        );

        final mediumMatchRecipeId = await createTestRecipe(
          title: 'Medium Match Recipe',
          ingredients: [
            {'name': 'Ground Beef', 'terms': ['ground beef', 'beef']},
            {'name': 'Tomato', 'terms': ['tomato', 'tomatoes']},
            {'name': 'Onion', 'terms': ['onion']},
            {'name': 'Garlic', 'terms': ['garlic']},
            {'name': 'Pasta', 'terms': ['pasta', 'spaghetti']},
          ],
        );

        final lowMatchRecipeId = await createTestRecipe(
          title: 'Low Match Recipe',
          ingredients: [
            {'name': 'Salmon', 'terms': ['salmon', 'fish']},
            {'name': 'Lemon', 'terms': ['lemon']},
            {'name': 'Dill', 'terms': ['dill', 'fresh dill']},
            {'name': 'Capers', 'terms': ['capers']},
            {'name': 'Butter', 'terms': ['butter']},
          ],
        );

        // Create pantry items that will match with different ratios
        await createPantryItem(name: 'Tomatoes', terms: ['tomato', 'tomatoes']);
        await createPantryItem(name: 'Mozzarella Cheese', terms: ['mozzarella', 'cheese']);
        await createPantryItem(name: 'Basil', terms: ['basil']);
        await createPantryItem(name: 'Ground Beef', terms: ['ground beef', 'beef']);
        await createPantryItem(name: 'Garlic', terms: ['garlic']);
        await createPantryItem(name: 'Salmon', terms: ['salmon']);

        // Find matching recipes
        await container.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();

        // Verify results
        final matchState = container.read(pantryRecipeMatchProvider).value!;
        expect(matchState.matches.length, 3);

        // First should be high match recipe (100%)
        expect(matchState.matches[0].recipe.id, highMatchRecipeId);
        expect(matchState.matches[0].matchRatio, 1.0);

        // Second should be medium match recipe (60%)
        expect(matchState.matches[1].recipe.id, mediumMatchRecipeId);
        expect(matchState.matches[1].matchRatio, closeTo(0.6, 0.01));
        expect(matchState.matches[1].matchedTerms, 3); // Ground Beef, Tomato, Garlic
        expect(matchState.matches[1].totalTerms, 5);   // out of 5 ingredients

        // Third should be low match recipe (20%)
        expect(matchState.matches[2].recipe.id, lowMatchRecipeId);
        expect(matchState.matches[2].matchRatio, closeTo(0.2, 0.01));
      });
    });

    testWidgets('No matching recipes when pantry is empty', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('pantry_match_tester');

      await withTestUser('pantry_match_tester', () async {
        // Enable test mode for the ingredient term queue manager
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;
        // Create a recipe
        await createTestRecipe(
          title: 'No Match Recipe',
          ingredients: [
            {'name': 'Sugar', 'terms': ['sugar', 'granulated sugar']},
            {'name': 'Flour', 'terms': ['flour', 'all-purpose flour']},
            {'name': 'Eggs', 'terms': ['eggs', 'egg']},
          ],
        );

        // Don't add any pantry items

        // Find matching recipes
        await container.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();

        // Verify results - should be empty
        final matchState = container.read(pantryRecipeMatchProvider).value!;
        expect(matchState.matches.length, 0);
      });
    });

    testWidgets('Ingredient term overrides are respected in matching', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('pantry_match_tester');

      await withTestUser('pantry_match_tester', () async {
        // Enable test mode for the ingredient term queue manager
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;
        // Create a recipe with an ingredient that needs an override
        final recipeId = await createTestRecipe(
          title: 'Override Match Recipe',
          ingredients: [
            {
              'name': 'Spring Onion',
              'terms': ['spring onion', 'green onion', 'scallion'],
            },
          ],
        );

        // Add a pantry item with the overridden term
        await createPantryItem(name: 'Green Onions', terms: ['green onion']);

        // Add an override using the proper provider
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final notifier = container.read(ingredientTermOverrideNotifierProvider.notifier);

        const inputTerm = 'spring onion';
        const mappedTerm = 'green onion';

        await notifier.addOverride(
          inputTerm: inputTerm,
          mappedTerm: mappedTerm,
          userId: userId,
        );

        // Wait for the override to be created
        await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
          (overrides) => overrides.any((o) => o.inputTerm == inputTerm),
        );

        // Find matching recipes
        await container.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();

        // Verify results - should match due to the override
        final matchState = container.read(pantryRecipeMatchProvider).value!;
        expect(matchState.matches.length, 1);
        expect(matchState.matches[0].recipe.id, recipeId);
        expect(matchState.matches[0].isPerfectMatch, true);
      });
    });
    
    testWidgets('Find pantry matches for recipe ingredients', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('pantry_match_tester');

      await withTestUser('pantry_match_tester', () async {
        // Enable test mode for the ingredient term queue manager
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;
        
        // Create a recipe with ingredients - some will match, some won't
        final recipeId = await createTestRecipe(
          title: 'Mixed Match Recipe',
          ingredients: [
            {
              'name': 'Chicken',
              'amount': '500',
              'unit': 'g',
              'terms': ['chicken', 'chicken breast'],
            },
            {
              'name': 'Rice',
              'amount': '1',
              'unit': 'cup',
              'terms': ['rice', 'white rice'],
            },
            {
              'name': 'Broccoli',
              'amount': '1',
              'unit': 'head',
              'terms': ['broccoli'],
            },
          ],
        );

        // Create pantry items - only match 2 out of 3 ingredients
        final chickenPantryId = await createPantryItem(
          name: 'Chicken Breast', 
          terms: ['chicken', 'chicken breast']
        );
        final ricePantryId = await createPantryItem(
          name: 'White Rice', 
          terms: ['rice', 'white rice']
        );
        
        // Use the repository directly instead of the provider to avoid async disposal issues
        final repository = container.read(recipeRepositoryProvider);
        final matchResult = await repository.findPantryMatchesForRecipe(recipeId);
        
        // Verify basic results
        expect(matchResult.recipeId, recipeId);
        expect(matchResult.matches.length, 3); // Should have 3 ingredients
        expect(matchResult.matchRatio, closeTo(2/3, 0.01)); // 2 out of 3 match
        expect(matchResult.hasAllIngredients, false); // Not all ingredients match
        
        // Verify each ingredient match
        final chickenMatch = matchResult.matches.firstWhere(
          (m) => m.ingredient.name == 'Chicken'
        );
        expect(chickenMatch.hasMatch, true);
        expect(chickenMatch.pantryItem!.id, chickenPantryId);
        expect(chickenMatch.pantryItem!.name, 'Chicken Breast');
        
        final riceMatch = matchResult.matches.firstWhere(
          (m) => m.ingredient.name == 'Rice'
        );
        expect(riceMatch.hasMatch, true);
        expect(riceMatch.pantryItem!.id, ricePantryId);
        expect(riceMatch.pantryItem!.name, 'White Rice');
        
        final broccoliMatch = matchResult.matches.firstWhere(
          (m) => m.ingredient.name == 'Broccoli'
        );
        expect(broccoliMatch.hasMatch, false);
        expect(broccoliMatch.pantryItem, null);
        
        // Verify missing ingredients
        expect(matchResult.missingIngredients.length, 1);
        expect(matchResult.missingIngredients[0].name, 'Broccoli');
      });
    });
    
    testWidgets('Find pantry matches with term overrides', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('pantry_match_tester');

      await withTestUser('pantry_match_tester', () async {
        // Enable test mode for the ingredient term queue manager
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;
        
        // Create a recipe with an ingredient that needs an override
        final recipeId = await createTestRecipe(
          title: 'Override Ingredient Match Recipe',
          ingredients: [
            {
              'name': 'Spring Onion',
              'terms': ['spring onion', 'scallion'],
            },
          ],
        );

        // Add a pantry item with a different term
        final pantryItemId = await createPantryItem(
          name: 'Green Onions', 
          terms: ['green onion']
        );

        // Add an override using the proper provider
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final notifier = container.read(ingredientTermOverrideNotifierProvider.notifier);

        const inputTerm = 'spring onion';
        const mappedTerm = 'green onion';

        await notifier.addOverride(
          inputTerm: inputTerm,
          mappedTerm: mappedTerm,
          userId: userId,
        );

        // Wait for the override to be created
        await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
          (overrides) => overrides.any((o) => o.inputTerm == inputTerm),
        );
        
        // Use the repository directly to get ingredient matches instead of the provider
        final repository = container.read(recipeRepositoryProvider);
        final matchResult = await repository.findPantryMatchesForRecipe(recipeId);
        
        // Should match due to the override
        expect(matchResult.matches.length, 1);
        expect(matchResult.matchRatio, 1.0);
        expect(matchResult.hasAllIngredients, true);
        
        final match = matchResult.matches.first;
        expect(match.hasMatch, true);
        expect(match.ingredient.name, 'Spring Onion');
        expect(match.pantryItem!.id, pantryItemId);
        expect(match.pantryItem!.name, 'Green Onions');
      });
    });
  });
}
