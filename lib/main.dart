import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:recipe_app/src/providers/recipe_filter_sort_provider.dart';
import 'package:recipe_app/utils/mecab_wrapper.dart';
import 'app_config.dart';
import 'database/database.dart';
import 'database/powersync.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:path_provider/path_provider.dart';
import 'src/features/settings/services/settings_storage_service.dart';
import 'src/features/settings/models/app_settings.dart';
import 'src/features/settings/providers/app_settings_provider.dart';

Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MecabWrapper().initialize();

  await AppConfig.initialize();

  await openDatabase();

  // Brick / Supabase
  //await BaseRepository.configure(databaseFactory);
  //await BaseRepository().initialize();

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  final directory = await getApplicationDocumentsDirectory();
  print('SQLite DB Path: ${directory.path}');

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Pre-load app settings before running the app
  // This ensures home screen preference is available when router is created
  final settingsStorageService = SettingsStorageService();
  final appSettings = await settingsStorageService.loadSettings();

  if (Platform.isMacOS) {
    await _configureMacosWindowUtils();
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize SharedPreferences overrides
  final overrides = await createSharedPreferencesOverrides();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(ProviderScope(
      overrides: [
        ...overrides,
        // Override the settings provider with pre-loaded settings
        appSettingsProvider.overrideWith((ref) {
          final notifier = AppSettingsNotifier(settingsStorageService);
          // Set the pre-loaded settings immediately
          notifier.setPreloadedSettings(appSettings);
          return notifier;
        }),
      ],
      child: MyApp(settingsController: settingsController))
  );
}

//final databaseProvider = FutureProvider<AppDatabase>((ref) async {
//  final connection = await openConnection();
//  return AppDatabase(connection);
///});
