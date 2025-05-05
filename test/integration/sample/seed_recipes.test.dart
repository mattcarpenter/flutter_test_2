import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/models/pantry_item_terms.dart';
import 'package:recipe_app/src/managers/ingredient_term_queue_manager.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/repositories/ingredient_term_queue_repository.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:recipe_app/src/services/ingredient_canonicalization_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Seed Recipe Tests', () {
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

    testWidgets('Import seed recipes', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('seed_tester');

      await withTestUser('seed_tester', () async {
        // Set up the circular dependency between RecipeRepository and IngredientTermQueueManager
        final recipeRepository = container.read(recipeRepositoryProvider);
        final ingredientTermManager = container.read(ingredientTermQueueManagerProvider);

        // Enable test mode to skip connectivity checks
        ingredientTermManager.testMode = true;

        // Connect them bidirectionally
        ingredientTermManager.recipeRepository = recipeRepository;
        recipeRepository.ingredientTermQueueManager = ingredientTermManager;

        // Import seed recipes with a limit of 10
        final importCount = await container.read(recipeNotifierProvider.notifier).importSeedRecipes();

        // Log the number of imported recipes
        print('Successfully imported $importCount seed recipes');

        // Wait for the recipes to appear in the provider
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.length >= importCount,
          timeout: const Duration(seconds: 60),
        );

        // Verify recipes were imported
        final recipes = container.read(recipeNotifierProvider).value!;
        expect(recipes.length, greaterThanOrEqualTo(importCount));

        // Insert a couple test pantry items
        await container.read(pantryNotifierProvider.notifier).addItem(
          name: 'Onions',
          userId: Supabase.instance.client.auth.currentUser!.id,
          terms: [
            makeTerm('onions'),
          ],
        );

        await container.read(pantryNotifierProvider.notifier).addItem(
          name: 'Bacon',
          userId: Supabase.instance.client.auth.currentUser!.id,
          terms: [
            makeTerm('bacon'),
          ],
        );

        print('Done creating pantry items');

        // Wait for 10 minutes so you can manually inspect the database
        await Future.delayed(const Duration(minutes: 10));
        exit(0);
      });
    });
  });
}

PantryItemTerm makeTerm(value, { sort = 0 }) {
  return PantryItemTerm(
    value: value,
    source: 'ai',
    sort: sort,
  );
}
