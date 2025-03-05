import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/test_user_manager.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  final container = ProviderContainer();

  tearDownAll(() async {
    container.dispose();
    await TestUserManager.logoutTestUser();
  });

  group('Recipe Folder Tests', () {
    setUpAll(() async {
      await loadEnvVars();
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    setUp(() async {
      await TestUserManager.wipeAlLocalAndRemoteTestUserData();
    });

    tearDown(() async {
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

  });
}
