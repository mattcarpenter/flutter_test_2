import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/recipe_folder_assignment_provider.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';
import 'package:collection/collection.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Recipe Tests', () {
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


    testWidgets('User sees their recipes after signing in again', (tester) async {
      // Create test user "owner"
      await TestUserManager.createTestUser('owner');

      // First session: Log in as "owner", add a recipe, and verify it's present.
      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          title: "Test Recipe",
          language: "en",
          rating: 5,
          description: "A delicious test recipe",
          userId: ownerId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Test Recipe"),
        );
        await Future.delayed(const Duration(seconds: 1));
      });

      // After logout, the local DB should be cleared.
      await waitForProviderValue<List<RecipeWithFolders>>(
        container,
        recipeNotifierProvider,
            (recipes) => recipes.isEmpty,
      );

      // Second session: Log in again as "owner" and ensure the recipe is restored.
      await withTestUser('owner', () async {
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Test Recipe"),
        );
      });
    });

    testWidgets('Users cannot see recipes owned by other users', (tester) async {
      // Create test users "owner" and "other".
      await TestUserManager.createTestUsers(['owner', 'other']);

      // "Owner" creates a recipe.
      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          title: "Owner Recipe",
          language: "en",
          rating: 5,
          description: "A recipe by the owner",
          userId: ownerId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Owner Recipe"),
        );
        await Future.delayed(const Duration(seconds: 1));
      });

      // "Other" should not see "Owner Recipe".
      await withTestUser('other', () async {
        await Future.delayed(const Duration(seconds: 1));
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => !recipes.any((r) => r.recipe.title == "Owner Recipe"),
        );
      });

      // "Owner" logs back in and should see their recipe.
      await withTestUser('owner', () async {
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Owner Recipe"),
        );
      });
    });

    testWidgets('Recipe includes folder details when assigned', (tester) async {
      // Create test user "owner"
      await TestUserManager.createTestUser('owner');

      late String folderId;

      // First, create a folder so we have one to assign.
      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Dinner",
          userId: ownerId,
        );
        await waitForFolder(
          container: container,
          folderName: "Dinner",
          expectedCount: 1,
        );
        final folders = container.read(recipeFolderNotifierProvider).value!;
        folderId = folders.firstWhere((f) => f.name == "Dinner").id;

        // Little delay to ensure the folder is synced
        await Future.delayed(const Duration(seconds: 1));

        await container.read(recipeNotifierProvider.notifier).addRecipe(
          title: "Pasta",
          language: "en",
          rating: 4,
          description: "Simple pasta recipe",
          userId: ownerId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Pasta"),
        );

        // Little delay to ensure the recipe is synced
        await Future.delayed(const Duration(seconds: 1));

        // Retrieve the recipe id.
        final recipes = container.read(recipeNotifierProvider).value!;
        final recipe = recipes.firstWhere((r) => r.recipe.title == "Pasta").recipe;

        // Add the assignment.
        await container.read(recipeFolderAssignmentNotifierProvider.notifier).addAssignment(
          recipeId: recipe.id,
          userId: ownerId,
          folderId: folderId,
          householdId: null,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Little delay to ensure the assignment is synced
        await Future.delayed(const Duration(seconds: 1));

        // Verify the composite model now includes folder details.
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) {
            final matchingRecipe = recipes.firstWhereOrNull((r) => r.recipe.title == "Pasta");
            if (matchingRecipe == null) return false;
            return matchingRecipe.folderDetails.isNotEmpty &&
                matchingRecipe.folderDetails.any((detail) =>
                detail.folder.id == folderId && detail.folder.name == "Dinner");
          },
        );
      });
    });

  });
}
