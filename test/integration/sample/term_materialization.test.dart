import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/models/ingredient_terms.dart';
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/database/models/pantry_item_terms.dart';
import 'package:recipe_app/database/models/pantry_items.dart'; // For StockStatus enum
import 'package:recipe_app/database/models/steps.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/powersync.dart';
import 'package:recipe_app/src/managers/pantry_item_term_queue_manager.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/ingredient_term_override_provider.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/test_household_manager.dart';
import '../../utils/test_utils.dart';
import '../../utils/test_user_manager.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity_status');

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
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'listen') {
          return null;
        }
        return null;
      });
      
      // Disable the pantry item term queue manager to prevent race conditions
      final queueManager = container.read(pantryItemTermQueueManagerProvider);
      queueManager.testMode = true;
    });

    tearDown(() async {
      container.dispose();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
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
            isCanonicalised: true,
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
            isCanonicalised: true,
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

        // We should have 6 terms in total (3 for each ingredient: name + 2 canonical terms)
        expect(materializedTerms.length, 6);

        // Verify onion terms (name + canonical terms)
        final onionMaterializedTerms = materializedTerms
            .where((row) => row.read<String>('ingredient_id') == 'ing_1')
            .toList();
        expect(onionMaterializedTerms.length, 3);
        expect(onionMaterializedTerms[0].read<String>('term'), 'Diced Yellow Onion'); // Name term added first
        expect(onionMaterializedTerms[1].read<String>('term'), 'onion');
        expect(onionMaterializedTerms[2].read<String>('term'), 'yellow onion');

        // Verify tomato terms (name + canonical terms)
        final tomatoMaterializedTerms = materializedTerms
            .where((row) => row.read<String>('ingredient_id') == 'ing_2')
            .toList();
        expect(tomatoMaterializedTerms.length, 3);
        expect(tomatoMaterializedTerms[0].read<String>('term'), 'Roma Tomatoes'); // Name term added first
        expect(tomatoMaterializedTerms[1].read<String>('term'), 'tomato');
        expect(tomatoMaterializedTerms[2].read<String>('term'), 'roma tomato');

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

        // We should now have 4 terms for the first ingredient (name + 3 canonical terms)
        expect(updatedMaterializedTerms.length, 4);
        expect(updatedMaterializedTerms[3].read<String>('term'), 'allium');
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
          stockStatus: StockStatus.inStock,
          userId: userId,
        );

        // Wait for the pantry item to be stored
        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
          (items) => items.any((item) => item.name == "Granny Smith Apples"),
        );

        // Update the pantry item to add terms (ensure name is first term)
        final allTerms = [
          PantryItemTerm(value: "Granny Smith Apples", source: "user", sort: 0), // Name term first
          ...appleTerms.map((term) => PantryItemTerm(
            value: term.value,
            source: term.source,
            sort: term.sort + 1, // Adjust sort order
          )),
        ];

        await appDb.update(appDb.pantryItems).replace(
          PantryItemsCompanion(
            id: Value(pantryItemId),
            name: const Value("Granny Smith Apples"),
            stockStatus: const Value(StockStatus.inStock),
            userId: Value(userId),
            terms: Value(allTerms),
            isCanonicalised: const Value(true),
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

        // We should have 3 terms in total (name + 2 canonical terms)
        expect(materializedTerms.length, 3);
        expect(materializedTerms[0].read<String>('term'), 'Granny Smith Apples'); // Name term added first
        expect(materializedTerms[1].read<String>('term'), 'apple');
        expect(materializedTerms[2].read<String>('term'), 'granny smith');

        // Now update the pantry item to test the update trigger
        final updatedCanonicalTerms = [
          ...appleTerms,
          PantryItemTerm(value: "fruit", source: "user", sort: 3),
        ];

        final allUpdatedTerms = [
          PantryItemTerm(value: "Granny Smith Apples", source: "user", sort: 0), // Name term first
          ...updatedCanonicalTerms.map((term) => PantryItemTerm(
            value: term.value,
            source: term.source,
            sort: term.sort + 1, // Adjust sort order
          )),
        ];

        await appDb.update(appDb.pantryItems).replace(
          PantryItemsCompanion(
            id: Value(pantryItemId),
            name: const Value("Granny Smith Apples"),
            stockStatus: const Value(StockStatus.inStock),
            userId: Value(userId),
            terms: Value(allUpdatedTerms),
            isCanonicalised: const Value(true),
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

        // We should now have 4 terms (name + 3 canonical terms)
        expect(updatedMaterializedTerms.length, 4);
        expect(updatedMaterializedTerms[3].read<String>('term'), 'fruit');
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

        // The override should be completely removed from the materialized table
        expect(afterDeleteOverrides.length, 0);
      });
    });

    testWidgets('Materialized terms are recreated when user logs out and back in', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      String recipeId = '';
      String pantryItemId = '';

      // First session: Create recipe and pantry item with terms, then verify they exist in materialized tables
      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Create a recipe with ingredients that have terms
        recipeId = const Uuid().v4();
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
            isCanonicalised: true,
          ),
        ];

        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: recipeId,
          title: "Persistence Test Recipe",
          language: "en",
          description: "Testing persistence",
          userId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          ingredients: ingredients,
        );

        // Wait for the recipe to be stored
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.any((r) => r.recipe.title == "Persistence Test Recipe"),
        );

        // Create a pantry item with terms
        final appleTerms = [
          PantryItemTerm(value: "apple", source: "user", sort: 1),
          PantryItemTerm(value: "green apple", source: "user", sort: 2),
        ];

        // Add a pantry item using the provider
        pantryItemId = await container.read(pantryItemsProvider.notifier).addItem(
          name: "Green Apples",
          stockStatus: StockStatus.inStock,
          userId: userId,
        );

        // Wait for the pantry item to be stored
        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
          (items) => items.any((item) => item.name == "Green Apples"),
        );

        // Create all pantry item terms including name term
        final allAppleTerms = [
          PantryItemTerm(value: "Green Apples", source: "user", sort: 0), // Name term first
          ...appleTerms.map((term) => PantryItemTerm(
            value: term.value,
            source: term.source,
            sort: term.sort + 1, // Adjust sort order
          )),
        ];

        // Update the pantry item to add terms and set canonicalized flag
        await container.read(pantryItemsProvider.notifier).updateItem(
          id: pantryItemId,
          terms: allAppleTerms,
          isCanonicalised: true,
        );

        // Allow some time for triggers to execute and data to sync to server
        await Future.delayed(const Duration(seconds: 1));

        // Verify the materialized terms exist before logout
        final recipeMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM recipe_ingredient_terms 
          WHERE recipe_id = ?
          ''',
          variables: [Variable.withString(recipeId)],
        ).getSingle();

        final pantryMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM pantry_item_terms 
          WHERE pantry_item_id = ?
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).getSingle();

        expect(recipeMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
        expect(pantryMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
      });

      // At this point, user is logged out. Local DB is cleared.

      // Log back in and check that materialized tables are recreated
      await withTestUser('owner', () async {
        // Wait for data to sync back from server
        await Future.delayed(const Duration(seconds: 1));

        // Verify the recipe and pantry item are back
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.any((r) => r.recipe.title == "Persistence Test Recipe"),
        );

        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
          (items) => items.any((item) => item.name == "Green Apples"),
        );

        // Now verify that the materialized terms were recreated
        final recipeMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM recipe_ingredient_terms 
          WHERE recipe_id = ?
          ''',
          variables: [Variable.withString(recipeId)],
        ).getSingle();

        final pantryMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM pantry_item_terms 
          WHERE pantry_item_id = ?
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).getSingle();

        expect(recipeMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
        expect(pantryMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
      });
    });

    testWidgets('Materialized terms work with household sharing', (tester) async {
      // Create test users "owner" and "member"
      await TestUserManager.createTestUsers(['household_owner', 'household_member']);

      late String householdId;
      late String recipeId;
      late String pantryItemId;

      // Step 1: household_owner logs in, creates a household
      await withTestUser('household_owner', () async {
        final householdOwnerId = Supabase.instance.client.auth.currentUser!.id;
        final householdData = await TestHouseholdManager.createHousehold('Test Household', householdOwnerId);
        householdId = householdData['id'] as String;
        await TestHouseholdManager.addHouseholdMember(householdId, householdOwnerId);
      });

      // Step 2: Add household_member to the household
      await withTestUser('household_member', () async {
        final householdMemberId = Supabase.instance.client.auth.currentUser!.id;
        await TestHouseholdManager.addHouseholdMember(householdId, householdMemberId);
      });

      // Step 3: household_owner creates recipe and pantry item with terms and associates with household
      await withTestUser('household_owner', () async {
        final householdOwnerId = Supabase.instance.client.auth.currentUser!.id;

        // Create recipe with terms and assign to household
        recipeId = const Uuid().v4();
        final carrotTerms = [
          IngredientTerm(value: "carrot", source: "ai", sort: 1),
          IngredientTerm(value: "orange vegetable", source: "ai", sort: 2),
        ];

        final ingredients = [
          Ingredient(
            id: "ing_1",
            type: "ingredient",
            name: "Diced Carrots",
            note: "Fresh",
            primaryAmount1Value: "3",
            primaryAmount1Unit: "whole",
            primaryAmount1Type: "count",
            terms: carrotTerms,
            isCanonicalised: true,
          ),
        ];

        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: recipeId,
          title: "Household Shared Recipe",
          language: "en",
          description: "Recipe shared with household",
          userId: householdOwnerId,
          householdId: householdId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          ingredients: ingredients,
        );

        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.any((r) => r.recipe.title == "Household Shared Recipe"),
        );

        // Create pantry item with terms and assign to household
        final potatoTerms = [
          PantryItemTerm(value: "potato", source: "user", sort: 1),
          PantryItemTerm(value: "russet potato", source: "user", sort: 2),
        ];

        // Add pantry item with householdId
        pantryItemId = await container.read(pantryItemsProvider.notifier).addItem(
          name: "Russet Potatoes",
          stockStatus: StockStatus.inStock,
          userId: householdOwnerId,
          householdId: householdId,
        );

        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
          (items) => items.any((item) => item.name == "Russet Potatoes"),
        );

        // Update pantry item to add terms (ensure name is first term)
        final allPotatoTerms = [
          PantryItemTerm(value: "Russet Potatoes", source: "user", sort: 0), // Name term first
          ...potatoTerms.map((term) => PantryItemTerm(
            value: term.value,
            source: term.source,
            sort: term.sort + 1, // Adjust sort order
          )),
        ];


        // Use provider method for proper PowerSync multi-user sync
        await container.read(pantryItemsProvider.notifier).updateItem(
          id: pantryItemId,
          terms: allPotatoTerms,
          isCanonicalised: true,
        );

        // Allow time for triggers to execute and sync
        await Future.delayed(const Duration(seconds: 3));


        // Verify materialized terms exist for owner
        final recipeMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM recipe_ingredient_terms 
          WHERE recipe_id = ?
          ''',
          variables: [Variable.withString(recipeId)],
        ).getSingle();

        final pantryMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM pantry_item_terms 
          WHERE pantry_item_id = ?
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).getSingle();


        expect(recipeMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
        expect(pantryMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
      });

      // Step 4: household_member logs in and should see the shared items with materialized terms
      await withTestUser('household_member', () async {
        // Wait for sync to complete
        await Future.delayed(const Duration(seconds: 5));

        // Verify the household_member can see the items
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.any((r) => r.recipe.title == "Household Shared Recipe"),
        );

        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
          (items) => items.any((item) => item.name == "Russet Potatoes"),
        );

        // Verify materialized terms exist for household member
        final recipeMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM recipe_ingredient_terms 
          WHERE recipe_id = ?
          ''',
          variables: [Variable.withString(recipeId)],
        ).getSingle();

        final pantryMaterializedTerms = await appDb.customSelect(
          '''
          SELECT COUNT(*) as count FROM pantry_item_terms 
          WHERE pantry_item_id = ?
          ''',
          variables: [Variable.withString(pantryItemId)],
        ).getSingle();


        expect(recipeMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
        expect(pantryMaterializedTerms.read<int>('count'), 3); // name + 2 canonical terms
      });
    });
  });
}
