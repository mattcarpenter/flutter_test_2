import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
}
