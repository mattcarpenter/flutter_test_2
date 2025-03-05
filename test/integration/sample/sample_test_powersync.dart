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
      await TestUserManager.createTestUser('owner');
      await TestUserManager.loginAsTestUser('owner');

      // Add a folder
      await container.read(recipeFolderNotifierProvider.notifier).addFolder(
        name: "Test Folder",
        userId: Supabase.instance.client.auth.currentUser!.id,
      );

      // Ensure state is updated
      await waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => folders.any((folder) => folder.name == "Test Folder") && folders.length == 1,
      );

      // Logout and ensure state is cleared
      final folderCleared = waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => folders.isEmpty,
      );
      await TestUserManager.logoutTestUser();
      await folderCleared;

      // Login again and ensure folder is restored
      await TestUserManager.loginAsTestUser('owner');
      await waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => folders.any((folder) => folder.name == "Test Folder") && folders.length == 1,
      );
    });

    testWidgets('Users cannot see folders owned by other members', (tester) async {
      await TestUserManager.createTestUsers(['owner', 'other']);

      // Owner creates folder
      await TestUserManager.loginAsTestUser('owner');
      await container.read(recipeFolderNotifierProvider.notifier).addFolder(
        name: "Owner Folder",
        userId: Supabase.instance.client.auth.currentUser!.id,
      );

      // Wait for state to update
      await waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => folders.any((folder) => folder.name == "Owner Folder") && folders.length == 1,
      );

      await Future.delayed(Duration(seconds: 1));

      // Other user logs in; assert they cannot see owner's folder
      final folderNotVisible = waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => !folders.any((folder) => folder.name == "Owner Folder"),
      );
      await TestUserManager.logoutTestUser();
      await folderNotVisible;

      await TestUserManager.loginAsTestUser('other');

      // Other user creates a folder and logs out
      await container.read(recipeFolderNotifierProvider.notifier).addFolder(
        name: "Other Folder",
        userId: Supabase.instance.client.auth.currentUser!.id,
      );

      // Ensure state updated with new folder
      await waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => folders.any((folder) => folder.name == "Other Folder") && folders.length == 1,
      );

      await TestUserManager.logoutTestUser();

      // Owner logs back in and asserts they can see their folder
      final foldersLoaded = waitForProviderValue<List<RecipeFolderEntry>>(
        container,
        recipeFolderNotifierProvider,
            (folders) => folders.any((folder) => folder.name == "Owner Folder") && folders.length == 1,
      );
      await TestUserManager.loginAsTestUser('owner');
      await foldersLoaded;
    });
  });
}
