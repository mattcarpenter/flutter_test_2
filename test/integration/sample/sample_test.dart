import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_app/src/repositories/base_repository.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:recipe_app/src/models/recipe_folder.model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "../../.env");

  late ProviderContainer container;
  late SupabaseClient client;

  final user1Email = dotenv.env['USER_1_EMAIL'] ?? '';
  final user1Password = dotenv.env['USER_1_PASSWORD'] ?? '';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await BaseRepository.configure(databaseFactory);
    await BaseRepository().initialize();

    container = ProviderContainer();
    client = Supabase.instance.client;
  });

  tearDownAll(() async {
    container.dispose();
    await client.auth.signOut();
  });

  group('Folder Fetching Test', () {
    testWidgets('Logs in and lists folders', (tester) async {
      await client.auth.signInWithPassword(
        email: user1Email,
        password: user1Password,
      );

      // Make sure the repository loads all folders from the local DB.
      await BaseRepository().getAll<RecipeFolder>();

      final completer = Completer<void>();

      // Listen to the notifier provider instead of the stream provider.
      final listener = container.listen(
        recipeFolderNotifierProvider,
            (previous, next) {
          if (next is AsyncData<List<RecipeFolder>> && next.value.isNotEmpty) {
            print('✅ Successfully received folders: ${next.value.map((f) => f.name)}');
            expect(next.value.isNotEmpty, isTrue);
            completer.complete();
          }
        },
      );

      await completer.future;
      listener.close();
    });
  });
}
