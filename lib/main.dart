import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'app_config.dart';
import 'database/database.dart';
import 'database/powersync.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:path_provider/path_provider.dart';

Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.initialize();

  // Drift
  //final connection = await openConnection();
  //final db = AppDatabase(connection);
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

  if (Platform.isMacOS) {
    await _configureMacosWindowUtils();
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(ProviderScope(
      //overrides: [
      //  databaseProvider.overrideWith((ref) => db),
      //],
      child: MyApp(settingsController: settingsController))
  );
}

//final databaseProvider = FutureProvider<AppDatabase>((ref) async {
//  final connection = await openConnection();
//  return AppDatabase(connection);
///});
