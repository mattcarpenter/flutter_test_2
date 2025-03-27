import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/constants/folder_constants.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';
import '../../utils/test_recipe_folder_share_manager.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Recipe Folder Deletion Tests', () {
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

    testWidgets('User can delete a folder and the folder disappears', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Create a folder
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Test Folder",
          userId: userId,
        );

        // Wait for the folder to appear
        await waitForFolder(
          container: container,
          folderName: "Test Folder",
          expectedCount: 1,
        );

        // Get the folder ID
        final folders = container.read(recipeFolderNotifierProvider).value!;
        final folderId = folders.firstWhere((folder) => folder.name == "Test Folder").id;

        // Delete the folder
        await container.read(recipeFolderNotifierProvider.notifier).deleteFolder(folderId);

        // Verify the folder is gone
        await waitForNoFolder(container: container, folderName: "Test Folder");
      });
    });

    testWidgets('When a folder with recipes is deleted, recipes become uncategorized', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Create a folder
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Recipe Folder",
          userId: userId,
        );

        // Wait for the folder to appear
        await waitForFolder(
          container: container,
          folderName: "Recipe Folder",
          expectedCount: 1,
        );

        // Get the folder ID
        final folders = container.read(recipeFolderNotifierProvider).value!;
        final folderId = folders.firstWhere((folder) => folder.name == "Recipe Folder").id;

        // Create a recipe
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: const Uuid().v4(),
          title: "Test Recipe",
          language: "en",
          userId: userId,
        );

        // Wait for the recipe to appear
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Test Recipe"),
        );

        // Get the recipe
        final recipes = container.read(recipeNotifierProvider).value!;
        final recipe = recipes.firstWhere((r) => r.recipe.title == "Test Recipe").recipe;

        // Assign the recipe to the folder
        await container.read(recipeNotifierProvider.notifier).addFolderAssignment(
          recipeId: recipe.id,
          folderId: folderId,
        );

        // Wait for the folder assignment to show in the recipe
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) {
            final r = recipes.firstWhere((r) => r.recipe.title == "Test Recipe");
            return r.recipe.folderIds != null &&
                r.recipe.folderIds!.contains(folderId);
          },
        );

        // Verify recipe is in the folder
        final updatedRecipes = container.read(recipeNotifierProvider).value!;
        final updatedRecipe = updatedRecipes.firstWhere((r) => r.recipe.title == "Test Recipe").recipe;
        expect(updatedRecipe.folderIds, contains(folderId));

        // Delete the folder
        await container.read(recipeFolderNotifierProvider.notifier).deleteFolder(folderId);

        // Verify folder is gone
        await waitForNoFolder(container: container, folderName: "Recipe Folder");

        // Verify recipe no longer has the folder ID
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) {
            final r = recipes.firstWhere((r) => r.recipe.title == "Test Recipe");
            return r.recipe.folderIds == null ||
                !r.recipe.folderIds!.contains(folderId);
          },
        );

        // Final verification that recipe is now "uncategorized"
        final finalRecipes = container.read(recipeNotifierProvider).value!;
        final finalRecipe = finalRecipes.firstWhere((r) => r.recipe.title == "Test Recipe").recipe;
        expect(finalRecipe.folderIds, isNot(contains(folderId)));
      });
    });

    testWidgets('Deleting a folder removes it from multiple recipes', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Create a folder
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Multiple Recipe Folder",
          userId: userId,
        );

        // Wait for the folder to appear
        await waitForFolder(
          container: container,
          folderName: "Multiple Recipe Folder",
          expectedCount: 1,
        );

        // Get the folder ID
        final folders = container.read(recipeFolderNotifierProvider).value!;
        final folderId = folders.firstWhere((folder) => folder.name == "Multiple Recipe Folder").id;

        // Create multiple recipes
        final recipeIds = <String>[];
        for (int i = 1; i <= 3; i++) {
          final recipeId = const Uuid().v4();
          recipeIds.add(recipeId);

          await container.read(recipeNotifierProvider.notifier).addRecipe(
            id: recipeId,
            title: "Recipe $i",
            language: "en",
            userId: userId,
          );

          // Wait for the recipe to appear
          await waitForProviderValue<List<RecipeWithFolders>>(
            container,
            recipeNotifierProvider,
                (recipes) => recipes.any((r) => r.recipe.title == "Recipe $i"),
          );

          // Assign the recipe to the folder
          await container.read(recipeNotifierProvider.notifier).addFolderAssignment(
            recipeId: recipeId,
            folderId: folderId,
          );

          // Wait for the folder assignment
          await waitForProviderValue<List<RecipeWithFolders>>(
            container,
            recipeNotifierProvider,
                (recipes) {
              final r = recipes.firstWhere((r) => r.recipe.id == recipeId);
              return r.recipe.folderIds != null &&
                  r.recipe.folderIds!.contains(folderId);
            },
          );
        }

        // Verify all recipes have the folder ID
        for (final recipeId in recipeIds) {
          final recipe = container.read(recipeNotifierProvider).value!
              .firstWhere((r) => r.recipe.id == recipeId).recipe;
          expect(recipe.folderIds, contains(folderId));
        }

        // Delete the folder
        await container.read(recipeFolderNotifierProvider.notifier).deleteFolder(folderId);

        // Verify folder is gone
        await waitForNoFolder(container: container, folderName: "Multiple Recipe Folder");

        // Verify none of the recipes have the folder ID anymore
        for (final recipeId in recipeIds) {
          await waitForProviderValue<List<RecipeWithFolders>>(
            container,
            recipeNotifierProvider,
                (recipes) {
              final r = recipes.firstWhere((r) => r.recipe.id == recipeId);
              return r.recipe.folderIds == null ||
                  !r.recipe.folderIds!.contains(folderId);
            },
          );
        }
      });
    });

    testWidgets('After folder deletion, recipes show up in "Uncategorized" folder', (tester) async {
      // Create test user
      await TestUserManager.createTestUser('owner');

      await withTestUser('owner', () async {
        final userId = Supabase.instance.client.auth.currentUser!.id;

        // Create a folder
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Category Folder",
          userId: userId,
        );

        // Wait for the folder to appear
        await waitForFolder(
          container: container,
          folderName: "Category Folder",
          expectedCount: 1,
        );

        // Get the folder ID
        final folders = container.read(recipeFolderNotifierProvider).value!;
        final folderId = folders.firstWhere((folder) => folder.name == "Category Folder").id;

        // Create a recipe
        final recipeId = const Uuid().v4();
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: recipeId,
          title: "Categorized Recipe",
          language: "en",
          userId: userId,
        );

        // Wait for the recipe to appear
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Categorized Recipe"),
        );

        // Assign the recipe to the folder
        await container.read(recipeNotifierProvider.notifier).addFolderAssignment(
          recipeId: recipeId,
          folderId: folderId,
        );

        // Wait for the folder assignment
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) {
            final r = recipes.firstWhere((r) => r.recipe.id == recipeId);
            return r.recipe.folderIds != null &&
                r.recipe.folderIds!.contains(folderId);
          },
        );

        // Check recipe counts
        final folderCounts = container.read(recipeFolderCountProvider);
        final uncategorizedCount = folderCounts[kUncategorizedFolderId] ?? 0;
        expect(folderCounts[folderId], 1); // Our folder should have 1 recipe

        // Delete the folder
        await container.read(recipeFolderNotifierProvider.notifier).deleteFolder(folderId);

        // Verify folder is gone
        await waitForNoFolder(container: container, folderName: "Category Folder");

        // Wait for recipe count updates
        await Future.delayed(const Duration(seconds: 1));

        // Check recipe counts again - uncategorized should increase by 1
        final updatedFolderCounts = container.read(recipeFolderCountProvider);
        final updatedUncategorizedCount = updatedFolderCounts[kUncategorizedFolderId] ?? 0;
        expect(updatedUncategorizedCount, uncategorizedCount + 1); // Uncategorized count should increase
        expect(updatedFolderCounts[folderId], isNull); // Deleted folder should have no count
      });
    });

    testWidgets('Deleting a shared folder properly removes references for all users', (tester) async {
      // Create test users
      await TestUserManager.createTestUsers(['owner', 'member']);

      late String folderId;
      late String memberId;
      late String recipeId;

      // First, get the member ID
      await withTestUser('member', () async {
        memberId = Supabase.instance.client.auth.currentUser!.id;
      });

      // As owner, create a folder and share it
      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;

        // Create a folder
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Shared Folder",
          userId: ownerId,
        );

        // Wait for the folder to appear
        await waitForFolder(
          container: container,
          folderName: "Shared Folder",
          expectedCount: 1,
        );

        // Get the folder ID
        final folders = container.read(recipeFolderNotifierProvider).value!;
        folderId = folders.firstWhere((folder) => folder.name == "Shared Folder").id;

        // Create a recipe
        recipeId = const Uuid().v4();
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          id: recipeId,
          title: "Shared Recipe",
          language: "en",
          userId: ownerId,
        );

        // Wait for the recipe to appear
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Shared Recipe"),
        );

        // Assign the recipe to the folder
        await container.read(recipeNotifierProvider.notifier).addFolderAssignment(
          recipeId: recipeId,
          folderId: folderId,
        );

        // Wait for the folder assignment
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) =>
          r.recipe.id == recipeId &&
              r.recipe.folderIds != null &&
              r.recipe.folderIds!.contains(folderId)),
        );

        // Wait for sync to Supabase before sharing
        await Future.delayed(const Duration(seconds: 3));

        // Share the folder with member
        await TestRecipeFolderShareManager.createShare(
          folderId: folderId,
          sharerId: ownerId,
          targetUserId: memberId,
          canEdit: 1,
        );

        // Wait for sync
        await Future.delayed(const Duration(seconds: 1));
      });

      // Member should see the shared folder and recipe
      await withTestUser('member', () async {
        // Wait for the shared folder to appear
        await waitForFolder(
          container: container,
          folderName: "Shared Folder",
          expectedCount: 1,
        );

        // Verify the recipe is in the folder
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Shared Recipe"),
        );
      });

      // Owner deletes the folder - add delay to allow sync from Supabase
      await withTestUser('owner', () async {
        // Critical: Wait for folder to sync from Supabase to local DB
        await Future.delayed(const Duration(seconds: 3));

        // Delete the folder
        await container.read(recipeFolderNotifierProvider.notifier).deleteFolder(folderId);

        // Verify folder is gone
        await waitForNoFolder(container: container, folderName: "Shared Folder");

        // Verify recipe still exists but without folder reference
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) =>
          r.recipe.id == recipeId &&
              (r.recipe.folderIds == null || !r.recipe.folderIds!.contains(folderId))),
        );
      });

      // Member should no longer see the folder or recipe
      await withTestUser('member', () async {
        // Wait for sync from Supabase
        await Future.delayed(const Duration(seconds: 3));

        // Verify folder is gone for member too
        await waitForNoFolder(container: container, folderName: "Shared Folder");

        // Verify member can no longer see the recipe
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => !recipes.any((r) => r.recipe.title == "Shared Recipe"),
        );
      });
    });
  });
}
