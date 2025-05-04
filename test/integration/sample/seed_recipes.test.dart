import 'dart:math' as Math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/managers/ingredient_term_queue_manager.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/repositories/ingredient_term_queue_repository.dart';
import 'package:recipe_app/src/repositories/recipe_repository.dart';
import 'package:recipe_app/src/services/ingredient_canonicalization_service.dart';
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
        
        // Connect them bidirectionally
        ingredientTermManager.recipeRepository = recipeRepository;
        recipeRepository.ingredientTermQueueManager = ingredientTermManager;
        
        // Import seed recipes with a limit of 10
        final importCount = await container.read(recipeNotifierProvider.notifier).importSeedRecipes(limit: 10);

        // Log the number of imported recipes
        print('Successfully imported $importCount seed recipes');

        // Wait for the recipes to appear in the provider
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
          (recipes) => recipes.length >= importCount,
        );

        // Verify recipes were imported
        final recipes = container.read(recipeNotifierProvider).value!;
        expect(recipes.length, greaterThanOrEqualTo(importCount));

        // Print recipe details for manual verification
        if (recipes.isNotEmpty) {
          for (int i = 0; i < Math.min(3, recipes.length); i++) {
            final recipe = recipes[i].recipe;
            print('===== Recipe ${i+1}: ${recipe.title} =====');
            print('Description: ${recipe.description}');
            print('Ingredients count: ${recipe.ingredients?.length ?? 0}');
            
            // Print first 3 ingredients 
            if (recipe.ingredients != null && recipe.ingredients!.isNotEmpty) {
              print('Sample ingredients:');
              for (int j = 0; j < Math.min(3, recipe.ingredients!.length); j++) {
                final ingredient = recipe.ingredients![j];
                print('  - ${ingredient.primaryAmount1Value ?? ""} ${ingredient.primaryAmount1Unit ?? ""} ${ingredient.name}');
              }
            }
            
            print('Steps count: ${recipe.steps?.length ?? 0}');
            
            // Print first step
            if (recipe.steps != null && recipe.steps!.isNotEmpty) {
              print('First step: ${recipe.steps!.first.text.substring(0, Math.min(100, recipe.steps!.first.text.length))}...');
            }
            print('================================================');
          }
        }

        // Wait for 10 minutes so you can manually inspect the database
        await Future.delayed(const Duration(minutes: 10));
      });
    });
  });
}
