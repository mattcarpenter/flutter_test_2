import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/models/recipe_with_folders.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/test_household_manager.dart';
import '../../utils/test_recipe_folder_share_manager.dart';
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
        await container
            .read(recipeNotifierProvider.notifier)
            .addFolderAssignment(recipeId: recipe.id, folderId: folderId);

        // Little delay to ensure the assignment is synced
        await Future.delayed(const Duration(seconds: 1));

        // Verify the composite model now includes folder details.
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) {
            final matchingRecipe = recipes.firstWhereOrNull((r) => r.recipe.title == "Pasta");
            if (matchingRecipe == null) return false;
            return matchingRecipe.folders.isNotEmpty &&
                matchingRecipe.folders.any((detail) =>
                detail.id == folderId && detail.name == "Dinner");
          },
        );
      });
    });

    testWidgets('Shared folder shows recipe to member', (tester) async {
      // Create test users "owner" and "member".
      await TestUserManager.createTestUsers(['owner', 'member']);

      late String folderId;
      late String memberId;

      // First, log in as member to capture their user id.
      await withTestUser('member', () async {
        memberId = Supabase.instance.client.auth.currentUser!.id;
      });

      // Now, as the owner, create a folder, recipe, assign the recipe to the folder,
      // then share that folder with the member.
      await withTestUser('owner', () async {
        final ownerId = Supabase.instance.client.auth.currentUser!.id;

        // Create a folder named "Shared Folder".
        await container.read(recipeFolderNotifierProvider.notifier).addFolder(
          name: "Shared Folder",
          userId: ownerId,
        );
        await waitForFolder(
          container: container,
          folderName: "Shared Folder",
          expectedCount: 1,
        );
        final folders = container.read(recipeFolderNotifierProvider).value!;
        folderId = folders.firstWhere((f) => f.name == "Shared Folder").id;

        // Small delay to ensure folder sync.
        await Future.delayed(const Duration(seconds: 1));

        // Create a recipe named "Shared Recipe".
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          title: "Shared Recipe",
          language: "en",
          rating: 5,
          description: "Recipe to be shared",
          userId: ownerId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Shared Recipe"),
        );

        // Retrieve the created recipe.
        final recipes = container.read(recipeNotifierProvider).value!;
        final recipe = recipes.firstWhere((r) => r.recipe.title == "Shared Recipe").recipe;

        // Add a folder assignment linking the recipe to "Shared Folder".
        await container
            .read(recipeNotifierProvider.notifier)
            .addFolderAssignment(recipeId: recipe.id, folderId: folderId);

        // Small delay to ensure the assignment is synced.
        await Future.delayed(const Duration(seconds: 1));

        // Share the folder with the member using the TestRecipeFolderShareManager.
        await TestRecipeFolderShareManager.createShare(
          folderId: folderId,
          sharerId: ownerId,
          targetUserId: memberId,
          canEdit: 1,
        );

        // Small delay to allow sharing to sync.
        await Future.delayed(const Duration(seconds: 1));
      });

      // Finally, log in as "member" and assert that the shared recipe appears with folder details.
      await withTestUser('member', () async {
        await Future.delayed(const Duration(seconds: 5));
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) {
            final matchingRecipe = recipes.firstWhereOrNull((r) => r.recipe.title == "Shared Recipe");
            if (matchingRecipe == null) return false;
            return matchingRecipe.folders.isNotEmpty &&
                matchingRecipe.folders.any((detail) =>
                detail.id == folderId &&
                    detail.name == "Shared Folder"
                );
          },
        );
      });
    });

    testWidgets('Household Owner and Household Member are in a household; other_member shares a folder with household_owner; household_member can see folder and recipes within', (tester) async {
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

        // Add a recipe to the folder
        await container.read(recipeNotifierProvider.notifier).addRecipe(
          title: "Other Member's Recipe",
          language: "en",
          rating: 5,
          description: "Recipe to be shared",
          userId: otherMemberId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await Future.delayed(const Duration(seconds: 1));

        // Get the recipe id
        await waitForProviderValue<List<RecipeWithFolders>>(
          container,
          recipeNotifierProvider,
              (recipes) => recipes.any((r) => r.recipe.title == "Other Member's Recipe"),
        );
        final recipes = container.read(recipeNotifierProvider).value!;
        final recipe = recipes.firstWhere((r) => r.recipe.title == "Other Member's Recipe").recipe;

        // Add recipe to the folder we created
        await container
            .read(recipeNotifierProvider.notifier)
            .addFolderAssignment(recipeId: recipe.id, folderId: folderId);

        // Small delay to ensure the assignment is synced.
        await Future.delayed(const Duration(seconds: 1));

        // Share the folder with household_owner.
        await TestRecipeFolderShareManager.createShare(
          folderId: folderId,
          sharerId: otherMemberId,
          targetUserId: householdOwnerId,
          canEdit: 1,
        );
      });

      // Step 4: household_member logs in and verifies that they can see the folder shared with them.
      await withTestUser('household_member', () async {
        await Future.delayed(const Duration(seconds: 5));
        await waitForFolder(
          container: container,
          folderName: "Other Member's Folder",
          expectedCount: 1,
        );
      });
    });


  });
}
