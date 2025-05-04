import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
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

        // Print the first recipe's details for manual verification
        if (recipes.isNotEmpty) {
          final firstRecipe = recipes.first.recipe;
          print('First recipe: ${firstRecipe.title}');
          print('Ingredients count: ${firstRecipe.ingredients?.length ?? 0}');
          print('Steps count: ${firstRecipe.steps?.length ?? 0}');
        }

        // Wait for 10 minutes so you can manually inspect the database
        await Future.delayed(const Duration(minutes: 10));
      });
    });
  });
}
