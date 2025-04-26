import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/recipe_ingredient_term_override_provider.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Recipe Ingredient Term Override Tests', () {
    setUp(() async {
      container = ProviderContainer();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    tearDown(() async {
      container.dispose();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    testWidgets('Add term override', (tester) async {
      await TestUserManager.createTestUser('owner');
      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        final newRecipeId = const Uuid().v4();
        final newPantryItemId = const Uuid().v4();

        // Create real recipe
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: newRecipeId,
          title: "Test Recipe for Override",
          language: "en",
          userId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.id == newRecipeId),
        );

        // Create real pantry item
        await container.read(pantryItemsProvider.notifier).addItem(
          name: "Test Pantry Item",
          userId: userId,
          householdId: null,
        );

        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
              (items) => items.any((item) => item.name == "Test Pantry Item"),
        );

        // Add override
        final notifier = container.read(
          recipeIngredientTermOverrideNotifierProvider(newRecipeId).notifier,
        );

        const term = "shallot";

        await notifier.addOverride(
          recipeId: newRecipeId,
          term: term,
          pantryItemId: newPantryItemId,
          userId: userId,
        );

        // Confirm it exists
        final overrides = await waitForProviderValue<List<RecipeIngredientTermOverrideEntry>>(
          container,
          recipeIngredientTermOverrideNotifierProvider(newRecipeId),
              (overrides) => overrides.any((o) => o.term == term),
        );

        expect(overrides.any((o) => o.term == term), isTrue);
      });
    });

    testWidgets('Delete term override', (tester) async {
      await TestUserManager.createTestUser('owner');
      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        final newRecipeId = const Uuid().v4();
        final newPantryItemId = const Uuid().v4();

        // Create real recipe
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: newRecipeId,
          title: "Test Recipe for Deletion",
          language: "en",
          userId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.id == newRecipeId),
        );

        // Create real pantry item
        await container.read(pantryItemsProvider.notifier).addItem(
          name: "Test Pantry Item 2",
          userId: userId,
          householdId: null,
        );

        await waitForProviderValue<List<PantryItemEntry>>(
          container,
          pantryItemsProvider,
              (items) => items.any((item) => item.name == "Test Pantry Item 2"),
        );

        // Add override
        final notifier = container.read(
          recipeIngredientTermOverrideNotifierProvider(newRecipeId).notifier,
        );

        const term = "onion";

        await notifier.addOverride(
          recipeId: newRecipeId,
          term: term,
          pantryItemId: newPantryItemId,
          userId: userId,
        );

        final overrides = await waitForProviderValue<List<RecipeIngredientTermOverrideEntry>>(
          container,
          recipeIngredientTermOverrideNotifierProvider(newRecipeId),
              (overrides) => overrides.any((o) => o.term == term),
        );

        final overrideId = overrides.firstWhere((o) => o.term == term).id;

        // Delete
        await notifier.deleteOverrideById(overrideId);

        // Confirm deletion
        final afterDeleteOverrides = await waitForProviderValue<List<RecipeIngredientTermOverrideEntry>>(
          container,
          recipeIngredientTermOverrideNotifierProvider(newRecipeId),
              (overrides) => overrides.every((o) => o.term != term),
        );

        expect(afterDeleteOverrides.any((o) => o.term == term), isFalse);
      });
    });
  });
}
