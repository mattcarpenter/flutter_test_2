import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/constants/folder_constants.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../utils/test_household_manager.dart';
import '../../utils/test_recipe_folder_share_manager.dart';
import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  late ProviderContainer container;

  tearDownAll(() async {
    await TestUserManager.logoutTestUser();
  });

  group('Recipe Folder Tests', () {
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

    testWidgets('User sees their folders after signing in again', (tester) async {
      // Create the test user only once.
      await TestUserManager.createTestUser('owner');

      // First session: log in as "owner", add a folder, and verify it's present.
      await withTestUser('owner', () async {
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Test Folder",
          userId: Supabase.instance.client.auth.currentUser!.id,
        );
        await waitForFolder(
          container: container,
          folderName: "Test Folder",
          expectedCount: 1,
        );
        await Future.delayed(const Duration(seconds: 1));
      });

      // After logout the local DB should be cleared.
      await waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => folders.isEmpty,
      );

      // Second session: log in again as "owner" and ensure the folder is restored.
      await withTestUser('owner', () async {
        await waitForFolder(
          container: container,
          folderName: "Test Folder",
          expectedCount: 1,
        );
      });
    });

    testWidgets('Users cannot see folders owned by other members', (tester) async {
      // Create test users once.
      await TestUserManager.createTestUsers(['owner', 'other']);

      // Owner creates a folder.
      await withTestUser('owner', () async {
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Owner Folder",
          userId: Supabase.instance.client.auth.currentUser!.id,
        );
        // Wait for the folder to be visible.
        await waitForFolder(container: container, folderName: "Owner Folder", expectedCount: 1);

        // Ensure enough time to sync to Supabase
        await Future.delayed(const Duration(seconds: 1));
      });

      // Other user logs in and should not see Owner's folder.
      await withTestUser('other', () async {
        // Wait until it's confirmed that "Owner Folder" is not visible.
        await waitForNoFolder(container: container, folderName: "Owner Folder");

        // Other user creates their own folder.
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Other Folder",
          userId: Supabase.instance.client.auth.currentUser!.id,
        );
        await waitForFolder(container: container, folderName: "Other Folder", expectedCount: 1);
      });

      // Owner logs back in and should see their own folder.
      await withTestUser('owner', () async {
        await waitForFolder(container: container, folderName: "Owner Folder", expectedCount: 1);
      });
    });

    testWidgets('Household Member Can View Folders Owned by Household Owner', (tester) async {
      // Create test users: "owner" and "other".
      await TestUserManager.createTestUsers(['owner', 'other']);

      // Log in as owner and get owner ID.
      await TestUserManager.loginAsTestUser('owner');
      final ownerUserId = Supabase.instance.client.auth.currentUser!.id;

      // Create a household for the owner.
      final householdData = await TestHouseholdManager.createHousehold('Owner Household', ownerUserId);
      final householdId = householdData['id'] as String;
      await TestHouseholdManager.addHouseholdMember(householdId, ownerUserId);

      // (Optional) Owner is implicitly part of the household when created.
      // Add a folder under that household.
      await container.read(recipeFolderNotifierProvider.notifier).addFolder(
        name: "Household Folder",
        userId: ownerUserId,
        householdId: householdId,
      );
      await waitForFolder(
        container: container,
        folderName: "Household Folder",
        expectedCount: 1,
      );
      await Future.delayed(const Duration(seconds: 1));
      await TestUserManager.logoutTestUser();

      // Log in as "other" to get their user id.
      await TestUserManager.loginAsTestUser('other');
      final otherUserId = Supabase.instance.client.auth.currentUser!.id;
      await TestUserManager.logoutTestUser();

      // Add "other" as a household member using the admin API.
      await TestHouseholdManager.addHouseholdMember(householdId, otherUserId);

      // Now, as the "other" user, verify they can see the folder.
      await withTestUser('other', () async {
        await waitForFolder(
          container: container,
          folderName: "Household Folder",
          expectedCount: 1,
        );
      });
    });

    testWidgets('Household Owner can view folders owned by household member', (tester) async {
      // Create test users: "owner" and "member".
      await TestUserManager.createTestUsers(['owner', 'member']);

      late String householdId;

      // Step 1: Owner logs in and creates a household.
      await withTestUser('owner', () async {
        final ownerUserId = Supabase.instance.client.auth.currentUser!.id;
        final householdData = await TestHouseholdManager.createHousehold('Owner Household', ownerUserId);
        householdId = householdData['id'] as String;
        await TestHouseholdManager.addHouseholdMember(householdId, ownerUserId);
      });

      // Step 2: Member logs in, gets added to the household, and creates a folder.
      await withTestUser('member', () async {
        final memberUserId = Supabase.instance.client.auth.currentUser!.id;
        // Add the member to the household.
        await TestHouseholdManager.addHouseholdMember(householdId, memberUserId);
        // Member creates a folder associated with the household.
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Member Folder",
          userId: memberUserId,
          householdId: householdId,
        );
        // Wait until the folder is visible.
        await waitForFolder(
          container: container,
          folderName: "Member Folder",
          expectedCount: 1,
        );
      });

      // Step 3: Owner logs in again and verifies that they can see the folder created by the member.
      await withTestUser('owner', () async {
        await waitForFolder(
          container: container,
          folderName: "Member Folder",
          expectedCount: 1,
        );
      });
    });

    testWidgets('User can see folders shared with them', (tester) async {
      // Create test users: "owner" and "member".
      await TestUserManager.createTestUsers(['owner', 'member']);

      late String memberUserId;
      late String folderId;

      // Retrieve the member's user id.
      await withTestUser('member', () async {
        memberUserId = Supabase.instance.client.auth.currentUser!.id;
      });

      // Owner logs in to create a folder and share it with the member.
      await withTestUser('owner', () async {
        final ownerUserId = Supabase.instance.client.auth.currentUser!.id;

        // Owner creates a folder.
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Owner's Folder",
          userId: ownerUserId,
        );
        // Wait until the folder appears in the provider state.
        await waitForFolder(
          container: container,
          folderName: "Owner's Folder",
          expectedCount: 1,
        );

        // Retrieve the folder id from the provider state.
        final folders = container.read(recipeFolderNotifierProvider).value!;
        final ownerFolder = folders.firstWhere((folder) => folder.name == "Owner's Folder");
        folderId = ownerFolder.id;

        // Small delay to allow any asynchronous processes to complete.
        await Future.delayed(const Duration(seconds: 1));

        // Share the folder with the member using the TestRecipeFolderShareManager.
        await TestRecipeFolderShareManager.createShare(
          folderId: folderId,
          sharerId: ownerUserId,
          targetUserId: memberUserId,
          canEdit: 1,
        );
      });

      // Now, log in as the member and ensure the shared folder is visible.
      await withTestUser('member', () async {
        await waitForFolder(
          container: container,
          folderName: "Owner's Folder",
          expectedCount: 1,
        );
      });
    });

    testWidgets('Household Owner and Household Member are in a household; other_member shares a folder with household_owner; household_member can see it', (tester) async {
      // Create test users.
      await TestUserManager.createTestUsers(['household_owner', 'household_member', 'other_member']);

      late String householdId;
      late String householdOwnerId;
      late String householdMemberId;
      late String folderId;

      // Step 1: household_owner logs in, creates a household, and we capture the household id.
      await withTestUser('household_owner', () async {
        householdOwnerId = Supabase.instance.client.auth.currentUser!.id;
        final householdData = await TestHouseholdManager.createHousehold('Test Household', householdOwnerId);
        householdId = householdData['id'] as String;
      });

      // Step 2: household_member logs in and is added to the household.
      await withTestUser('household_member', () async {
        householdMemberId = Supabase.instance.client.auth.currentUser!.id;
        await TestHouseholdManager.addHouseholdMember(householdId, householdMemberId);
        await TestHouseholdManager.addHouseholdMember(householdId, householdOwnerId);
      });

      // Step 3: other_member logs in, creates a folder, and shares it with household_owner.
      await withTestUser('other_member', () async {
        final otherMemberId = Supabase.instance.client.auth.currentUser!.id;
        // Create folder by other_member.
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Other Member's Folder",
          userId: otherMemberId,
        );
        await waitForFolder(
          container: container,
          folderName: "Other Member's Folder",
          expectedCount: 1,
        );
        // Wait for sync to complete.
        await Future.delayed(const Duration(seconds: 1));
        // Retrieve the folder id.
        final folders = container.read(recipeFolderNotifierProvider).value!;
        final otherMemberFolder = folders.firstWhere((folder) => folder.name == "Other Member's Folder");
        folderId = otherMemberFolder.id;

        // Share the folder with household_owner.
        await TestRecipeFolderShareManager.createShare(
          folderId: folderId,
          sharerId: otherMemberId,
          targetUserId: householdOwnerId,
          canEdit: 1,
        );
      });

      // Step 4: household_member logs in and verifies that they can see the folder shared with household_owner.
      await withTestUser('household_member', () async {
        await waitForFolder(
          container: container,
          folderName: "Other Member's Folder",
          expectedCount: 1,
        );
      });

      // Step 5: household_owner logs in and verifies that they can see the folder shared with them.
      await withTestUser('household_owner', () async {
        await waitForFolder(
          container: container,
          folderName: "Other Member's Folder",
          expectedCount: 1,
        );
      });
    });

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
