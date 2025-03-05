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

    tearDownAll(() async {
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
  });
}
