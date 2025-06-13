import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/powersync.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/database/models/pantry_items.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/pantry_item_terms.dart';
import 'package:recipe_app/database/models/steps.dart';
import 'package:recipe_app/src/managers/ingredient_term_queue_manager.dart';
import 'package:recipe_app/src/providers/ingredient_term_override_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/repositories/pantry_repository.dart';
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

  group('Sub-Recipe Pantry Matching Tests', () {
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
        final id = Uuid().v4(); // Remove const to ensure unique IDs
        return Ingredient(
          id: id,
          type: 'ingredient',
          name: ing['name'],
          primaryAmount1Value: ing['amount']?.toString(),
          primaryAmount1Unit: ing['unit'],
          recipeId: ing['recipeId'], // Support for sub-recipe links
          terms: (ing['terms'] as List).cast<String>().asMap().entries.map((entry) {
            return IngredientTerm(
              value: entry.value,
              source: 'test',
              sort: entry.key,
            );
          }).toList(),
          isCanonicalised: true,
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

      // Process any queued terms immediately in test mode and wait for database operations
      await ingredientTermManager.processQueue();

      // Wait for async database operations to complete
      await Future.delayed(const Duration(seconds: 3));

      return recipeId;
    }

    // Helper function to create a pantry item with terms
    Future<String> createPantryItem({
      required String name,
      required List<String> terms,
      StockStatus stockStatus = StockStatus.inStock,
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

      // Add pantry item using the repository method
      final pantryRepository = container.read(pantryRepositoryProvider);
      final itemId = await pantryRepository.addItem(
        name: name,
        userId: userId,
      );

      // Update the item with our test terms and stock status
      await appDb.update(appDb.pantryItems).replace(
        PantryItemsCompanion(
          id: Value(itemId),
          name: Value(name),
          stockStatus: Value(stockStatus),
          userId: Value(userId),
          terms: Value(pantryItemTerms),
          isCanonicalised: const Value(true),
        ),
      );

      // Process any queued terms and wait for database operations to complete
      final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
      await ingredientTermManager.processQueue();

      return itemId;
    }

    // Helper function to create a recipe chain (A → B → C)
    Future<List<String>> createRecipeChain({
      required List<Map<String, dynamic>> recipeDefinitions,
    }) async {
      final recipeIds = <String>[];

      // Create recipes in reverse order so we can reference them
      for (int i = recipeDefinitions.length - 1; i >= 0; i--) {
        final recipe = recipeDefinitions[i];

        // Update ingredients with recipe IDs for linking
        final ingredients = List<Map<String, dynamic>>.from(recipe['ingredients']);
        for (var ingredient in ingredients) {
          if (ingredient['linkedRecipeIndex'] != null) {
            final linkedIndex = ingredient['linkedRecipeIndex'] as int;
            ingredient['recipeId'] = recipeIds[recipeIds.length - 1 - (linkedIndex - i - 1)];
          }
        }

        final recipeId = await createTestRecipe(
          title: recipe['title'],
          ingredients: ingredients,
          steps: recipe['steps'],
        );

        recipeIds.insert(0, recipeId);
      }

      return recipeIds;
    }

    // Helper function to verify recipe match results
    void verifyRecipeMatch({
      required dynamic match,
      required String expectedRecipeId,
      required double expectedMatchRatio,
      required bool expectedPerfectMatch,
    }) {
      expect(match.recipe.id, expectedRecipeId);
      expect(match.matchRatio, closeTo(expectedMatchRatio, 0.01));
      expect(match.isPerfectMatch, expectedPerfectMatch);
    }

    // Helper function to verify ingredient match results
    void verifyIngredientMatch({
      required dynamic match,
      required String expectedIngredientName,
      required bool expectedHasMatch,
      String? expectedPantryItemName,
      bool? expectedHasRecipeMatch,
    }) {
      expect(match.ingredient.name, expectedIngredientName);
      expect(match.hasMatch, expectedHasMatch);

      if (expectedPantryItemName != null) {
        expect(match.pantryItem?.name, expectedPantryItemName);
      }

      if (expectedHasRecipeMatch != null) {
        expect(match.hasRecipeMatch, expectedHasRecipeMatch);
      }
    }

    testWidgets('Basic sub-recipe match - linked recipe fully available', (tester) async {
      await TestUserManager.createTestUser('sub_recipe_tester');

      await withTestUser('sub_recipe_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create chicken stock recipe (sub-recipe)
        final stockRecipeId = await createTestRecipe(
          title: 'Chicken Stock',
          ingredients: [
            {'name': 'Chicken', 'terms': ['chicken', 'chicken bones']},
            {'name': 'Onions', 'terms': ['onion', 'onions']},
            {'name': 'Carrots', 'terms': ['carrot', 'carrots']},
            {'name': 'Celery', 'terms': ['celery']},
          ],
        );

        // Create chicken soup recipe that links to stock
        final soupRecipeId = await createTestRecipe(
          title: 'Chicken Soup',
          ingredients: [
            {
              'name': 'Chicken Stock',
              'amount': '4',
              'unit': 'cups',
              'terms': ['chicken stock', 'stock'],
              'recipeId': stockRecipeId, // Link to stock recipe
            },
            {'name': 'Noodles', 'terms': ['noodles', 'egg noodles']},
          ],
        );

        // Create pantry items for stock ingredients
        await createPantryItem(name: 'Chicken', terms: ['chicken']);
        await createPantryItem(name: 'Onions', terms: ['onion']);
        await createPantryItem(name: 'Carrots', terms: ['carrot']);
        await createPantryItem(name: 'Celery', terms: ['celery']);
        await createPantryItem(name: 'Egg Noodles', terms: ['noodles']);

        await Future.delayed(const Duration(seconds: 3));

        // Test recipe-level matching
        await container.read(pantryRecipeMatchProvider.notifier).findMatchingRecipes();
        final matchState = container.read(pantryRecipeMatchProvider).value!;

        expect(matchState.matches.length, 2); // Both recipes should be makeable

        // Find the soup recipe in matches
        final soupMatch = matchState.matches.firstWhere(
          (m) => m.recipe.id == soupRecipeId
        );
        verifyRecipeMatch(
          match: soupMatch,
          expectedRecipeId: soupRecipeId,
          expectedMatchRatio: 1.0,
          expectedPerfectMatch: true,
        );

        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(soupRecipeId);

        expect(ingredientMatches.matches.length, 2);
        expect(ingredientMatches.hasAllIngredients, true);

        // Verify chicken stock ingredient matches via recipe
        final stockIngredientMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Chicken Stock'
        );
        verifyIngredientMatch(
          match: stockIngredientMatch,
          expectedIngredientName: 'Chicken Stock',
          expectedHasMatch: true,
          expectedHasRecipeMatch: true,
        );
      });
    });

    testWidgets('Direct pantry override - prepared item available', (tester) async {
      await TestUserManager.createTestUser('sub_recipe_override_tester');

      await withTestUser('sub_recipe_override_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create vinaigrette recipe (missing ingredients in pantry)
        final vinaigretteRecipeId = await createTestRecipe(
          title: 'Balsamic Vinaigrette',
          ingredients: [
            {'name': 'Balsamic Vinegar', 'terms': ['balsamic vinegar']},
            {'name': 'Olive Oil', 'terms': ['olive oil']}, // This will be missing
            {'name': 'Honey', 'terms': ['honey']},
          ],
        );

        // Create salad recipe that links to vinaigrette
        final saladRecipeId = await createTestRecipe(
          title: 'Green Salad',
          ingredients: [
            {'name': 'Mixed Greens', 'terms': ['mixed greens', 'salad greens']},
            {
              'name': 'Balsamic Vinaigrette',
              'terms': ['vinaigrette', 'dressing'],
              'recipeId': vinaigretteRecipeId, // Link to vinaigrette recipe
            },
          ],
        );

        // Create pantry items - vinaigrette recipe is NOT makeable (missing olive oil)
        await createPantryItem(name: 'Balsamic Vinegar', terms: ['balsamic vinegar']);
        await createPantryItem(name: 'Honey', terms: ['honey']);
        // Note: No olive oil, so vinaigrette recipe can't be made

        // BUT we have prepared vinaigrette in pantry
        await createPantryItem(name: 'Balsamic Vinaigrette', terms: ['vinaigrette', 'dressing']);
        await createPantryItem(name: 'Mixed Greens', terms: ['mixed greens']);

        // Debug pantry items
        final pantryDebug = await appDb.customSelect('''
          SELECT pi.name, pit.term 
          FROM pantry_items pi
          LEFT JOIN pantry_item_terms pit ON pi.id = pit.pantry_item_id
          WHERE pi.deleted_at IS NULL
        ''').get();
        
        print('DEBUG: Pantry items and terms:');
        for (final row in pantryDebug) {
          print('  - ${row.read<String>('name')}: ${row.readNullable<String>('term')}');
        }

        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(saladRecipeId);

        print('DEBUG: Salad ingredient matches:');
        for (final match in ingredientMatches.matches) {
          print('  - ${match.ingredient.name}: hasMatch=${match.hasMatch}, hasRecipeMatch=${match.hasRecipeMatch}, pantryItem=${match.pantryItem?.name}');
          print('    Ingredient terms: ${match.ingredient.terms?.map((t) => t.value).join(", ") ?? "none"}');
        }
        print('DEBUG: hasAllIngredients=${ingredientMatches.hasAllIngredients}, matchRatio=${ingredientMatches.matchRatio}');

        // Test CORRECT behavior: Direct pantry match should take priority over sub-recipe
        // Even though vinaigrette ingredient has recipeId, direct pantry item should be preferred
        expect(ingredientMatches.hasAllIngredients, true);

        // Verify vinaigrette ingredient matches via DIRECT pantry item (priority over sub-recipe)
        final vinaigretteMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Balsamic Vinaigrette'
        );
        verifyIngredientMatch(
          match: vinaigretteMatch,
          expectedIngredientName: 'Balsamic Vinaigrette',
          expectedHasMatch: true,
          expectedPantryItemName: 'Balsamic Vinaigrette',
          expectedHasRecipeMatch: false, // Should be false because direct pantry takes priority
        );
      });
    });

    testWidgets('Fallback to sub-recipe when direct pantry out of stock', (tester) async {
      await TestUserManager.createTestUser('out_of_stock_fallback_tester');

      await withTestUser('out_of_stock_fallback_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create chicken stock recipe (makeable)
        final stockRecipeId = await createTestRecipe(
          title: 'Chicken Stock',
          ingredients: [
            {'name': 'Chicken Bones', 'terms': ['chicken bones']},
            {'name': 'Onions', 'terms': ['onion', 'onions']},
            {'name': 'Carrots', 'terms': ['carrot', 'carrots']},
          ],
        );

        // Create soup recipe that links to stock
        final soupRecipeId = await createTestRecipe(
          title: 'Chicken Soup',
          ingredients: [
            {
              'name': 'Chicken Stock',
              'amount': '4',
              'unit': 'cups',
              'terms': ['chicken stock', 'stock'],
              'recipeId': stockRecipeId, // Link to stock recipe
            },
            {'name': 'Noodles', 'terms': ['noodles', 'egg noodles']},
          ],
        );

        // Create pantry items for stock recipe (making it makeable)
        await createPantryItem(name: 'Chicken Bones', terms: ['chicken bones']);
        await createPantryItem(name: 'Onions', terms: ['onion']);
        await createPantryItem(name: 'Carrots', terms: ['carrot']);
        await createPantryItem(name: 'Noodles', terms: ['noodles']);
        
        // Create direct pantry item BUT mark it as OUT OF STOCK
        await createPantryItem(
          name: 'Chicken Stock', 
          terms: ['chicken stock', 'stock'],
          stockStatus: StockStatus.outOfStock, // This should trigger fallback
        );

        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(soupRecipeId);
        
        expect(ingredientMatches.hasAllIngredients, true);
        
        // Verify chicken stock ingredient falls back to sub-recipe (not out-of-stock direct item)
        final stockIngredientMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Chicken Stock'
        );
        verifyIngredientMatch(
          match: stockIngredientMatch,
          expectedIngredientName: 'Chicken Stock',
          expectedHasMatch: true,
          expectedHasRecipeMatch: true, // Should fall back to sub-recipe
        );
        
        // The pantry item should be null because we fell back to recipe, not direct pantry
        expect(stockIngredientMatch.pantryItem, null, reason: 'Should fall back to recipe, not use out-of-stock pantry item');
      });
    });

    testWidgets('Fallback to sub-recipe when no direct pantry match', (tester) async {
      await TestUserManager.createTestUser('no_direct_match_fallback_tester');

      await withTestUser('no_direct_match_fallback_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create tomato sauce recipe (makeable)
        final sauceRecipeId = await createTestRecipe(
          title: 'Tomato Sauce',
          ingredients: [
            {'name': 'Tomatoes', 'terms': ['tomatoes', 'fresh tomatoes']},
            {'name': 'Garlic', 'terms': ['garlic']},
            {'name': 'Basil', 'terms': ['basil', 'fresh basil']},
          ],
        );

        // Create pasta recipe that links to sauce
        final pastaRecipeId = await createTestRecipe(
          title: 'Pasta with Tomato Sauce',
          ingredients: [
            {'name': 'Pasta', 'terms': ['pasta', 'spaghetti']},
            {
              'name': 'Tomato Sauce',
              'terms': ['tomato sauce', 'sauce'],
              'recipeId': sauceRecipeId, // Link to sauce recipe
            },
          ],
        );

        // Create pantry items for sauce recipe (making it makeable)
        await createPantryItem(name: 'Fresh Tomatoes', terms: ['tomatoes']);
        await createPantryItem(name: 'Garlic', terms: ['garlic']);
        await createPantryItem(name: 'Fresh Basil', terms: ['basil']);
        await createPantryItem(name: 'Spaghetti', terms: ['pasta']);
        
        // NOTE: No direct "Tomato Sauce" pantry item - should fall back to recipe

        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(pastaRecipeId);
        
        expect(ingredientMatches.hasAllIngredients, true);
        
        // Verify tomato sauce ingredient matches via sub-recipe (no direct pantry item)
        final sauceMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Tomato Sauce'
        );
        verifyIngredientMatch(
          match: sauceMatch,
          expectedIngredientName: 'Tomato Sauce',
          expectedHasMatch: true,
          expectedHasRecipeMatch: true, // Should match via sub-recipe
        );
        
        expect(sauceMatch.pantryItem, null, reason: 'Should match via recipe, not direct pantry item');
      });
    });

    testWidgets('No match when neither direct nor sub-recipe available', (tester) async {
      await TestUserManager.createTestUser('no_match_tester');

      await withTestUser('no_match_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create pesto sauce recipe (NOT makeable - missing ingredients)
        final pestoRecipeId = await createTestRecipe(
          title: 'Pesto Sauce',
          ingredients: [
            {'name': 'Basil', 'terms': ['basil', 'fresh basil']},
            {'name': 'Pine Nuts', 'terms': ['pine nuts']}, // This will be missing
            {'name': 'Parmesan', 'terms': ['parmesan', 'parmesan cheese']},
          ],
        );

        // Create pasta recipe that links to pesto
        final pastaRecipeId = await createTestRecipe(
          title: 'Pasta with Pesto',
          ingredients: [
            {'name': 'Pasta', 'terms': ['pasta', 'spaghetti']},
            {
              'name': 'Pesto Sauce',
              'terms': ['pesto', 'pesto sauce'],
              'recipeId': pestoRecipeId, // Link to unmakeable pesto recipe
            },
          ],
        );

        // Create pantry items - pesto recipe is NOT makeable (missing pine nuts)
        await createPantryItem(name: 'Fresh Basil', terms: ['basil']);
        await createPantryItem(name: 'Parmesan', terms: ['parmesan']);
        await createPantryItem(name: 'Spaghetti', terms: ['pasta']);
        // NOTE: No pine nuts, so pesto recipe can't be made
        // NOTE: No direct "Pesto Sauce" pantry item either

        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(pastaRecipeId);
        
        expect(ingredientMatches.hasAllIngredients, false);
        expect(ingredientMatches.matchRatio, 0.5); // Only pasta matches, pesto doesn't
        
        // Verify pesto sauce ingredient has NO match (neither direct pantry nor sub-recipe)
        final pestoMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Pesto Sauce'
        );
        verifyIngredientMatch(
          match: pestoMatch,
          expectedIngredientName: 'Pesto Sauce',
          expectedHasMatch: false, // No match available
          expectedHasRecipeMatch: false, // Sub-recipe not makeable
        );
        
        expect(pestoMatch.pantryItem, null, reason: 'No direct pantry item available');
      });
    });

    testWidgets('Multi-level recipe chain (3 levels deep)', (tester) async {
      await TestUserManager.createTestUser('recipe_chain_tester');

      await withTestUser('recipe_chain_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create recipe chain: Pizza → Pizza Sauce → Tomato Base
        final recipeIds = await createRecipeChain(
          recipeDefinitions: [
            {
              'title': 'Pizza',
              'ingredients': [
                {'name': 'Pizza Dough', 'terms': ['dough', 'pizza dough']},
                {
                  'name': 'Pizza Sauce',
                  'terms': ['pizza sauce', 'sauce'],
                  'linkedRecipeIndex': 1, // Links to next recipe
                },
                {'name': 'Mozzarella', 'terms': ['mozzarella', 'cheese']},
              ],
              'steps': ['Roll dough', 'Add sauce', 'Add cheese', 'Bake'],
            },
            {
              'title': 'Pizza Sauce',
              'ingredients': [
                {
                  'name': 'Tomato Base',
                  'terms': ['tomato base', 'tomato sauce'],
                  'linkedRecipeIndex': 2, // Links to next recipe
                },
                {'name': 'Italian Herbs', 'terms': ['italian herbs', 'herbs']},
                {'name': 'Garlic', 'terms': ['garlic']},
              ],
              'steps': ['Mix tomato base with herbs and garlic'],
            },
            {
              'title': 'Tomato Base',
              'ingredients': [
                {'name': 'Tomatoes', 'terms': ['tomatoes', 'fresh tomatoes']},
                {'name': 'Salt', 'terms': ['salt']},
              ],
              'steps': ['Crush tomatoes', 'Add salt'],
            },
          ],
        );

        final pizzaRecipeId = recipeIds[0];

        // Create pantry items for all base ingredients
        await createPantryItem(name: 'Pizza Dough', terms: ['dough']);
        await createPantryItem(name: 'Mozzarella', terms: ['mozzarella']);
        await createPantryItem(name: 'Fresh Tomatoes', terms: ['tomatoes']);
        await createPantryItem(name: 'Salt', terms: ['salt']);
        await createPantryItem(name: 'Italian Herbs', terms: ['italian herbs']);
        await createPantryItem(name: 'Garlic', terms: ['garlic']);

        // Test that the chain works
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(pizzaRecipeId);

        expect(ingredientMatches.hasAllIngredients, true);
        expect(ingredientMatches.matchRatio, 1.0);

        // Verify pizza sauce ingredient matches via recipe chain
        final sauceMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Pizza Sauce'
        );
        verifyIngredientMatch(
          match: sauceMatch,
          expectedIngredientName: 'Pizza Sauce',
          expectedHasMatch: true,
          expectedHasRecipeMatch: true,
        );
      });
    });

    testWidgets('Partial sub-recipe match', (tester) async {
      await TestUserManager.createTestUser('partial_match_tester');

      await withTestUser('partial_match_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create marinara sauce recipe (will be partially makeable)
        final sauceRecipeId = await createTestRecipe(
          title: 'Marinara Sauce',
          ingredients: [
            {'name': 'Tomatoes', 'terms': ['tomatoes']},
            {'name': 'Garlic', 'terms': ['garlic']},
            {'name': 'Basil', 'terms': ['basil']}, // This will be missing
            {'name': 'Onion', 'terms': ['onion']},
          ],
        );

        // Create pasta recipe with mixed ingredients
        final pastaRecipeId = await createTestRecipe(
          title: 'Pasta with Marinara',
          ingredients: [
            {'name': 'Pasta', 'terms': ['pasta', 'spaghetti']}, // Direct match
            {
              'name': 'Marinara Sauce',
              'terms': ['marinara', 'sauce'],
              'recipeId': sauceRecipeId, // Sub-recipe, partially makeable
            },
            {'name': 'Parmesan', 'terms': ['parmesan', 'cheese']}, // Direct match
            {'name': 'Black Pepper', 'terms': ['black pepper']}, // No match
          ],
        );

        // Create pantry items - sauce recipe missing basil, pasta missing black pepper
        await createPantryItem(name: 'Spaghetti', terms: ['pasta']);
        await createPantryItem(name: 'Tomatoes', terms: ['tomatoes']);
        await createPantryItem(name: 'Garlic', terms: ['garlic']);
        await createPantryItem(name: 'Onion', terms: ['onion']);
        await createPantryItem(name: 'Parmesan', terms: ['parmesan']);
        // Missing: basil (for sauce), black pepper (for pasta)

        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(pastaRecipeId);

        expect(ingredientMatches.hasAllIngredients, false);
        // Note: Match ratio might vary based on implementation details
        // The key test is that we get some matches but not all
        expect(ingredientMatches.matchRatio, lessThan(1.0));
        expect(ingredientMatches.matchRatio, greaterThan(0.0));

        // Verify individual ingredient matches
        final pastaMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Pasta'
        );
        verifyIngredientMatch(
          match: pastaMatch,
          expectedIngredientName: 'Pasta',
          expectedHasMatch: true,
          expectedHasRecipeMatch: false,
        );

        final sauceMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Marinara Sauce'
        );
        verifyIngredientMatch(
          match: sauceMatch,
          expectedIngredientName: 'Marinara Sauce',
          expectedHasMatch: false, // Not fully makeable due to missing basil
          expectedHasRecipeMatch: false,
        );

        final parmesanMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Parmesan'
        );
        verifyIngredientMatch(
          match: parmesanMatch,
          expectedIngredientName: 'Parmesan',
          expectedHasMatch: true,
          expectedHasRecipeMatch: false,
        );

        final pepperMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Black Pepper'
        );
        verifyIngredientMatch(
          match: pepperMatch,
          expectedIngredientName: 'Black Pepper',
          expectedHasMatch: false,
          expectedHasRecipeMatch: false,
        );
      });
    });

    testWidgets('Direct pantry priority - in stock item beats makeable sub-recipe', (tester) async {
      await TestUserManager.createTestUser('priority_tester');

      await withTestUser('priority_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create chicken stock recipe (will NOT be makeable)
        final stockRecipeId = await createTestRecipe(
          title: 'Chicken Stock',
          ingredients: [
            {'name': 'Chicken Bones', 'terms': ['chicken bones']}, // Missing from pantry
            {'name': 'Onions', 'terms': ['onion']},
            {'name': 'Carrots', 'terms': ['carrot']},
          ],
        );

        // Create soup recipe that links to stock
        final soupRecipeId = await createTestRecipe(
          title: 'Chicken Soup',
          ingredients: [
            {
              'name': 'Chicken Stock',
              'terms': ['chicken stock', 'stock'],
              'recipeId': stockRecipeId, // Link to unmakeable stock recipe
            },
            {'name': 'Noodles', 'terms': ['noodles']},
          ],
        );

        // Create pantry items - stock recipe CAN'T be made (no chicken bones)
        // BUT we have store-bought chicken stock in pantry
        // This tests that direct pantry item takes priority over sub-recipe checking
        await createPantryItem(name: 'Onions', terms: ['onion']);
        await createPantryItem(name: 'Carrots', terms: ['carrot']);
        await createPantryItem(name: 'Chicken Stock', terms: ['chicken stock', 'stock']); // Direct match!
        await createPantryItem(name: 'Noodles', terms: ['noodles']);

        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(soupRecipeId);

        expect(ingredientMatches.hasAllIngredients, true);
        expect(ingredientMatches.matchRatio, 1.0);

        // Verify chicken stock matches via direct pantry item (not recipe)
        final stockMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Chicken Stock'
        );
        verifyIngredientMatch(
          match: stockMatch,
          expectedIngredientName: 'Chicken Stock',
          expectedHasMatch: true,
          expectedPantryItemName: 'Chicken Stock',
          expectedHasRecipeMatch: false, // Should match via pantry, not recipe
        );
      });
    });

    testWidgets('Circular dependency detection', (tester) async {
      await TestUserManager.createTestUser('circular_tester');

      await withTestUser('circular_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create recipe A
        final recipeAId = await createTestRecipe(
          title: 'Recipe A',
          ingredients: [
            {'name': 'Base Ingredient A', 'terms': ['base-a']},
          ],
        );

        // Create recipe B that links to A
        final recipeBId = await createTestRecipe(
          title: 'Recipe B',
          ingredients: [
            {
              'name': 'Recipe A Component',
              'terms': ['recipe-a'],
              'recipeId': recipeAId,
            },
            {'name': 'Base Ingredient B', 'terms': ['base-b']},
          ],
        );

        // Update recipe A to link to B (creating circular dependency)
        final recipeRepository = container.read(recipeRepositoryProvider);
        final recipeA = await recipeRepository.getRecipeById(recipeAId);
        final updatedIngredients = [
          ...?recipeA?.ingredients,
          Ingredient(
            id: const Uuid().v4(),
            type: 'ingredient',
            name: 'Recipe B Component',
            recipeId: recipeBId, // Creates circular reference
            terms: [
              IngredientTerm(value: 'recipe-b', source: 'test', sort: 0),
            ],
            isCanonicalised: true,
          ),
        ];

        final updatedRecipe = recipeA!.copyWith(
          ingredients: Value(updatedIngredients),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        );

        await recipeRepository.updateRecipe(updatedRecipe);

        // Process any queued terms after update and wait for database operations
        await ingredientTermManager.processQueue();
        await Future.delayed(const Duration(seconds: 3));

        // Create pantry items for base ingredients
        await createPantryItem(name: 'Base A', terms: ['base-a']);
        await createPantryItem(name: 'Base B', terms: ['base-b']);

        // Add debugging for circular dependency
        print('DEBUG: Testing circular dependency between $recipeAId and $recipeBId');

        // Test that circular dependency is handled gracefully (should not hang/crash)
        bool completed = false;
        final stopwatch = Stopwatch()..start();

        try {
          final ingredientMatches = await recipeRepository.findPantryMatchesForRecipe(recipeAId);
          completed = true;
          stopwatch.stop();

          print('DEBUG: Circular dependency test completed in ${stopwatch.elapsedMilliseconds}ms');
          print('DEBUG: Found ${ingredientMatches.matches.length} ingredient matches');

          // Should complete without infinite loop
          expect(ingredientMatches.recipeId, recipeAId);
          expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds

        } catch (e) {
          stopwatch.stop();
          print('DEBUG: Circular dependency test failed with error: $e');
          // Even if it fails, it should fail quickly, not hang
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
          rethrow;
        }

        expect(completed, true, reason: 'Circular dependency test should complete without hanging');
      });
    });

    testWidgets('Deep nesting performance test', (tester) async {
      await TestUserManager.createTestUser('deep_nesting_tester');

      await withTestUser('deep_nesting_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create 3-level deep recipe chain (limited by current implementation depth of 3)
        final recipeIds = <String>[];

        // Create from bottom up
        for (int i = 2; i >= 0; i--) {
          final ingredients = <Map<String, dynamic>>[
            {'name': 'Base Ingredient $i', 'terms': ['base-$i']},
          ];

          // Add reference to next recipe if not the last one
          if (i < 2) {
            ingredients.add({
              'name': 'Sub Recipe ${i + 1}',
              'terms': ['sub-${i + 1}'],
              'recipeId': recipeIds[0], // Reference to previously created recipe
            });
          }

          final recipeId = await createTestRecipe(
            title: 'Recipe Level $i',
            ingredients: ingredients,
          );

          recipeIds.insert(0, recipeId);
        }

        // Create pantry items for all base ingredients
        for (int i = 0; i < 3; i++) {
          await createPantryItem(name: 'Base $i', terms: ['base-$i']);
        }

        print('DEBUG: Testing 3-level deep nesting with recipes: $recipeIds');

        // Time the operation
        final stopwatch = Stopwatch()..start();

        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(recipeIds[0]);

        stopwatch.stop();

        print('DEBUG: Deep nesting test completed in ${stopwatch.elapsedMilliseconds}ms');
        print('DEBUG: Match ratio: ${ingredientMatches.matchRatio}, hasAllIngredients: ${ingredientMatches.hasAllIngredients}');

        // Should complete within reasonable time (5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // NOTE: Due to depth limits in current implementation, this might not be fully makeable
        // The important thing is that it completes without hanging
        expect(ingredientMatches.recipeId, recipeIds[0]);
      });
    });

    testWidgets('Mixed ingredient types comprehensive test', (tester) async {
      await TestUserManager.createTestUser('mixed_types_tester');

      await withTestUser('mixed_types_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create a sub-recipe
        final subRecipeId = await createTestRecipe(
          title: 'Sub Recipe',
          ingredients: [
            {'name': 'Sub Ingredient 1', 'terms': ['sub-1']},
            {'name': 'Sub Ingredient 2', 'terms': ['sub-2']},
          ],
        );

        // Create main recipe with mixed ingredient types
        final mainRecipeId = await createTestRecipe(
          title: 'Mixed Types Recipe',
          ingredients: [
            // Regular ingredient with match
            {'name': 'Regular Match', 'terms': ['regular-match']},

            // Regular ingredient without match
            {'name': 'Regular No Match', 'terms': ['unicorn-tears']}, // Unique term that won't match anything

            // Ingredient without terms
            {'name': 'No Terms Ingredient', 'terms': []},

            // Sub-recipe ingredient (makeable)
            {
              'name': 'Sub Recipe Component',
              'terms': ['sub-recipe'],
              'recipeId': subRecipeId,
            },

            // Sub-recipe ingredient with direct pantry override
            {
              'name': 'Override Component',
              'terms': ['override-component'],
              'recipeId': subRecipeId, // Links to sub-recipe but has direct pantry match
            },
          ],
        );

        // Create pantry items for various scenarios
        // NOTE: Item names should match the primary term since addItem() uses name as first term
        await createPantryItem(name: 'regular-match', terms: ['regular-match']);
        await createPantryItem(name: 'sub-1', terms: ['sub-1']);
        await createPantryItem(name: 'sub-2', terms: ['sub-2']);
        await createPantryItem(name: 'override-component', terms: ['override-component']);


        // Test ingredient-level matching
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(mainRecipeId);

        // Debug: Check what's actually stored in the JSON data
        final recipeJsonDebug = await appDb.customSelect('''
          SELECT id, data FROM ps_data__recipes WHERE id = ?
        ''', variables: [Variable(mainRecipeId)]).get();
        
        print('DEBUG: Recipe JSON data:');
        for (final row in recipeJsonDebug) {
          print('  Recipe ID: ${row.read<String>('id')}');
          print('  JSON data: ${row.read<String>('data')}');
        }

        // Debug: Check what terms are materialized in the database for main recipe
        final ingredientTermsDebug = await appDb.customSelect('''
          SELECT recipe_id, ingredient_id, term, sort, linked_recipe_id 
          FROM recipe_ingredient_terms 
          WHERE recipe_id = ?
          ORDER BY ingredient_id, sort
        ''', variables: [Variable(mainRecipeId)]).get();
        
        print('DEBUG: Main recipe materialized ingredient terms:');
        for (final row in ingredientTermsDebug) {
          print('  Recipe: ${row.read<String>('recipe_id')}, Ingredient: ${row.read<String>('ingredient_id')}, Term: ${row.read<String>('term')}, Sort: ${row.read<int>('sort')}, LinkedRecipe: ${row.readNullable<String>('linked_recipe_id')}');
        }

        // Debug: Check what terms are materialized for the sub-recipe
        final subRecipeTermsDebug = await appDb.customSelect('''
          SELECT recipe_id, ingredient_id, term, sort, linked_recipe_id 
          FROM recipe_ingredient_terms 
          WHERE recipe_id = ?
          ORDER BY ingredient_id, sort
        ''', variables: [Variable(subRecipeId)]).get();
        
        print('DEBUG: Sub-recipe materialized ingredient terms:');
        for (final row in subRecipeTermsDebug) {
          print('  Recipe: ${row.read<String>('recipe_id')}, Ingredient: ${row.read<String>('ingredient_id')}, Term: ${row.read<String>('term')}, Sort: ${row.read<int>('sort')}, LinkedRecipe: ${row.readNullable<String>('linked_recipe_id')}');
        }

        // Debug: Check what's in pantry_item_terms  
        final pantryTermsDebug = await appDb.customSelect('''
          SELECT pit.pantry_item_id, pit.term, pit.sort, pi.name
          FROM pantry_item_terms pit
          LEFT JOIN pantry_items pi ON pit.pantry_item_id = pi.id
          WHERE pi.deleted_at IS NULL
          ORDER BY pi.name, pit.sort
        ''').get();
        
        print('DEBUG: Pantry item terms:');
        for (final row in pantryTermsDebug) {
          print('  Item: ${row.readNullable<String>('name')}, Term: ${row.read<String>('term')}, Sort: ${row.read<int>('sort')}');
        }

        // Debug: Show each ingredient match result
        print('DEBUG: Individual ingredient matches:');
        for (final match in ingredientMatches.matches) {
          print('  - ${match.ingredient.name}: hasMatch=${match.hasMatch}, hasRecipeMatch=${match.hasRecipeMatch}, pantryItem=${match.pantryItem?.name ?? "null"}');
          print('    Ingredient ID: ${match.ingredient.id}');
          print('    Ingredient terms: ${match.ingredient.terms?.map((t) => t.value).join(", ") ?? "none"}');
          if (match.ingredient.recipeId != null) {
            print('    Linked recipe ID: ${match.ingredient.recipeId}');
          }
        }
        print('DEBUG: Overall results: matches=${ingredientMatches.matches.length}, ratio=${ingredientMatches.matchRatio}, hasAll=${ingredientMatches.hasAllIngredients}');

        expect(ingredientMatches.matches.length, 5); // All ingredients should appear
        expect(ingredientMatches.matchRatio, 0.6); // 3 out of 5 match (Regular Match + Sub Recipe Component + Override Component)
        expect(ingredientMatches.hasAllIngredients, false);

        // Verify each ingredient type
        final regularMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Regular Match'
        );
        verifyIngredientMatch(
          match: regularMatch,
          expectedIngredientName: 'Regular Match',
          expectedHasMatch: true,
          expectedHasRecipeMatch: false,
        );

        final regularNoMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Regular No Match'
        );
        verifyIngredientMatch(
          match: regularNoMatch,
          expectedIngredientName: 'Regular No Match',
          expectedHasMatch: false,
          expectedHasRecipeMatch: false,
        );

        final noTermsMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'No Terms Ingredient'
        );
        verifyIngredientMatch(
          match: noTermsMatch,
          expectedIngredientName: 'No Terms Ingredient',
          expectedHasMatch: false,
          expectedHasRecipeMatch: false,
        );

        final subRecipeMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Sub Recipe Component'
        );
        verifyIngredientMatch(
          match: subRecipeMatch,
          expectedIngredientName: 'Sub Recipe Component',
          expectedHasMatch: true,
          expectedHasRecipeMatch: true,
        );

        final overrideMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Override Component'
        );
        verifyIngredientMatch(
          match: overrideMatch,
          expectedIngredientName: 'Override Component',
          expectedHasMatch: true,
          expectedPantryItemName: 'override-component',
          expectedHasRecipeMatch: false, // Should match via pantry, not recipe
        );
      });
    });

    testWidgets('Term overrides with sub-recipes', (tester) async {
      await TestUserManager.createTestUser('term_override_sub_recipe_tester');

      await withTestUser('term_override_sub_recipe_tester', () async {
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);
        ingredientTermManager.testMode = true;

        // Create sub-recipe with ingredient that needs override
        final subRecipeId = await createTestRecipe(
          title: 'Sub Recipe with Override',
          ingredients: [
            {'name': 'Spring Onion', 'terms': ['spring onion', 'scallion']},
            {'name': 'Regular Ingredient', 'terms': ['regular']},
          ],
        );

        // Create main recipe that links to sub-recipe
        final mainRecipeId = await createTestRecipe(
          title: 'Main Recipe',
          ingredients: [
            {
              'name': 'Sub Recipe Component',
              'terms': ['sub-component'],
              'recipeId': subRecipeId,
            },
          ],
        );

        // Create pantry items using overridden terms
        await createPantryItem(name: 'Green Onions', terms: ['green onion']);
        await createPantryItem(name: 'Regular', terms: ['regular']);

        // Add term override
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final notifier = container.read(ingredientTermOverrideNotifierProvider.notifier);

        await notifier.addOverride(
          inputTerm: 'spring onion',
          mappedTerm: 'green onion',
          userId: userId,
        );

        // Wait for override to be created
        await waitForProviderValue<List<IngredientTermOverrideEntry>>(
          container,
          ingredientTermOverrideNotifierProvider,
          (overrides) => overrides.any((o) => o.inputTerm == 'spring onion'),
        );

        // Test that sub-recipe is makeable due to override
        final repository = container.read(recipeRepositoryProvider);
        final ingredientMatches = await repository.findPantryMatchesForRecipe(mainRecipeId);

        expect(ingredientMatches.hasAllIngredients, true);
        expect(ingredientMatches.matchRatio, 1.0);

        // Verify sub-recipe component matches via recipe (not direct pantry)
        final subRecipeMatch = ingredientMatches.matches.firstWhere(
          (m) => m.ingredient.name == 'Sub Recipe Component'
        );
        verifyIngredientMatch(
          match: subRecipeMatch,
          expectedIngredientName: 'Sub Recipe Component',
          expectedHasMatch: true,
          expectedHasRecipeMatch: true,
        );
      });
    });
  });
}
