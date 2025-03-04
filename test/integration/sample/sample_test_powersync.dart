import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_app/app_config.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/powersync.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:recipe_app/src/repositories/recipe_folder_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path/path.dart' as p;

import '../../utils/supabase_admin.dart';
import '../../utils/test_utils.dart';

void main() async {
  await initializeTestEnvironment();
  final container = ProviderContainer();

  tearDownAll(() async {
    container.dispose();
    await logout();
  });

  group('Hello World Integration Test', () {
    setUpAll(() async {
      await loadEnvVars();
      await truncateAllTables();
      await deleteAllUsers();
    });

    testWidgets('Signs in, inserts folder, syncs, and receives data via Riverpod', (tester) async {
      // Sign in using test credentials from your .env.test file.
      final testEmail = dotenv.env['TEST_USER_EMAIL'];
      final testPassword = dotenv.env['TEST_USER_PASSWORD'] ?? '';
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(email: testEmail, password: testPassword);
      expect(authResponse.session, isNotNull,
          reason: 'User should be signed in');

      // Insert a new folder via your repository.
      final folderRepo = RecipeFolderRepository(appDb);
      final folderName = "Test Folder ${DateTime.now().millisecondsSinceEpoch}";
      await folderRepo.addFolder(RecipeFoldersCompanion.insert(
        name: folderName,
        userId: Value(Supabase.instance.client.auth.currentUser!.id),
        parentId: Value(null),
        householdId: Value(null),
      ));

      // Optionally trigger a sync. If you have a sync method on your PowerSyncDatabase,
      // call it here. Otherwise, ensure that your app's connector (via openDatabase)
      // automatically picks up pending changes.
      //await db.sync(); // Adjust this if your sync trigger is named differently.

      // Listen for the folder via your Riverpod notifier.
      final completer = Completer<void>();
      final listener = container.listen(
        recipeFolderNotifierProvider,
            (previous, next) {
          next.whenOrNull(
            data: (folders) {
              if (folders.any((folder) => folder.name == folderName)) {
                if (!completer.isCompleted) {
                  completer.complete();
                }
              }
            },
          );
        },
      );

      // Wait for up to 10 seconds for the folder to be synced and received.
      await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () => fail("Folder '$folderName' not found in synced data."),
      );

      //await Future.delayed(Duration(minutes: 30));

      //listener.close();
    });
  });
}
